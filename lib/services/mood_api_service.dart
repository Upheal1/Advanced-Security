import 'package:flutter/foundation.dart';
import '../models/mood_entry.dart';
import '../utils/api_exceptions.dart';
import '../features/community/services/community_supabase.dart';

/// Service for mood operations backed by Supabase.
/// Table: `mood_entries` — columns: id TEXT PK, user_id UUID, mood TEXT, date TEXT, timestamp TIMESTAMPTZ
class MoodApiService {
  // No-arg constructor kept so call sites require no changes.
  MoodApiService();

  // ── CRUD ──────────────────────────────────────────────────────────────────

  String _uid() {
    final uid = CommunitySupabase.clientOrNull?.auth.currentUser?.id;
    if (uid == null) {
      throw UnauthorizedException('User must be authenticated to access mood entries.');
    }
    return uid;
  }

  /// Save (upsert) a mood entry.
  Future<void> saveEntry(MoodEntry entry) async {
    try {
      final uid = _uid();
      if (kDebugMode) debugPrint('MoodApiService.saveEntry: saving ${entry.id} for $uid');
      await CommunitySupabase.clientOrNull!.from('mood_entries').upsert({
        'id': entry.id,
        'user_id': uid,
        'mood': entry.mood,
        'date': entry.date.toIso8601String().split('T')[0],
        'timestamp': entry.timestamp.toIso8601String(),
      });
      if (kDebugMode) debugPrint('MoodApiService.saveEntry: saved ${entry.id}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to save mood entry: $e', 500);
    }
  }

  /// Get all mood entries for the current user, newest first.
  Future<List<MoodEntry>> getEntries() async {
    try {
      final uid = CommunitySupabase.clientOrNull?.auth.currentUser?.id;
      if (uid == null) return [];
      final rows = await CommunitySupabase.clientOrNull!
          .from('mood_entries')
          .select()
          .eq('user_id', uid)
          .order('timestamp', ascending: false);
      return _parseRows(rows);
    } catch (e) {
      if (kDebugMode) debugPrint('MoodApiService.getEntries error: $e');
      return [];
    }
  }

  /// Get a mood entry by date (YYYY-MM-DD).
  Future<MoodEntry?> getEntryByDate(DateTime date) async {
    try {
      final uid = CommunitySupabase.clientOrNull?.auth.currentUser?.id;
      if (uid == null) return null;
      final dateStr = date.toIso8601String().split('T')[0];
      final row = await CommunitySupabase.clientOrNull!
          .from('mood_entries')
          .select()
          .eq('user_id', uid)
          .eq('date', dateStr)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      return MoodEntry.fromJson(row);
    } catch (e) {
      if (kDebugMode) debugPrint('MoodApiService.getEntryByDate error: $e');
      return null;
    }
  }

  /// Get entries within a date range (inclusive).
  Future<List<MoodEntry>> getEntriesInRange(DateTime start, DateTime end) async {
    try {
      final uid = CommunitySupabase.clientOrNull?.auth.currentUser?.id;
      if (uid == null) return [];
      final rows = await CommunitySupabase.clientOrNull!
          .from('mood_entries')
          .select()
          .eq('user_id', uid)
          .gte('timestamp', start.toIso8601String())
          .lte('timestamp', end.add(const Duration(days: 1)).toIso8601String())
          .order('timestamp', ascending: false);
      return _parseRows(rows);
    } catch (e) {
      if (kDebugMode) debugPrint('MoodApiService.getEntriesInRange error: $e');
      return [];
    }
  }

  /// Delete a mood entry by id.
  Future<void> deleteEntry(String id) async {
    try {
      final uid = _uid();
      await CommunitySupabase.clientOrNull!
          .from('mood_entries')
          .delete()
          .eq('id', id)
          .eq('user_id', uid);
      if (kDebugMode) debugPrint('MoodApiService.deleteEntry: deleted $id');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete mood entry: $e', 500);
    }
  }

  // ── Analysis helpers ───────────────────────────────────────────────────────

  Future<List<MoodEntry>> getEntriesForAnalysis({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final uid = userId ?? CommunitySupabase.clientOrNull?.auth.currentUser?.id;
      if (uid == null) return [];

      var q = CommunitySupabase.clientOrNull!
          .from('mood_entries')
          .select()
          .eq('user_id', uid);

      if (startDate != null) {
        q = q.gte('timestamp', startDate.toIso8601String());
      }
      if (endDate != null) {
        q = q.lte('timestamp',
            endDate.add(const Duration(days: 1)).toIso8601String());
      }

      var ordered = q.order('timestamp', ascending: false);
      if (limit != null) {
        ordered = ordered.limit(limit);
      }

      final rows = await ordered;
      return _parseRows(rows);
    } catch (e) {
      if (kDebugMode) debugPrint('MoodApiService.getEntriesForAnalysis error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> analyzeMoodTrends({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final entries = await getEntriesForAnalysis(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    if (entries.isEmpty) {
      return {
        'status': 'no_data',
        'message': 'No mood entries found for the specified period.',
      };
    }

    final avgMood =
        entries.map((e) => e.moodValue).reduce((a, b) => a + b) / entries.length;

    return {
      'status': 'success',
      'totalEntries': entries.length,
      'averageMood': avgMood,
      'entries': entries.map((e) => e.toJson()).toList(),
      'message': 'Mood trends calculated successfully.',
    };
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  List<MoodEntry> _parseRows(List<dynamic> rows) {
    final entries = <MoodEntry>[];
    for (final row in rows) {
      try {
        entries.add(MoodEntry.fromJson(row as Map<String, dynamic>));
      } catch (e) {
        if (kDebugMode) debugPrint('MoodApiService: parse error: $e');
      }
    }
    return entries;
  }
}
