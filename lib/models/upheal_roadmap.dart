/// Typed Dart models for the Upheal Roadmap API.
///
/// Maps directly from the Pydantic schemas in the backend:
///   - `ClinicalTask`    → `services/shared/schemas.py`
///   - `RoadmapResponse` → `services/gateway/schemas.py`
library;

/// A single actionable clinical-style task returned inside a roadmap.
class ClinicalTask {
  const ClinicalTask({
    required this.taskId,
    required this.content,
    required this.symptomTags,
    required this.difficulty,
    required this.xpReward,
    required this.safetyRisk,
    required this.utilityScore,
    required this.sourceReference,
    required this.metadata,
    required this.phase,
  });

  final String taskId;
  final String content;
  final List<String> symptomTags;

  /// Difficulty level 1–5. 1–2 = Quick Win, 3 = Ladder, 4–5 = Boss.
  final int difficulty;

  /// Experience points awarded for completing this task.
  final int xpReward;

  /// `true` when the task involves content that should be flagged to a
  /// clinician (e.g. exposure therapy, crisis resources).
  final bool safetyRisk;

  /// Computed relevance score (0.0–1.0) used to rank tasks.
  final double utilityScore;

  /// Citation / knowledge-base reference for this task.
  final String sourceReference;

  /// Arbitrary key-value metadata attached by the backend pipeline.
  final Map<String, dynamic> metadata;

  /// Phase label: `"Quick Win"`, `"Ladder"`, or `"Boss"`.
  final String phase;

  factory ClinicalTask.fromJson(Map<String, dynamic> json) {
    return ClinicalTask(
      taskId: json['task_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      symptomTags: (json['symptom_tags'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 0,
      safetyRisk: json['safety_risk'] as bool? ?? false,
      utilityScore: (json['utility_score'] as num?)?.toDouble() ?? 0.5,
      sourceReference: json['source_reference'] as String? ?? '',
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      phase: json['phase'] as String? ?? 'Quick Win',
    );
  }

  Map<String, dynamic> toJson() => {
        'task_id': taskId,
        'content': content,
        'symptom_tags': symptomTags,
        'difficulty': difficulty,
        'xp_reward': xpReward,
        'safety_risk': safetyRisk,
        'utility_score': utilityScore,
        'source_reference': sourceReference,
        'metadata': metadata,
        'phase': phase,
      };

  @override
  String toString() => 'ClinicalTask(taskId: $taskId, phase: $phase)';
}

/// Full roadmap response returned by `POST /api/roadmap` and
/// `GET /api/roadmap/{user_id}`.
class RoadmapResponse {
  const RoadmapResponse({
    required this.userId,
    required this.overviewParagraph,
    required this.suggestedTasks,
    required this.safetyStatus,
    required this.nextCheckupDays,
    required this.generatedAt,
    this.sessionId,
    this.version = '1.0',
  });

  final String userId;
  final String overviewParagraph;
  final List<ClinicalTask> suggestedTasks;

  /// Safety status: `"GREEN"`, `"YELLOW"`, or `"RED"`.
  final String safetyStatus;

  /// Number of days until the next recommended check-up.
  final int nextCheckupDays;

  /// ISO-8601 timestamp when this roadmap was generated, e.g.
  /// `"2025-07-13T08:00:00Z"`.
  final String generatedAt;

  final String? sessionId;
  final String version;

  // ─── Convenience phase filters ─────────────────────────────────────────────

  /// All tasks with `phase == "Quick Win"`.
  List<ClinicalTask> get quickWins =>
      suggestedTasks.where((t) => t.phase == 'Quick Win').toList();

  /// All tasks with `phase == "Ladder"`.
  List<ClinicalTask> get ladderTasks =>
      suggestedTasks.where((t) => t.phase == 'Ladder').toList();

  /// All tasks with `phase == "Boss"`.
  List<ClinicalTask> get bossTasks =>
      suggestedTasks.where((t) => t.phase == 'Boss').toList();

  factory RoadmapResponse.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['suggested_tasks'] as List<dynamic>? ?? [];
    return RoadmapResponse(
      userId: json['user_id'] as String? ?? '',
      overviewParagraph: json['overview_paragraph'] as String? ?? '',
      suggestedTasks: rawTasks
          .map((e) => ClinicalTask.fromJson(e as Map<String, dynamic>))
          .toList(),
      safetyStatus: json['safety_status'] as String? ?? 'GREEN',
      nextCheckupDays: (json['next_checkup_days'] as num?)?.toInt() ?? 7,
      generatedAt: json['generated_at'] as String? ?? '',
      sessionId: json['session_id'] as String?,
      version: json['version'] as String? ?? '1.0',
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'overview_paragraph': overviewParagraph,
        'suggested_tasks': suggestedTasks.map((t) => t.toJson()).toList(),
        'safety_status': safetyStatus,
        'next_checkup_days': nextCheckupDays,
        'generated_at': generatedAt,
        if (sessionId != null) 'session_id': sessionId,
        'version': version,
      };

  @override
  String toString() =>
      'RoadmapResponse(userId: $userId, tasks: ${suggestedTasks.length}, safety: $safetyStatus)';
}
