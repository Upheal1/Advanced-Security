import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:upheal/services/upheal_api.dart';

// Helper: build a UphealApi with a pre-canned MockClient.
UphealApi _api(MockClient client, {Duration? timeout}) =>
    UphealApi(
      baseUrl: 'http://localhost:8000',
      client: client,
      timeout: timeout ?? const Duration(seconds: 30),
    );

// Helper: returns a 200 JSON response.
http.Response _ok(Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), 200,
        headers: {'content-type': 'application/json'});

// Helper: returns any error response.
http.Response _err(int status, [String body = 'error']) =>
    http.Response(body, status);

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  group('UphealApi.health()', () {
    test('returns parsed map on 200', () async {
      final client = MockClient((_) async =>
          _ok({'status': 'ok', 'knowledge_base_healthy': true}));

      final result = await _api(client).health();

      expect(result['status'], 'ok');
      expect(result['knowledge_base_healthy'], true);
    });

    test('throws on non-200 status', () {
      final client = MockClient((_) async => _err(503));

      expect(_api(client).health(), throwsA(isA<Exception>()));
    });

    test('throws when response is a JSON list, not a map', () {
      final client = MockClient(
          (_) async => http.Response('["not","a","map"]', 200,
              headers: {'content-type': 'application/json'}));

      expect(_api(client).health(), throwsA(isA<Exception>()));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('UphealApi.assess()', () {
    final sampleResponse = {
      'anxiety_probability': 0.72,
      'depression_probability': 0.45,
      'severity': {'anxiety': 'moderate', 'depression': 'mild'},
      'comorbidity': false,
      'rag_recommendations': [],
      'query_used': 'test query',
    };

    test('returns parsed map on 200', () async {
      final client = MockClient((_) async => _ok(sampleResponse));

      final result = await _api(client).assess(
        answers: {'gad7_q1': 2, 'phq9_q1': 1},
        userId: 'user-123',
      );

      expect(result['anxiety_probability'], 0.72);
      expect(result['depression_probability'], 0.45);
    });

    test('sends userId and answers in request body', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return _ok(sampleResponse);
      });

      await _api(client).assess(
        answers: {'gad7_q1': 1},
        userId: 'user-abc',
      );

      expect(captured, isNotNull);
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['user_id'], 'user-abc');
      expect((body['answers'] as Map)['gad7_q1'], 1);
    });

    test('includes sessionId in body when provided', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return _ok(sampleResponse);
      });

      await _api(client).assess(
        answers: {'gad7_q1': 0},
        userId: 'u1',
        sessionId: 'sess-42',
      );

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['session_id'], 'sess-42');
    });

    test('includes screenTimeData in body when provided', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return _ok(sampleResponse);
      });

      await _api(client).assess(
        answers: {'gad7_q1': 1},
        userId: 'u2',
        screenTimeData: {'com.instagram.android': 90},
      );

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect((body['screenTimeData'] as Map)['com.instagram.android'], 90);
    });

    test('omits screenTimeData from body when not provided', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return _ok(sampleResponse);
      });

      await _api(client).assess(
        answers: {'gad7_q1': 0},
        userId: 'u3',
      );

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body.containsKey('screenTimeData'), isFalse);
    });

    test('throws on non-200 status', () {
      final client = MockClient((_) async => _err(422));

      expect(
        _api(client).assess(answers: {}, userId: 'u'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on unexpected response shape (list)', () {
      final client = MockClient(
          (_) async => http.Response('[]', 200,
              headers: {'content-type': 'application/json'}));

      expect(
        _api(client).assess(answers: {}, userId: 'u'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws TimeoutException when request exceeds timeout', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return _ok(sampleResponse);
      });

      expect(
        _api(client, timeout: const Duration(milliseconds: 100))
            .assess(answers: {}, userId: 'u'),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('adds Content-Type header', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return _ok(sampleResponse);
      });

      await _api(client).assess(answers: {}, userId: 'u');

      expect(captured!.headers['Content-Type'], contains('application/json'));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('UphealApi.roadmap()', () {
    final sampleRoadmap = {
      'user_id': 'u1',
      'tasks': [
        {'id': 1, 'title': 'Meditate', 'priority': 1}
      ],
    };

    test('returns parsed map on 200', () async {
      final client = MockClient((_) async => _ok(sampleRoadmap));

      final result = await _api(client).roadmap(
        userId: 'u1',
        answers: {'gad7_q1': 2},
      );

      expect(result['user_id'], 'u1');
      expect((result['tasks'] as List).length, 1);
    });

    test('sends userId and answers in body', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return _ok(sampleRoadmap);
      });

      await _api(client).roadmap(
        userId: 'user-xyz',
        answers: {'gad7_q1': 3},
      );

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['user_id'], 'user-xyz');
      expect((body['answers'] as Map)['gad7_q1'], 3);
    });

    test('includes topN in body when provided', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return _ok(sampleRoadmap);
      });

      await _api(client).roadmap(
        userId: 'u1',
        answers: {},
        topN: 3,
      );

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['top_n'], 3);
    });

    test('omits topN from body when not provided', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return _ok(sampleRoadmap);
      });

      await _api(client).roadmap(userId: 'u1', answers: {});

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body.containsKey('top_n'), isFalse);
    });

    test('throws on non-200 status', () {
      final client = MockClient((_) async => _err(500));

      expect(
        _api(client).roadmap(userId: 'u1', answers: {}),
        throwsA(isA<Exception>()),
      );
    });

    test('throws TimeoutException when request exceeds timeout', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return _ok(sampleRoadmap);
      });

      expect(
        _api(client, timeout: const Duration(milliseconds: 100))
            .roadmap(userId: 'u1', answers: {}),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('UphealApi.roadmapStatus()', () {
    const userId = 'user-999';
    final sampleStatus = {'user_id': userId, 'tasks': []};

    test('returns parsed map on 200', () async {
      final client = MockClient((_) async => _ok(sampleStatus));

      final result = await _api(client).roadmapStatus(userId);

      expect(result['user_id'], userId);
    });

    test('hits the correct URL path', () async {
      Uri? capturedUri;
      final client = MockClient((req) async {
        capturedUri = req.url;
        return _ok(sampleStatus);
      });

      await _api(client).roadmapStatus(userId);

      expect(capturedUri?.path, '/api/roadmap/$userId');
    });

    test('throws "Not authenticated" on 401', () {
      final client = MockClient((_) async => _err(401));

      expect(
        _api(client).roadmapStatus(userId),
        throwsA(predicate<Exception>(
            (e) => e.toString().contains('Not authenticated'))),
      );
    });

    test('throws "No roadmap found" on 404', () {
      final client = MockClient((_) async => _err(404));

      expect(
        _api(client).roadmapStatus(userId),
        throwsA(predicate<Exception>(
            (e) => e.toString().contains('No roadmap found'))),
      );
    });

    test('throws generic exception on other error codes', () {
      final client = MockClient((_) async => _err(500));

      expect(
        _api(client).roadmapStatus(userId),
        throwsA(isA<Exception>()),
      );
    });

    test('throws TimeoutException when request exceeds timeout', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return _ok(sampleStatus);
      });

      expect(
        _api(client, timeout: const Duration(milliseconds: 100))
            .roadmapStatus(userId),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('UphealApi._getHeaders() — no auth token', () {
    // When Supabase is not initialised (all unit tests), SupabaseService.idToken
    // returns null, so only Content-Type is present.

    test('assess() sends Content-Type: application/json', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return _ok({'anxiety_probability': 0.0, 'depression_probability': 0.0,
            'severity': {}, 'comorbidity': false, 'rag_recommendations': [],
            'query_used': ''});
      });

      await _api(client).assess(answers: {}, userId: 'u');

      expect(captured!.headers['content-type'], contains('application/json'));
    });

    test('assess() does NOT send Authorization when user is signed out', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return _ok({'anxiety_probability': 0.0, 'depression_probability': 0.0,
            'severity': {}, 'comorbidity': false, 'rag_recommendations': [],
            'query_used': ''});
      });

      await _api(client).assess(answers: {}, userId: 'u');

      expect(captured!.headers.containsKey('authorization'), isFalse);
    });
  });
}
