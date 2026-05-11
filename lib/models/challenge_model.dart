import 'package:flutter/material.dart';

enum ChallengeCategory { daily, weekly, special }

enum ChallengeDifficulty { easy, medium, hard, legendary }

enum ChallengeStatus { available, active, completed, expired }

class ChallengeModel {
  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.difficulty,
    required this.xpReward,
    required this.durationHours,
    required this.targetCount,
    this.currentCount = 0,
    this.status = ChallengeStatus.available,
    this.startedAt,
    this.completedAt,
    this.expiresAt,
    required this.participantCount,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
  final ChallengeCategory category;
  final ChallengeDifficulty difficulty;
  final int xpReward;
  final int durationHours;
  final int targetCount;
  final int participantCount;

  int currentCount;
  ChallengeStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;

  double get progress {
    if (targetCount == 0) return 0.0;
    final value = currentCount / targetCount;
    return value.clamp(0.0, 1.0);
  }

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  String get timeLeftLabel {
    if (expiresAt == null) return 'No limit';
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return 'Expired';

    final diff = expiresAt!.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    if (hours <= 0 && minutes <= 0) return 'Less than 1 min left';
    if (hours == 0) return '$minutes min left';
    if (minutes == 0) return '${hours}h left';
    return '${hours}h ${minutes}m left';
  }

  String get difficultyLabel {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 'Easy';
      case ChallengeDifficulty.medium:
        return 'Medium';
      case ChallengeDifficulty.hard:
        return 'Hard';
      case ChallengeDifficulty.legendary:
        return 'Legendary';
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return const Color(0xFF1D9E75); // teal
      case ChallengeDifficulty.medium:
        return const Color(0xFF378ADD); // blue
      case ChallengeDifficulty.hard:
        return const Color(0xFF7F77DD); // purple
      case ChallengeDifficulty.legendary:
        return const Color(0xFFBA7517); // amber
    }
  }

  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    ChallengeCategory? category,
    ChallengeDifficulty? difficulty,
    int? xpReward,
    int? durationHours,
    int? targetCount,
    int? currentCount,
    ChallengeStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? expiresAt,
    int? participantCount,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      xpReward: xpReward ?? this.xpReward,
      durationHours: durationHours ?? this.durationHours,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      participantCount: participantCount ?? this.participantCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'emoji': emoji,
      'category': category.name,
      'difficulty': difficulty.name,
      'xpReward': xpReward,
      'durationHours': durationHours,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'status': status.name,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'participantCount': participantCount,
    };
  }

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String,
      category: ChallengeCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ChallengeCategory.daily,
      ),
      difficulty: ChallengeDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => ChallengeDifficulty.easy,
      ),
      xpReward: (json['xpReward'] as num).toInt(),
      durationHours: (json['durationHours'] as num).toInt(),
      targetCount: (json['targetCount'] as num).toInt(),
      currentCount: (json['currentCount'] as num?)?.toInt() ?? 0,
      status: ChallengeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ChallengeStatus.available,
      ),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      participantCount: (json['participantCount'] as num).toInt(),
    );
  }

  static List<ChallengeModel> getDefaultChallenges() {
    final now = DateTime.now();

    DateTime? _expiresFromHours(int hours) =>
        hours > 0 ? now.add(Duration(hours: hours)) : null;

    return [
      // Daily challenges
      ChallengeModel(
        id: 'daily_breathe',
        title: 'Breathing reset',
        description: 'Complete a 5-minute box breathing session',
        emoji: '🌬️',
        category: ChallengeCategory.daily,
        difficulty: ChallengeDifficulty.easy,
        xpReward: 20,
        durationHours: 24,
        targetCount: 1,
        currentCount: 0,
        status: ChallengeStatus.available,
        startedAt: null,
        completedAt: null,
        expiresAt: _expiresFromHours(24),
        participantCount: 843,
      ),
      ChallengeModel(
        id: 'daily_focus_sprint',
        title: 'Focus sprint',
        description: 'Complete 3 deep work sessions today',
        emoji: '⚡',
        category: ChallengeCategory.daily,
        difficulty: ChallengeDifficulty.medium,
        xpReward: 50,
        durationHours: 24,
        targetCount: 3,
        currentCount: 0,
        status: ChallengeStatus.available,
        startedAt: null,
        completedAt: null,
        expiresAt: _expiresFromHours(24),
        participantCount: 1204,
      ),
      ChallengeModel(
        id: 'daily_no_scroll',
        title: 'No doom scrolling',
        description: 'Keep social media under 15 minutes today',
        emoji: '📵',
        category: ChallengeCategory.daily,
        difficulty: ChallengeDifficulty.hard,
        xpReward: 100,
        durationHours: 24,
        targetCount: 1,
        currentCount: 0,
        status: ChallengeStatus.available,
        startedAt: null,
        completedAt: null,
        expiresAt: _expiresFromHours(24),
        participantCount: 567,
      ),
      ChallengeModel(
        id: 'daily_journal',
        title: 'Reflect & write',
        description: 'Write a 3-minute journal entry',
        emoji: '📓',
        category: ChallengeCategory.daily,
        difficulty: ChallengeDifficulty.easy,
        xpReward: 20,
        durationHours: 24,
        targetCount: 1,
        currentCount: 0,
        status: ChallengeStatus.available,
        startedAt: null,
        completedAt: null,
        expiresAt: _expiresFromHours(24),
        participantCount: 692,
      ),

      // Weekly challenges
      ChallengeModel(
        id: 'weekly_streak',
        title: '7-day warrior',
        description: 'Maintain your streak for 7 days straight',
        emoji: '🔥',
        category: ChallengeCategory.weekly,
        difficulty: ChallengeDifficulty.hard,
        xpReward: 100,
        durationHours: 168,
        targetCount: 7,
        currentCount: 0,
        status: ChallengeStatus.available,
        startedAt: null,
        completedAt: null,
        expiresAt: _expiresFromHours(168),
        participantCount: 389,
      ),
      ChallengeModel(
        id: 'weekly_focus_hours',
        title: '10 hours focused',
        description: 'Accumulate 10 hours of deep work this week',
        emoji: '🧠',
        category: ChallengeCategory.weekly,
        difficulty: ChallengeDifficulty.legendary,
        xpReward: 200,
        durationHours: 168,
        targetCount: 10,
        currentCount: 0,
        status: ChallengeStatus.available,
        startedAt: null,
        completedAt: null,
        expiresAt: _expiresFromHours(168),
        participantCount: 201,
      ),
      ChallengeModel(
        id: 'weekly_urge_resist',
        title: 'Urge master',
        description: 'Resist 5 urges using the breathing tool',
        emoji: '🛡️',
        category: ChallengeCategory.weekly,
        difficulty: ChallengeDifficulty.medium,
        xpReward: 50,
        durationHours: 168,
        targetCount: 5,
        currentCount: 0,
        status: ChallengeStatus.available,
        startedAt: null,
        completedAt: null,
        expiresAt: _expiresFromHours(168),
        participantCount: 445,
      ),

      // Special challenges
      ChallengeModel(
        id: 'special_cold_shower',
        title: 'Cold shower week',
        description: 'Take a cold shower 5 days in a row',
        emoji: '🚿',
        category: ChallengeCategory.special,
        difficulty: ChallengeDifficulty.hard,
        xpReward: 100,
        durationHours: 168,
        targetCount: 5,
        currentCount: 0,
        status: ChallengeStatus.available,
        startedAt: null,
        completedAt: null,
        expiresAt: _expiresFromHours(168),
        participantCount: 234,
      ),
      ChallengeModel(
        id: 'special_dopamine_detox',
        title: 'Dopamine detox',
        description: '24 hours with zero social media or entertainment',
        emoji: '🧘',
        category: ChallengeCategory.special,
        difficulty: ChallengeDifficulty.legendary,
        xpReward: 200,
        durationHours: 24,
        targetCount: 1,
        currentCount: 0,
        status: ChallengeStatus.available,
        startedAt: null,
        completedAt: null,
        expiresAt: _expiresFromHours(24),
        participantCount: 156,
      ),
      ChallengeModel(
        id: 'special_sleep_early',
        title: 'Early to bed',
        description: 'Sleep before midnight for 3 nights in a row',
        emoji: '🌙',
        category: ChallengeCategory.special,
        difficulty: ChallengeDifficulty.medium,
        xpReward: 50,
        durationHours: 72,
        targetCount: 3,
        currentCount: 0,
        status: ChallengeStatus.available,
        startedAt: null,
        completedAt: null,
        expiresAt: _expiresFromHours(72),
        participantCount: 378,
      ),
    ];
  }
}

