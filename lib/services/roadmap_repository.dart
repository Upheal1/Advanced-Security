import '../models/upheal_roadmap.dart';
import 'upheal_api.dart';

/// Repository that wraps [UphealApi] roadmap endpoints and converts raw
/// `Map<String,dynamic>` responses into typed [RoadmapResponse] objects.
class RoadmapRepository {
  const RoadmapRepository(this._api);

  final UphealApi _api;

  /// Calls `POST /api/roadmap` and returns a typed [RoadmapResponse].
  ///
  /// [userId]         — Supabase user UUID (required).
  /// [answers]        — Optional GAD-7/PHQ-9 answer map.
  /// [screenTimeData] — Optional per-app screen time payload.
  /// [topN]           — Number of tasks to return (1–10).
  Future<RoadmapResponse> generateRoadmap({
    required String userId,
    Map<String, int>? answers,
    Map<String, dynamic>? screenTimeData,
    int? topN,
  }) async {
    final raw = await _api.roadmap(
      userId: userId,
      answers: answers ?? {},
      screenTimeData: screenTimeData,
      topN: topN,
    );
    return RoadmapResponse.fromJson(raw);
  }

  /// Calls `GET /api/roadmap/{userId}` 🔒 and returns the active roadmap.
  ///
  /// Throws if the user is unauthenticated or has no roadmap yet.
  Future<RoadmapResponse> getCurrentRoadmap(String userId) async {
    final raw = await _api.roadmapStatus(userId);
    return RoadmapResponse.fromJson(raw);
  }

  /// Calls `GET /api/roadmap/{userId}/history` 🔒 and returns all past
  /// roadmaps for this user (most recent first).
  ///
  /// Returns an empty list if the endpoint responds with 404.
  Future<List<RoadmapResponse>> getRoadmapHistory(String userId) async {
    try {
      final raw = await _api.roadmapHistory(userId);
      final list = raw['roadmaps'] as List<dynamic>? ?? [];
      return list
          .map((e) => RoadmapResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception catch (e) {
      if (e.toString().contains('404') ||
          e.toString().contains('No roadmap history')) {
        return [];
      }
      rethrow;
    }
  }
}
