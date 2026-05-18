import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/community_models.dart';
import '../services/community_repository.dart';

class GroupsNotifier extends ChangeNotifier {
  GroupsNotifier(this._repo);

  final CommunityRepository _repo;
  List<CommunityGroup> groups = [];
  String? error;
  StreamSubscription<List<CommunityGroup>>? _sub;

  Future<void> connect() async {
    if (!_repo.isConfigured) return;
    await _sub?.cancel();
    _sub = _repo.watchGroups().listen(
      (g) {
        groups = g;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<String> createGroup({
    required String name,
    required String description,
    required CommunityGroupType type,
  }) =>
      _repo.createGroup(name: name, description: description, type: type);

  Future<void> join(String groupId) => _repo.joinGroup(groupId);

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }
}

class GroupChatNotifier extends ChangeNotifier {
  GroupChatNotifier(this._repo, this.groupId, this.displayName);

  final CommunityRepository _repo;
  final String groupId;
  final String displayName;

  List<GroupChatMessage> messages = [];
  List<CommunityProfile> members = [];
  int onlinePresenceCount = 0;
  final Map<String, bool> typingUserIds = {};
  RealtimeChannel? _typingCh;
  RealtimeChannel? _presenceCh;
  String? error;
  bool _connecting = false;
  StreamSubscription<List<GroupChatMessage>>? _msgSub;

  Future<void> connect() async {
    if (!_repo.isConfigured || _connecting) return;
    _connecting = true;
    error = null;
    try {
      await _repo.ensureSession(displayName: displayName);
      members = await _repo.fetchMembers(groupId);
      notifyListeners();

      await _msgSub?.cancel();
      _msgSub = _repo.watchMessages(groupId).listen((m) {
        messages = m;
        notifyListeners();
      }, onError: (e) {
        error = e.toString();
        notifyListeners();
      });

      final tch = _repo.typingChannel(groupId);
      _repo.subscribeTyping(tch, (payload) {
        final uid = payload['user_id'] as String?;
        final typing = payload['typing'] == true;
        if (uid == null) return;
      if (typing) {
        typingUserIds[uid] = true;
      } else {
        typingUserIds.remove(uid);
      }
      notifyListeners();
      if (typing) {
        Future.delayed(const Duration(seconds: 3), () {
          typingUserIds.remove(uid);
          notifyListeners();
        });
      }
    });
    _typingCh = tch;

      _presenceCh = await _repo.joinPresenceChannel(
        groupId,
        {
          'user_id': _repo.currentUserId,
          'name': displayName,
        },
        onPresenceChanged: (n) {
          onlinePresenceCount = n;
          notifyListeners();
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    } finally {
      _connecting = false;
    }
  }

  Future<void> onTypingChanged(bool typing) async {
    final ch = _typingCh;
    if (ch != null) await _repo.sendTypingPulse(ch, typing);
  }

  Future<void> send(String text) async {
    await _repo.sendMessage(groupId, text);
    // Message will be received via the existing stream subscription (_msgSub)
    // Trigger a manual refresh in case realtime doesn't catch it immediately
    try {
      final updatedMessages = await _repo.fetchGroupMessages(groupId);
      messages = updatedMessages.map((m) {
        final senderRow = m['profiles'] as Map<String, dynamic>?;
        return GroupChatMessage.fromMap(m, senderRow, {});
      }).toList();
      notifyListeners();
    } catch (_) {
      // Stream subscription will handle updates
    }
  }

  Future<void> sendImage(XFile file) async {
    await _repo.sendMessageWithImage(groupId, file);
    // Message will be received via the existing stream subscription (_msgSub)
    try {
      final updatedMessages = await _repo.fetchGroupMessages(groupId);
      messages = updatedMessages.map((m) {
        final senderRow = m['profiles'] as Map<String, dynamic>?;
        return GroupChatMessage.fromMap(m, senderRow, {});
      }).toList();
      notifyListeners();
    } catch (_) {
      // Stream subscription will handle updates
    }
  }

  Future<void> react(String messageId, String emoji) =>
      _repo.toggleReaction(messageId, emoji);

  @override
  void dispose() {
    unawaited(_msgSub?.cancel());
    unawaited(_typingCh?.unsubscribe());
    unawaited(_presenceCh?.unsubscribe());
    super.dispose();
  }
}

/// Derives local countdown from shared [FocusRoomState] (server-synced).
class FocusRoomNotifier extends ChangeNotifier {
  FocusRoomNotifier(this._repo, this.groupId, this.displayName);

  final CommunityRepository _repo;
  final String groupId;
  final String displayName;

  FocusRoomState? state;
  Timer? _tick;
  Duration remaining = Duration.zero;
  StreamSubscription<FocusRoomState?>? _sub;

  Future<void> connect() async {
    if (!_repo.isConfigured) return;
    try {
      await _repo.ensureSession(displayName: displayName);
      await _sub?.cancel();
      _sub = _repo.watchFocusState(groupId).listen((s) {
        state = s;
        _recompute();
        notifyListeners();
      }, onError: (e) {
        debugPrint('FocusRoom stream error: $e');
      });
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        _recompute();
        notifyListeners();
      });
    } catch (e) {
      debugPrint('FocusRoom connect error: $e');
    }
  }

  void _recompute() {
    final s = state;
    if (s == null || s.phase == FocusPhase.idle || s.phaseStartedAt == null) {
      remaining = Duration.zero;
      return;
    }
    final start = s.phaseStartedAt!.toUtc();
    final now = DateTime.now().toUtc();
    final elapsed = now.difference(start).inSeconds;
    final total = s.phase == FocusPhase.focus ? s.focusSeconds : s.breakSeconds;
    final left = total - elapsed;
    remaining = Duration(seconds: left.clamp(0, total));
  }

  Future<void> setPhase(FocusPhase phase) async {
    await _repo.updateFocusRoom(
      groupId: groupId,
      phase: phase,
      phaseStartedAt: DateTime.now().toUtc(),
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    unawaited(_sub?.cancel());
    super.dispose();
  }
}
