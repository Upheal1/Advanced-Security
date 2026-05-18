import 'package:flutter/foundation.dart';

enum BadgeStatus { locked, unlocked }

/// Core badge entity used by the badge system.
@immutable
class BadgeModel {
  final String id;
  final String title;
  final String description;

  /// Asset path for the badge icon (png/jpg/etc). If missing, UI should fall back.
  final String? iconPath;

  final BadgeStatus status;

  /// Threshold used by badge rules (e.g. 7 days streak, 20 tasks completed).
  final int requiredValue;

  final DateTime? unlockedAt;

  const BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    this.iconPath,
    required this.status,
    required this.requiredValue,
    this.unlockedAt,
  });

  bool get isUnlocked => status == BadgeStatus.unlocked;

  BadgeModel copyWith({
    BadgeStatus? status,
    DateTime? unlockedAt,
  }) {
    return BadgeModel(
      id: id,
      title: title,
      description: description,
      iconPath: iconPath,
      status: status ?? this.status,
      requiredValue: requiredValue,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.name,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  BadgeModel mergeFromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String?;
    final unlockedAtStr = json['unlockedAt'] as String?;
    final parsedStatus = BadgeStatus.values
        .cast<BadgeStatus?>()
        .firstWhere((e) => e?.name == statusStr, orElse: () => null);
    return copyWith(
      status: parsedStatus ?? status,
      unlockedAt:
          unlockedAtStr != null ? DateTime.tryParse(unlockedAtStr) : unlockedAt,
    );
  }
}

/// Curated badges shipped with the app.
///
/// Note: `iconPath` points at assets (you can add real images later).
class DefaultBadges {
  static const List<BadgeModel> all = [
    // Streak badges
    BadgeModel(
      id: 'streak_3',
      title: 'Warm-up',
      description: 'Keep your streak for 3 days.',
      status: BadgeStatus.locked,
      requiredValue: 3,
    ),
    BadgeModel(
      id: 'streak_7',
      title: 'Week Warrior',
      description: '7 days of consistency.',
      status: BadgeStatus.locked,
      requiredValue: 7,
    ),
    BadgeModel(
      id: 'streak_14',
      title: 'Habit Builder',
      description: '14 days strong — habits forming.',
      status: BadgeStatus.locked,
      requiredValue: 14,
    ),
    BadgeModel(
      id: 'streak_30',
      title: 'Month Master',
      description: '30 days — you\'re rewriting your story.',
      status: BadgeStatus.locked,
      requiredValue: 30,
    ),

    // Tasks completed badges (missions + challenges)
    BadgeModel(
      id: 'tasks_5',
      title: 'Getting Started',
      description: 'Complete 5 tasks.',
      status: BadgeStatus.locked,
      requiredValue: 5,
    ),
    BadgeModel(
      id: 'tasks_20',
      title: 'Momentum',
      description: 'Complete 20 tasks.',
      status: BadgeStatus.locked,
      requiredValue: 20,
    ),
    BadgeModel(
      id: 'tasks_50',
      title: 'Unstoppable',
      description: 'Complete 50 tasks.',
      status: BadgeStatus.locked,
      requiredValue: 50,
    ),

    // Addiction-free days (mapped to streakDays for now)
    BadgeModel(
      id: 'free_3',
      title: '3 Days Clean',
      description: '3 addiction-free days.',
      status: BadgeStatus.locked,
      requiredValue: 3,
    ),
    BadgeModel(
      id: 'free_7',
      title: '1 Week Clean',
      description: '7 addiction-free days.',
      status: BadgeStatus.locked,
      requiredValue: 7,
    ),
    BadgeModel(
      id: 'free_30',
      title: '30 Days Clean',
      description: '30 addiction-free days.',
      status: BadgeStatus.locked,
      requiredValue: 30,
    ),
  ];
}
