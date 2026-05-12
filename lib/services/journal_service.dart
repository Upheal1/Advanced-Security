import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../features/community/services/community_supabase.dart';
import 'supabase_service.dart';

/// Journal service — reads/writes directly to the Supabase `journal_entries`
/// table. No local Hive cache, no REST backend.
class JournalService {
  // ── helpers ──────────────────────────────────────────────────────────────

  dynamic get _client {
    final c = CommunitySupabase.clientOrNull;
    if (c == null) throw Exception('Supabase not initialized');
    return c;
  }

  String get _userId {
    final id = SupabaseService.userId;
    if (id == null) throw Exception('User not authenticated');
    return id;
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<List<JournalEntry>> getEntries() async {
    final userId = _userId;
    debugPrint('[Journal] Fetching entries for user: $userId');
    final response = await _client
        .from('journal_entries')
        .select()
        .eq('user_id', userId)
        .eq('is_archived', false)
        .order('created_at', ascending: false);
    final list = response as List;
    debugPrint('[Journal] Fetched ${list.length} entries');
    return list
        .map((e) => JournalEntry.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveEntry(JournalEntry entry) async {
    final userId = _userId;
    debugPrint('[Journal] Saving entry for user: $userId');
    await _client
        .from('journal_entries')
        .insert(entry.toSupabase(userId));
    debugPrint('[Journal] Entry saved successfully');
  }

  Future<JournalEntry?> getEntryByDate(DateTime date) async {
    final userId = _userId;
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end =
        DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final response = await _client
        .from('journal_entries')
        .select()
        .eq('user_id', userId)
        .eq('is_archived', false)
        .gte('created_at', start)
        .lte('created_at', end)
        .limit(1);
    final list = response as List;
    if (list.isEmpty) return null;
    return JournalEntry.fromSupabase(list.first as Map<String, dynamic>);
  }

  Future<void> deleteEntry(String id) async {
    debugPrint('[Journal] Deleting entry $id');
    await _client.from('journal_entries').delete().eq('id', id);
  }

  Future<List<JournalEntry>> getEntriesInRange(
      DateTime start, DateTime end) async {
    final userId = _userId;
    final response = await _client
        .from('journal_entries')
        .select()
        .eq('user_id', userId)
        .eq('is_archived', false)
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => JournalEntry.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  /// No-op — Supabase is always in sync.
  Future<void> syncPendingEntries() async {}

  int getPendingSyncCount() => 0;
}

