import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'supabase_service.dart';

/// Base URL for the UpHeal backend.
///
/// Set via --dart-define=UPHEAL_API_URL=https://your-server.com at build time.
///
/// Default values for local development:
///   - Android emulator: http://10.0.2.2:8000
///   - Physical device: use your machine's local IP, e.g. http://192.168.x.x:8000
///
/// For production: always use HTTPS.
const String uphealBaseUrl = String.fromEnvironment(
  'UPHEAL_API_URL',
  defaultValue: 'http://192.168.1.3:8000',
);

class UphealApi {
  final String baseUrl;

  /// An [http.Client] used for every request.
  ///
  /// Inject a custom client (e.g. [MockClient]) in tests; omit in production
  /// to use a default [http.Client] instance.
  final http.Client _client;

  /// Request timeout. Defaults to 90 seconds; override in tests.
  final Duration timeout;

  UphealApi({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 90),
  }) : _client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// Builds HTTP headers for every request.
  ///
  /// When the user is signed in the Supabase JWT is injected automatically.
  /// The Flutter SDK refreshes the token before expiry, so this always
  /// returns a valid (non-expired) bearer token.
  Future<Map<String, String>> _getHeaders() async {
    final token = await SupabaseService.idToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Public endpoints ──────────────────────────────────────────────────────

  /// GET /health — confirms the backend and knowledge-base are reachable.
  Future<Map<String, dynamic>> health() async {
    final response = await _client.get(_uri('/health'));
    if (response.statusCode != 200) {
      throw Exception(
        'Health check failed (${response.statusCode}): ${response.body}',
      );
    }
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected health response shape.');
  }

  /// POST /api/assess — run the GAD-7 + PHQ-9 clinical assessment.
  ///
  /// [answers]        — Map of question keys to scores (0–3).
  ///                    Keys: gad7_q1…gad7_q7, phq9_q1…phq9_q9.
  /// [userId]         — Supabase user UUID.
  /// [sessionId]      — Optional; continues an existing session.
  /// [screenTimeData] — Optional per-app usage data.
  Future<Map<String, dynamic>> assess({
    required Map<String, int> answers,
    required String userId,
    String? sessionId,
    Map<String, dynamic>? screenTimeData,
  }) async {
    final headers = await _getHeaders();
    final payload = <String, dynamic>{
      'answers': answers,
      'user_id': userId,
    };
    if (sessionId != null) payload['session_id'] = sessionId;
    if (screenTimeData != null) payload['screenTimeData'] = screenTimeData;

    debugPrint('[UphealApi] POST /api/assess  answers=${answers.length}  userId=$userId');

    try {
      final response = await _client
          .post(
            _uri('/api/assess'),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(
            timeout,
            onTimeout: () =>
                throw TimeoutException('assess() timed out after 90 s.'),
          );

      if (kDebugMode) {
        debugPrint('[UphealApi] assess → ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        if (kDebugMode) debugPrint('[UphealApi] error: ${response.body}');
        throw Exception(
          'Assessment failed (${response.statusCode}). Please try again.',
        );
      }

      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected assess response shape.');
    } catch (e) {
      if (kDebugMode) debugPrint('[UphealApi] assess exception: $e');
      rethrow;
    }
  }

  /// POST /api/roadmap — generate a new personalised wellness roadmap.
  ///
  /// [topN] controls how many tasks are returned (1–10, default 5 on the server).
  Future<Map<String, dynamic>> roadmap({
    required String userId,
    required Map<String, int> answers,
    Map<String, dynamic>? screenTimeData,
    int? topN,
  }) async {
    final headers = await _getHeaders();
    final payload = <String, dynamic>{
      'user_id': userId,
      'answers': answers,
    };
    if (screenTimeData != null) payload['screenTimeData'] = screenTimeData;
    if (topN != null) payload['top_n'] = topN;

    if (kDebugMode) {
      debugPrint('[UphealApi] POST /api/roadmap  topN=$topN');
    }

    final response = await _client
        .post(
          _uri('/api/roadmap'),
          headers: headers,
          body: jsonEncode(payload),
        )
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('roadmap() timed out after 90 s.'),
        );

    if (kDebugMode) {
      debugPrint('[UphealApi] roadmap → ${response.statusCode}');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to generate roadmap (${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected roadmap response shape.');
  }

  // ─── Auth-protected endpoints (🔒 JWT required) ───────────────────────────

  /// GET /api/roadmap/{userId} — fetch the user's current active roadmap.
  ///
  /// Throws a descriptive [Exception] on:
  ///   - 401: user not signed in
  ///   - 404: no roadmap has been generated yet
  Future<Map<String, dynamic>> roadmapStatus(String userId) async {
    final headers = await _getHeaders();

    if (kDebugMode) {
      debugPrint('[UphealApi] GET /api/roadmap/$userId');
    }

    final response = await _client
        .get(
          _uri('/api/roadmap/$userId'),
          headers: headers,
        )
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('roadmapStatus() timed out after 90 s.'),
        );

    if (kDebugMode) {
      debugPrint('[UphealApi] roadmapStatus → ${response.statusCode}');
    }

    if (response.statusCode == 401) {
      throw Exception('Not authenticated. Please sign in.');
    }
    if (response.statusCode == 404) {
      throw Exception('No roadmap found for user $userId.');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get roadmap status (${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected roadmapStatus response shape.');
  }

  /// GET /api/roadmap/{userId}/history — fetch past roadmaps for the user.
  ///
  /// Returns `{ "roadmaps": [...], "total_count": int }`.
  ///
  /// Throws a descriptive [Exception] on:
  ///   - 401: user not signed in
  ///   - 404: no history for this user
  Future<Map<String, dynamic>> roadmapHistory(String userId) async {
    final headers = await _getHeaders();

    if (kDebugMode) {
      debugPrint('[UphealApi] GET /api/roadmap/$userId/history');
    }

    final response = await _client
        .get(
          _uri('/api/roadmap/$userId/history'),
          headers: headers,
        )
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('roadmapHistory() timed out after 90 s.'),
        );

    if (kDebugMode) {
      debugPrint('[UphealApi] roadmapHistory → ${response.statusCode}');
    }

    if (response.statusCode == 401) {
      throw Exception('Not authenticated. Please sign in.');
    }
    if (response.statusCode == 404) {
      throw Exception('No roadmap history found for user $userId.');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get roadmap history (${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected roadmapHistory response shape.');
  }
}
