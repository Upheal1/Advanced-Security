import 'package:flutter_test/flutter_test.dart';

import 'package:upheal/services/supabase_service.dart';

/// [SupabaseService] wraps [CommunitySupabase.clientOrNull].
///
/// In a unit-test environment Supabase is never initialised, so
/// [CommunitySupabase.clientOrNull] always returns null.  These tests confirm
/// that the service degrades gracefully in that state and that the public API
/// surface matches what the rest of the app expects.
void main() {
  group('SupabaseService — Supabase not initialised', () {
    // ── idToken ──────────────────────────────────────────────────────────────

    test('idToken returns null when Supabase is not initialised', () async {
      final token = await SupabaseService.idToken;
      expect(token, isNull);
    });

    test('idToken is a Future (async getter)', () {
      // Calling idToken must return a Future, not throw synchronously.
      expect(SupabaseService.idToken, isA<Future<String?>>());
    });

    test('idToken completes without throwing', () async {
      await expectLater(SupabaseService.idToken, completes);
    });

    // ── userId ───────────────────────────────────────────────────────────────

    test('userId returns null when Supabase is not initialised', () {
      expect(SupabaseService.userId, isNull);
    });

    test('userId is synchronous (non-Future)', () {
      // Should NOT return a Future — callers rely on it being sync.
      final result = SupabaseService.userId;
      expect(result, isNot(isA<Future>()));
    });
  });
}
