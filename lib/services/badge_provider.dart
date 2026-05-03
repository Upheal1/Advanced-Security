import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/badge_model.dart';
import '../services/reward_orchestrator.dart' as rewards;

class BadgeProvider extends ChangeNotifier {
  BadgeProvider({required rewards.RewardOrchestrator orchestrator})
      : _orchestrator = orchestrator;

  static const String _storageKey = 'badges_v1';

  final rewards.RewardOrchestrator _orchestrator;

  List<BadgeModel> _badges = List<BadgeModel>.from(DefaultBadges.all);

  int _lastStreakDays = 0;
  int _lastTasksCompleted = 0;
  int _lastAddictionFreeDays = 0;

  List<BadgeModel> get badges => List.unmodifiable(_badges);

  List<BadgeModel> get earned =>
      _badges.where((b) => b.status == BadgeStatus.unlocked).toList();

  List<BadgeModel> get locked =>
      _badges.where((b) => b.status == BadgeStatus.locked).toList();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final mapById = <String, Map<String, dynamic>>{};
      for (final e in decoded) {
        if (e is Map) {
          final id = e['id'] as String?;
          if (id != null) {
            mapById[id] = e.cast<String, dynamic>();
          }
        }
      }
      _badges = DefaultBadges.all
          .map((b) =>
              mapById[b.id] != null ? b.mergeFromJson(mapById[b.id]!) : b)
          .toList(growable: false);
    } catch (_) {
      // ignore and keep defaults
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _badges.map((b) => b.toJson()).toList(growable: false);
    await prefs.setString(_storageKey, jsonEncode(list));
  }

  /// Update badge state based on user progress.
  ///
  /// - **streakDays**: streak length (also used as addiction-free days if you
  ///   don't track those separately yet)
  /// - **tasksCompleted**: total completed tasks (missions + challenges)
  /// - **addictionFreeDays**: addiction-free days (can be same as streakDays)
  Future<void> updateFrom({
    required int streakDays,
    required int tasksCompleted,
    required int addictionFreeDays,
  }) async {
    // Avoid work if nothing changed.
    if (_lastStreakDays == streakDays &&
        _lastTasksCompleted == tasksCompleted &&
        _lastAddictionFreeDays == addictionFreeDays) {
      return;
    }
    _lastStreakDays = streakDays;
    _lastTasksCompleted = tasksCompleted;
    _lastAddictionFreeDays = addictionFreeDays;

    final now = DateTime.now();
    var changed = false;

    BadgeModel? unlockIf(
      String id, {
      required bool shouldUnlock,
    }) {
      final idx = _badges.indexWhere((b) => b.id == id);
      if (idx == -1) return null;
      final current = _badges[idx];
      if (!shouldUnlock || current.isUnlocked) return null;
      final updated =
          current.copyWith(status: BadgeStatus.unlocked, unlockedAt: now);
      final next = List<BadgeModel>.from(_badges);
      next[idx] = updated;
      _badges = next;
      return updated;
    }

    // Streak badges
    for (final threshold in [3, 7, 14, 30]) {
      final unlocked =
          unlockIf('streak_$threshold', shouldUnlock: streakDays >= threshold);
      if (unlocked != null) {
        changed = true;
        _orchestrator.queueReward(
          rewards.BadgeUnlocked(
            badgeId: unlocked.id,
            badgeName: unlocked.title,
            emoji: '🏅',
          ),
        );
      }
    }

    // Tasks completed badges
    for (final threshold in [5, 20, 50]) {
      final unlocked = unlockIf('tasks_$threshold',
          shouldUnlock: tasksCompleted >= threshold);
      if (unlocked != null) {
        changed = true;
        _orchestrator.queueReward(
          rewards.BadgeUnlocked(
            badgeId: unlocked.id,
            badgeName: unlocked.title,
            emoji: '✅',
          ),
        );
      }
    }

    // Addiction-free days badges (mapped to provided value)
    for (final threshold in [3, 7, 30]) {
      final unlocked = unlockIf('free_$threshold',
          shouldUnlock: addictionFreeDays >= threshold);
      if (unlocked != null) {
        changed = true;
        _orchestrator.queueReward(
          rewards.BadgeUnlocked(
            badgeId: unlocked.id,
            badgeName: unlocked.title,
            emoji: '🌿',
          ),
        );
      }
    }

    if (changed) {
      await _persist();
      notifyListeners();
    }
  }
}
