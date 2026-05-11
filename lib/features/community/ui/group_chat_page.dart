import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/user_model.dart';
import '../services/community_repository.dart';

/// Standalone group chat using [CommunityRepository.fetchGroupMessages],
/// [CommunityRepository.subscribeToGroupMessages], and [CommunityRepository.sendGroupMessageViaEdge].
///
/// Prefer [GroupChatScreen] when you need typing indicators, presence, and images.
class GroupChatPage extends StatefulWidget {
  const GroupChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  late final CommunityRepository _repo;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  RealtimeChannel? _channel;
  bool _loading = true;
  bool _misconfigured = false;
  bool _sending = false;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _repo = context.read<CommunityRepository>();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!_repo.isConfigured) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _misconfigured = true;
      });
      return;
    }

    try {
      await _repo.ensureSession(displayName: context.read<UserModel>().username);
    } catch (_) {
      // Session setup failed; continue without auth (guest mode).
    }
    if (!mounted) return;
    await _loadMessages();
    await _subscribe();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _repo.fetchGroupMessages(widget.groupId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Load messages error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }

    _scrollToBottomSoon();
  }

  Future<void> _subscribe() async {
    try {
      _channel = await _repo.subscribeToGroupMessages(
        groupId: widget.groupId,
        onMessage: (message) {
          if (!mounted) return;

          setState(() {
            _messages.add(message);
          });

          _scrollToBottomSoon();
        },
        onError: (error) {
          debugPrint('Realtime error: $error');
        },
      );
    } catch (e) {
      debugPrint('Subscribe error: $e');
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _sending || !_repo.isConfigured) return;

    setState(() {
      _sending = true;
    });

    try {
      await _repo.ensureSession(displayName: context.read<UserModel>().username);
      await _repo.sendGroupMessageViaEdge(
        groupId: widget.groupId,
        content: text,
      );

      _controller.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      unawaited(_repo.removeRealtimeChannel(channel));
    }

    _controller.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _repo.currentUserId;
    final scheme = Theme.of(context).colorScheme;

    if (_misconfigured) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.groupName)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Community chat needs Supabase URL/key. Full restart with your Run config or '
              '.vscode/supabase.keys.json.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe =
                          currentUserId != null &&
                          message['sender_id'] == currentUserId;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: isMe
                                ? scheme.primaryContainer
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            message['content']?.toString() ?? '',
                            style: TextStyle(
                              color: isMe
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Write a supportive message...',
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
