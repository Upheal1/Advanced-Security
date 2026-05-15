/// Typed Dart models for the Upheal Roadmap API.
///
/// Maps directly from the Pydantic schemas in the backend:
///   - `ClinicalTask`    → `services/shared/schemas.py`
///   - `RoadmapResponse` → `services/gateway/schemas.py`
///
/// Extended with:
///   - ScreenTimeInsights for analytics
///   - RoadmapDay for 90-day calendar view
///   - Progress tracking and milestones
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

/// Screen time insights from the RAG system
class ScreenTimeInsights {
  const ScreenTimeInsights({
    required this.totalMinutes,
    required this.socialRatio,
    required this.productivityRatio,
    required this.topSocialApps,
    required this.topProductivityApps,
    required this.appBreakdown,
  });

  final double totalMinutes;
  final double socialRatio;
  final double productivityRatio;
  final List<String> topSocialApps;
  final List<String> topProductivityApps;
  final List<AppBreakdownItem> appBreakdown;

  factory ScreenTimeInsights.fromJson(Map<String, dynamic> json) {
    return ScreenTimeInsights(
      totalMinutes: (json['totalMinutes'] as num?)?.toDouble() ?? 0.0,
      socialRatio: (json['socialRatio'] as num?)?.toDouble() ?? 0.0,
      productivityRatio: (json['productivityRatio'] as num?)?.toDouble() ?? 0.0,
      topSocialApps: (json['topSocialApps'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      topProductivityApps: (json['topProductivityApps'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      appBreakdown: (json['appBreakdown'] as List<dynamic>?)
              ?.map((e) => AppBreakdownItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'totalMinutes': totalMinutes,
        'socialRatio': socialRatio,
        'productivityRatio': productivityRatio,
        'topSocialApps': topSocialApps,
        'topProductivityApps': topProductivityApps,
        'appBreakdown': appBreakdown.map((e) => e.toJson()).toList(),
      };

  String get formattedTotalTime {
    final hours = (totalMinutes / 60).floor();
    final mins = (totalMinutes % 60).round();
    return hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
  }

  int get totalHours => (totalMinutes / 60).round();
}

/// Individual app breakdown item
class AppBreakdownItem {
  const AppBreakdownItem({
    required this.packageName,
    required this.percentage,
    required this.category,
  });

  final String packageName;
  final double percentage;
  final String category;

  factory AppBreakdownItem.fromJson(Map<String, dynamic> json) {
    return AppBreakdownItem(
      packageName: json['packageName'] as String? ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'other',
    );
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'percentage': percentage,
        'category': category,
      };

  /// Convert package name to display name (e.g., com.instagram.android -> Instagram)
  String get displayName {
    final parts = packageName.split('.');
    if (parts.isEmpty) return packageName;
    final last = parts.last;
    return last.isNotEmpty
        ? last[0].toUpperCase() + last.substring(1)
        : packageName;
  }
}

/// A single day in the 90-day roadmap
class RoadmapDay {
  const RoadmapDay({
    required this.dayNumber,
    required this.task,
    required this.phase,
    this.dayContext,
  });

  final int dayNumber;
  final ClinicalTask task;
  final String phase;
  final String? dayContext;

  factory RoadmapDay.fromJson(Map<String, dynamic> json) {
    return RoadmapDay(
      dayNumber: json['day_number'] as int? ?? 1,
      task: ClinicalTask.fromJson(json['task'] as Map<String, dynamic>? ?? {}),
      phase: json['phase'] as String? ?? 'Quick Win',
      dayContext: json['day_context'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'day_number': dayNumber,
        'task': task.toJson(),
        'phase': phase,
        if (dayContext != null) 'day_context': dayContext,
      };
}

/// Extended roadmap response with all RAG features
class RoadmapFullResponse {
  const RoadmapFullResponse({
    required this.userId,
    required this.overviewParagraph,
    required this.suggestedTasks,
    required this.safetyStatus,
    required this.nextCheckupDays,
    required this.generatedAt,
    this.sessionId,
    this.version = '1.0',
    this.screenTimeInsights,
    this.days = const [],
    this.totalDays = 90,
    this.assessmentRequired = false,
    this.anxietyProbability,
    this.depressionProbability,
    this.severity,
    this.comorbidity,
  });

  final String userId;
  final String overviewParagraph;
  final List<ClinicalTask> suggestedTasks;
  final String safetyStatus;
  final int nextCheckupDays;
  final String generatedAt;
  final String? sessionId;
  final String version;
  final ScreenTimeInsights? screenTimeInsights;
  final List<RoadmapDay> days;
  final int totalDays;
  final bool assessmentRequired;
  final double? anxietyProbability;
  final double? depressionProbability;
  final Map<String, String>? severity;
  final String? comorbidity;

  factory RoadmapFullResponse.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['suggested_tasks'] as List<dynamic>? ?? [];
    final rawDays = json['days'] as List<dynamic>? ?? [];

    return RoadmapFullResponse(
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
      screenTimeInsights: json['screen_time_insights'] != null
          ? ScreenTimeInsights.fromJson(
              json['screen_time_insights'] as Map<String, dynamic>)
          : null,
      days: rawDays
          .map((e) => RoadmapDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDays: (json['total_days'] as num?)?.toInt() ?? 90,
      assessmentRequired: json['assessment_required'] as bool? ?? false,
      anxietyProbability: (json['anxiety_probability'] as num?)?.toDouble(),
      depressionProbability: (json['depression_probability'] as num?)?.toDouble(),
      severity: json['severity'] != null
          ? Map<String, String>.from(json['severity'] as Map)
          : null,
      comorbidity: json['comorbidity'] as String?,
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
        if (screenTimeInsights != null)
          'screen_time_insights': screenTimeInsights!.toJson(),
        'days': days.map((d) => d.toJson()).toList(),
        'total_days': totalDays,
        'assessment_required': assessmentRequired,
        if (anxietyProbability != null) 'anxiety_probability': anxietyProbability,
        if (depressionProbability != null)
          'depression_probability': depressionProbability,
        if (severity != null) 'severity': severity,
        if (comorbidity != null) 'comorbidity': comorbidity,
      };

  // ─── Convenience getters ─────────────────────────────────────────────

  List<ClinicalTask> get quickWins =>
      suggestedTasks.where((t) => t.phase == 'Quick Win').toList();

  List<ClinicalTask> get ladderTasks =>
      suggestedTasks.where((t) => t.phase == 'Ladder').toList();

  List<ClinicalTask> get bossTasks =>
      suggestedTasks.where((t) => t.phase == 'Boss').toList();

  int get totalXp =>
      suggestedTasks.fold(0, (sum, task) => sum + task.xpReward);

  int get completedTasks => 0; // Would be set from backend/completion tracking

  double get progressPercentage {
    if (totalDays == 0) return 0;
    return completedTasks / totalDays;
  }

  /// Quick Win phase: Days 1-30 (roughly first third)
  List<RoadmapDay> get quickWinsPhase =>
      days.where((d) => d.dayNumber <= 30).toList();

  /// Ladder phase: Days 31-60 (roughly middle third)
  List<RoadmapDay> get ladderPhase =>
      days.where((d) => d.dayNumber > 30 && d.dayNumber <= 60).toList();

  /// Boss phase: Days 61-90 (roughly final third)
  List<RoadmapDay> get bossPhase =>
      days.where((d) => d.dayNumber > 60).toList();
}

/// Phase configuration for UI theming
class PhaseConfig {
  const PhaseConfig({
    required this.name,
    required this.displayName,
    required this.color,
    required this.icon,
    required this.gradient,
    this.description,
  });

  final String name;
  final String displayName;
  final int color;
  final String icon;
  final List<int> gradient;
  final String? description;

  static const PhaseConfig quickWin = PhaseConfig(
    name: 'Quick Win',
    displayName: 'Quick Wins',
    color: 0xFF22C55E,
    icon: 'rocket',
    gradient: [0xFF22C55E, 0xFF4ADE80],
    description: 'Easy tasks to build momentum',
  );

  static const PhaseConfig ladder = PhaseConfig(
    name: 'Ladder',
    displayName: 'Ladder',
    color: 0xFFEAB308,
    icon: 'trendingUp',
    gradient: [0xFFEAB308, 0xFFFBBF24],
    description: 'Moderate challenges to grow',
  );

  static const PhaseConfig boss = PhaseConfig(
    name: 'Boss',
    displayName: 'Boss Level',
    color: 0xFFEF4444,
    icon: 'crown',
    gradient: [0xFFEF4444, 0xFFF87171],
    description: 'Major breakthroughs await',
  );

  static PhaseConfig fromPhase(String phase) {
    switch (phase) {
      case 'Quick Win':
        return quickWin;
      case 'Ladder':
        return ladder;
      case 'Boss':
        return boss;
      default:
        return quickWin;
    }
  }
}

/// Safety status configuration
class SafetyStatusConfig {
  const SafetyStatusConfig({
    required this.status,
    required this.color,
    required this.icon,
    required this.message,
    required this.priorityMessage,
  });

  final String status;
  final int color;
  final String icon;
  final String message;
  final String priorityMessage;

  static const SafetyStatusConfig green = SafetyStatusConfig(
    status: 'GREEN',
    color: 0xFF22C55E,
    icon: 'checkCircle',
    message: "You're doing well!",
    priorityMessage: 'Keep up the great progress',
  );

  static const SafetyStatusConfig yellow = SafetyStatusConfig(
    status: 'YELLOW',
    color: 0xFFEAB308,
    icon: 'alertCircle',
    message: 'Some concerns detected',
    priorityMessage: 'Check flagged items with your clinician',
  );

  static const SafetyStatusConfig red = SafetyStatusConfig(
    status: 'RED',
    color: 0xFFEF4444,
    icon: 'alertTriangle',
    message: 'Please seek professional help',
    priorityMessage: 'Your safety is our priority',
  );

  static SafetyStatusConfig fromStatus(String status) {
    switch (status) {
      case 'GREEN':
        return green;
      case 'YELLOW':
        return yellow;
      case 'RED':
        return red;
      default:
        return green;
    }
  }
}
