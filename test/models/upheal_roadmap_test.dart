import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'package:upheal/models/upheal_roadmap.dart';
import 'package:upheal/services/roadmap_repository.dart';
import 'package:upheal/services/upheal_api.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

Map<String, dynamic> _taskJson({
  String taskId = 'task-1',
  String content = 'Do something helpful.',
  List<String> symptomTags = const ['anxiety'],
  int difficulty = 2,
  int xpReward = 80,
  bool safetyRisk = false,
  double utilityScore = 0.75,
  String sourceReference = 'ref-001',
  Map<String, dynamic>? metadata,
  String phase = 'Quick Win',
}) =>
    {
      'task_id': taskId,
      'content': content,
      'symptom_tags': symptomTags,
      'difficulty': difficulty,
      'xp_reward': xpReward,
      'safety_risk': safetyRisk,
      'utility_score': utilityScore,
      'source_reference': sourceReference,
      'metadata': metadata ?? {'key': 'value'},
      'phase': phase,
    };

Map<String, dynamic> _roadmapJson({
  String userId = 'user-abc',
  String overview = 'Your personalised plan.',
  List<Map<String, dynamic>>? tasks,
  String safetyStatus = 'GREEN',
  int nextCheckupDays = 14,
  String generatedAt = '2025-07-13T08:00:00Z',
  String? sessionId,
  String version = '1.0',
}) =>
    {
      'user_id': userId,
      'overview_paragraph': overview,
      'suggested_tasks': tasks ?? [_taskJson()],
      'safety_status': safetyStatus,
      'next_checkup_days': nextCheckupDays,
      'generated_at': generatedAt,
      if (sessionId != null) 'session_id': sessionId,
      'version': version,
    };

// ─── ClinicalTask.fromJson ────────────────────────────────────────────────────

void main() {
  group('ClinicalTask.fromJson', () {
    test('parses all fields correctly', () {
      final json = _taskJson(
        taskId: 't-42',
        content: 'Meditate for 10 min.',
        symptomTags: ['anxiety', 'stress'],
        difficulty: 3,
        xpReward: 100,
        safetyRisk: true,
        utilityScore: 0.9,
        sourceReference: 'mindfulness-protocol',
        metadata: {'modality': 'mindfulness'},
        phase: 'Ladder',
      );

      final task = ClinicalTask.fromJson(json);

      expect(task.taskId, 't-42');
      expect(task.content, 'Meditate for 10 min.');
      expect(task.symptomTags, ['anxiety', 'stress']);
      expect(task.difficulty, 3);
      expect(task.xpReward, 100);
      expect(task.safetyRisk, isTrue);
      expect(task.utilityScore, closeTo(0.9, 0.001));
      expect(task.sourceReference, 'mindfulness-protocol');
      expect(task.metadata, {'modality': 'mindfulness'});
      expect(task.phase, 'Ladder');
    });

    test('uses defaults for optional/nullable fields', () {
      final task = ClinicalTask.fromJson({
        'task_id': 'x',
        'content': 'Something',
        'symptom_tags': <dynamic>[],
        'difficulty': 1,
        'xp_reward': 10,
        'source_reference': 'ref',
      });

      expect(task.safetyRisk, isFalse);
      expect(task.utilityScore, 0.5);
      expect(task.metadata, isEmpty);
      expect(task.phase, 'Quick Win');
    });

    test('handles null / missing optional fields gracefully', () {
      final task = ClinicalTask.fromJson({});

      expect(task.taskId, '');
      expect(task.content, '');
      expect(task.symptomTags, isEmpty);
      expect(task.difficulty, 1);
      expect(task.xpReward, 0);
      expect(task.safetyRisk, isFalse);
      expect(task.utilityScore, 0.5);
      expect(task.sourceReference, '');
      expect(task.metadata, isEmpty);
      expect(task.phase, 'Quick Win');
    });

    test('toJson round-trips without data loss', () {
      final json = _taskJson(
        taskId: 'rt-1',
        difficulty: 5,
        xpReward: 200,
        safetyRisk: true,
        phase: 'Boss',
      );
      final task = ClinicalTask.fromJson(json);
      final out = task.toJson();

      expect(out['task_id'], json['task_id']);
      expect(out['difficulty'], json['difficulty']);
      expect(out['xp_reward'], json['xp_reward']);
      expect(out['safety_risk'], json['safety_risk']);
      expect(out['phase'], json['phase']);
    });
  });

  // ─── RoadmapResponse.fromJson ───────────────────────────────────────────────

  group('RoadmapResponse.fromJson', () {
    test('parses all top-level fields', () {
      final json = _roadmapJson(
        userId: 'u-1',
        overview: 'Focus on reducing anxiety.',
        safetyStatus: 'YELLOW',
        nextCheckupDays: 7,
        generatedAt: '2025-07-13T08:00:00Z',
        sessionId: 'sess-99',
        version: '2.0',
      );

      final resp = RoadmapResponse.fromJson(json);

      expect(resp.userId, 'u-1');
      expect(resp.overviewParagraph, 'Focus on reducing anxiety.');
      expect(resp.safetyStatus, 'YELLOW');
      expect(resp.nextCheckupDays, 7);
      expect(resp.generatedAt, '2025-07-13T08:00:00Z');
      expect(resp.sessionId, 'sess-99');
      expect(resp.version, '2.0');
    });

    test('parses suggested_tasks into ClinicalTask list', () {
      final json = _roadmapJson(
        tasks: [
          _taskJson(taskId: 'a', phase: 'Quick Win'),
          _taskJson(taskId: 'b', phase: 'Ladder'),
          _taskJson(taskId: 'c', phase: 'Boss'),
        ],
      );

      final resp = RoadmapResponse.fromJson(json);
      expect(resp.suggestedTasks, hasLength(3));
      expect(resp.suggestedTasks[0].taskId, 'a');
      expect(resp.suggestedTasks[2].phase, 'Boss');
    });

    test('handles empty suggested_tasks list', () {
      final json = _roadmapJson(tasks: []);
      final resp = RoadmapResponse.fromJson(json);
      expect(resp.suggestedTasks, isEmpty);
    });

    test('uses defaults when optional fields are absent', () {
      final resp = RoadmapResponse.fromJson({
        'user_id': 'u',
        'overview_paragraph': '',
        'safety_status': 'GREEN',
        'next_checkup_days': 14,
        'generated_at': '',
      });

      expect(resp.sessionId, isNull);
      expect(resp.version, '1.0');
    });

    test('toJson round-trips without data loss', () {
      final json = _roadmapJson(safetyStatus: 'RED', nextCheckupDays: 3);
      final resp = RoadmapResponse.fromJson(json);
      final out = resp.toJson();

      expect(out['safety_status'], 'RED');
      expect(out['next_checkup_days'], 3);
      expect((out['suggested_tasks'] as List).length,
          json['suggested_tasks'].length);
    });
  });

  // ─── Phase filter helpers ───────────────────────────────────────────────────

  group('RoadmapResponse phase filters', () {
    late RoadmapResponse resp;

    setUp(() {
      resp = RoadmapResponse.fromJson(_roadmapJson(
        tasks: [
          _taskJson(taskId: 'qw1', phase: 'Quick Win'),
          _taskJson(taskId: 'qw2', phase: 'Quick Win'),
          _taskJson(taskId: 'la1', phase: 'Ladder'),
          _taskJson(taskId: 'bo1', phase: 'Boss'),
          _taskJson(taskId: 'bo2', phase: 'Boss'),
        ],
      ));
    });

    test('quickWins returns only Quick Win tasks', () {
      expect(resp.quickWins, hasLength(2));
      expect(resp.quickWins.every((t) => t.phase == 'Quick Win'), isTrue);
    });

    test('ladderTasks returns only Ladder tasks', () {
      expect(resp.ladderTasks, hasLength(1));
      expect(resp.ladderTasks.first.taskId, 'la1');
    });

    test('bossTasks returns only Boss tasks', () {
      expect(resp.bossTasks, hasLength(2));
      expect(resp.bossTasks.every((t) => t.phase == 'Boss'), isTrue);
    });

    test('empty response returns empty lists for all phases', () {
      final empty = RoadmapResponse.fromJson(_roadmapJson(tasks: []));
      expect(empty.quickWins, isEmpty);
      expect(empty.ladderTasks, isEmpty);
      expect(empty.bossTasks, isEmpty);
    });
  });

  // ─── UphealApi.roadmapHistory ───────────────────────────────────────────────

  group('UphealApi.roadmapHistory()', () {
    const base = 'http://test.local';

    UphealApi _api(MockClient client) =>
        UphealApi(baseUrl: base, client: client);

    test('returns raw map on 200', () async {
      final payload = jsonEncode({
        'roadmaps': [_roadmapJson()],
        'total_count': 1,
      });
      final api = _api(MockClient((_) async =>
          http.Response(payload, 200)));

      final result = await api.roadmapHistory('user-abc');
      expect(result['total_count'], 1);
      expect((result['roadmaps'] as List).length, 1);
    });

    test('throws descriptive message on 401', () async {
      final api = _api(MockClient((_) async =>
          http.Response('{"detail":"Unauthorized"}', 401)));

      expect(
        () => api.roadmapHistory('user-abc'),
        throwsA(predicate<Exception>(
            (e) => e.toString().contains('Not authenticated'))),
      );
    });

    test('throws descriptive message on 404', () async {
      final api = _api(MockClient((_) async =>
          http.Response('{"detail":"Not found"}', 404)));

      expect(
        () => api.roadmapHistory('user-abc'),
        throwsA(predicate<Exception>(
            (e) => e.toString().contains('No roadmap history'))),
      );
    });

    test('throws on unexpected status code', () async {
      final api = _api(MockClient((_) async =>
          http.Response('Internal error', 500)));

      expect(() => api.roadmapHistory('u'), throwsException);
    });
  });

  // ─── RoadmapRepository ─────────────────────────────────────────────────────

  group('RoadmapRepository', () {
    const base = 'http://test.local';

    RoadmapRepository _repo(MockClient client) =>
        RoadmapRepository(UphealApi(baseUrl: base, client: client));

    test('generateRoadmap returns typed RoadmapResponse', () async {
      final payload = jsonEncode(_roadmapJson(
        tasks: [_taskJson(phase: 'Quick Win')],
        safetyStatus: 'GREEN',
      ));
      final repo = _repo(MockClient((_) async =>
          http.Response(payload, 200)));

      final result = await repo.generateRoadmap(userId: 'u-1');

      expect(result, isA<RoadmapResponse>());
      expect(result.suggestedTasks, isNotEmpty);
      expect(result.safetyStatus, 'GREEN');
    });

    test('getCurrentRoadmap returns typed RoadmapResponse', () async {
      final payload = jsonEncode(_roadmapJson(userId: 'u-2'));
      final repo = _repo(MockClient((_) async =>
          http.Response(payload, 200)));

      final result = await repo.getCurrentRoadmap('u-2');
      expect(result.userId, 'u-2');
    });

    test('getRoadmapHistory returns list of typed responses', () async {
      final payload = jsonEncode({
        'roadmaps': [
          _roadmapJson(userId: 'u-3'),
          _roadmapJson(userId: 'u-3', generatedAt: '2025-06-01T00:00:00Z'),
        ],
        'total_count': 2,
      });
      final repo = _repo(MockClient((_) async =>
          http.Response(payload, 200)));

      final list = await repo.getRoadmapHistory('u-3');
      expect(list, hasLength(2));
      expect(list.every((r) => r.userId == 'u-3'), isTrue);
    });

    test('getRoadmapHistory returns empty list on 404', () async {
      final repo = _repo(MockClient((_) async =>
          http.Response('{"detail":"Not found"}', 404)));

      final list = await repo.getRoadmapHistory('u-4');
      expect(list, isEmpty);
    });

    test('getRoadmapHistory propagates non-404 errors', () async {
      final repo = _repo(MockClient((_) async =>
          http.Response('Server error', 500)));

      expect(() => repo.getRoadmapHistory('u-5'), throwsException);
    });
  });
}
