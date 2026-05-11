import 'package:flutter/material.dart';

/// High‑level category of what an achievement represents.
///
/// This is separate from the specific condition logic so you can group badges
/// in the UI (e.g. streak vs progression vs special).
enum AchievementType {
  focusStreak,
  totalSessions,
  totalTime,
  level,
  special,
  // New types can be appended here without breaking existing persisted data.
}

/// How the player is meant to *earn* this achievement.
///
/// This is used by evaluation logic rather than the UI, so adding new entries
/// later should be done by appending to keep indices stable.
enum AchievementConditionType {
  totalXp,              // e.g. reach 5,000 XP
  streakDays,           // e.g. 7‑day streak
  totalFocusSessions,   // number of focus sessions completed
  totalFocusMinutes,    // total focus time
  moodLogs,             // number of mood logs
  questsCompleted,      // number of quests completed
  avatarUnlocked,       // unlock a specific avatar/cosmetic
  comebackDays,         // e.g. return after a break and stay active X days
  multi,                // compound condition evaluated via metadata
}

/// Rarity / prominence of a badge.
enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Visibility rules for achievements in the gallery.
enum AchievementVisibility {
  normal, // always visible
  hidden, // shown as locked / mystery until unlocked
}

/// A single condition that can contribute to unlocking an achievement.
///
/// The actual evaluation is done by an achievement manager/service which can
/// read global stats and compare them to [target] or inspect [params].
class AchievementCondition {
  final AchievementConditionType type;

  /// Primary numeric target for this condition (e.g. 7 days, 10 sessions).
  final int? target;

  /// Optional extra parameters (e.g. which quest id, which avatar id).
  final Map<String, dynamic>? params;

  const AchievementCondition({
    required this.type,
    this.target,
    this.params,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'target': target,
        if (params != null) 'params': params,
      };

  factory AchievementCondition.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String?;
    final conditionType = AchievementConditionType.values.firstWhere(
      (e) => e.name == rawType,
      orElse: () => AchievementConditionType.totalXp,
    );

    return AchievementCondition(
      type: conditionType,
      target: json['target'] as int?,
      params: (json['params'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final Color color;
  final AchievementType type;
  final int requirement;
  final int? currentProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int xpReward;
  final AchievementRarity rarity;
  final AchievementVisibility visibility;

  /// Optional list of conditions that define how this achievement is earned.
  ///
  /// When present, this should be preferred over [requirement] by new
  /// evaluation code. [requirement] is kept for backward compatibility and
  /// for simple, single‑metric achievements.
  final List<AchievementCondition>? conditions;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.type,
    required this.requirement,
    this.currentProgress,
    this.isUnlocked = false,
    this.unlockedAt,
    this.xpReward = 50,
    this.rarity = AchievementRarity.common,
    this.visibility = AchievementVisibility.normal,
    this.conditions,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    Color? color,
    AchievementType? type,
    int? requirement,
    int? currentProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? xpReward,
    AchievementRarity? rarity,
    AchievementVisibility? visibility,
    List<AchievementCondition>? conditions,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      requirement: requirement ?? this.requirement,
      currentProgress: currentProgress ?? this.currentProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      xpReward: xpReward ?? this.xpReward,
      rarity: rarity ?? this.rarity,
      visibility: visibility ?? this.visibility,
      conditions: conditions ?? this.conditions,
    );
  }

  double get progress {
    if (currentProgress == null) return 0.0;
    return (currentProgress! / requirement).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'color': color.value,
    'type': type.name,
    'requirement': requirement,
    'currentProgress': currentProgress,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'xpReward': xpReward,
    'rarity': rarity.name,
    'visibility': visibility.name,
    if (conditions != null)
      'conditions': conditions!.map((c) => c.toJson()).toList(),
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    icon: json['icon'],
    color: Color(json['color']),
    type: AchievementType.values.firstWhere((e) => e.name == json['type']),
    requirement: json['requirement'],
    currentProgress: json['currentProgress'],
    isUnlocked: json['isUnlocked'] ?? false,
    unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
    xpReward: json['xpReward'] ?? 50,
    rarity: _parseRarity(json['rarity']),
    visibility: _parseVisibility(json['visibility']),
    conditions: (json['conditions'] as List?)
        ?.map((c) => AchievementCondition.fromJson(
              (c as Map).cast<String, dynamic>(),
            ))
        .toList(),
  );

  static AchievementRarity _parseRarity(dynamic raw) {
    if (raw == null) return AchievementRarity.common;
    try {
      if (raw is String) {
        return AchievementRarity.values.firstWhere(
          (e) => e.name == raw,
          orElse: () => AchievementRarity.common,
        );
      }
    } catch (_) {
      // ignore and fall through
    }
    return AchievementRarity.common;
  }

  static AchievementVisibility _parseVisibility(dynamic raw) {
    if (raw == null) return AchievementVisibility.normal;
    try {
      if (raw is String) {
        return AchievementVisibility.values.firstWhere(
          (e) => e.name == raw,
          orElse: () => AchievementVisibility.normal,
        );
      }
    } catch (_) {
      // ignore and fall through
    }
    return AchievementVisibility.normal;
  }

  static List<Achievement> getDefaultAchievements() => [
    // Focus Streak Achievements
    Achievement(
      id: 'streak_3',
      title: 'Getting Started',
      description: 'Focus for 3 days in a row',
      icon: '🔥',
      color: Colors.orange,
      type: AchievementType.focusStreak,
      requirement: 3,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Focus for 7 days in a row',
      icon: '💪',
      color: Colors.red,
      type: AchievementType.focusStreak,
      requirement: 7,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Focus Master',
      description: 'Focus for 30 days in a row',
      icon: '👑',
      color: Colors.purple,
      type: AchievementType.focusStreak,
      requirement: 30,
    ),
    
    // Total Sessions Achievements
    Achievement(
      id: 'sessions_10',
      title: 'Dedicated',
      description: 'Complete 10 focus sessions',
      icon: '🎯',
      color: Colors.blue,
      type: AchievementType.totalSessions,
      requirement: 10,
    ),
    Achievement(
      id: 'sessions_50',
      title: 'Focused Mind',
      description: 'Complete 50 focus sessions',
      icon: '🧠',
      color: Colors.green,
      type: AchievementType.totalSessions,
      requirement: 50,
    ),
    Achievement(
      id: 'sessions_100',
      title: 'Zen Master',
      description: 'Complete 100 focus sessions',
      icon: '🧘',
      color: Colors.teal,
      type: AchievementType.totalSessions,
      requirement: 100,
    ),
    
    // Total Time Achievements
    Achievement(
      id: 'time_10h',
      title: 'Time Keeper',
      description: 'Focus for 10 hours total',
      icon: '⏰',
      color: Colors.indigo,
      type: AchievementType.totalTime,
      requirement: 600, // 10 hours in minutes
    ),
    Achievement(
      id: 'time_50h',
      title: 'Time Master',
      description: 'Focus for 50 hours total',
      icon: '⏳',
      color: Colors.deepPurple,
      type: AchievementType.totalTime,
      requirement: 3000, // 50 hours in minutes
    ),
    
    // Level Achievements
    Achievement(
      id: 'level_5',
      title: 'Rising Star',
      description: 'Reach level 5',
      icon: '⭐',
      color: Colors.yellow,
      type: AchievementType.level,
      requirement: 5,
    ),
    Achievement(
      id: 'level_10',
      title: 'Focus Champion',
      description: 'Reach level 10',
      icon: '🏆',
      color: Colors.amber,
      type: AchievementType.level,
      requirement: 10,
    ),
    
    // Special Achievements
    Achievement(
      id: 'first_session',
      title: 'First Steps',
      description: 'Complete your first focus session',
      icon: '🎉',
      color: Colors.pink,
      type: AchievementType.special,
      requirement: 1,
    ),
    Achievement(
      id: 'perfect_week',
      title: 'Perfect Week',
      description: 'Focus every day for a week',
      icon: '✨',
      color: Colors.cyan,
      type: AchievementType.special,
      requirement: 7,
    ),
  ];
}









