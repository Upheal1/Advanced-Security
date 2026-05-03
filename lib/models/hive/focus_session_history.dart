import 'package:hive/hive.dart';

part 'focus_session_history.g.dart';

/// Types of focus sessions
@HiveType(typeId: 1)
enum FocusSessionType {
  @HiveField(0)
  focus,

  @HiveField(1)
  shortBreak,

  @HiveField(2)
  longBreak,
}

/// Hive model for storing completed focus sessions
@HiveType(typeId: 2)
class FocusSessionHistory {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final FocusSessionType type;

  @HiveField(2)
  final int durationSeconds;

  @HiveField(3)
  final DateTime startTime;

  @HiveField(4)
  final DateTime endTime;

  @HiveField(5)
  final bool completed;

  @HiveField(6)
  final List<String> blockedApps;

  @HiveField(7)
  final int sessionNumber; // Which session in the pomodoro cycle

  FocusSessionHistory({
    required this.id,
    required this.type,
    required this.durationSeconds,
    required this.startTime,
    required this.endTime,
    required this.completed,
    required this.blockedApps,
    required this.sessionNumber,
  });

  /// Create from current session data
  factory FocusSessionHistory.create({
    required FocusSessionType type,
    required int durationSeconds,
    required DateTime startTime,
    required bool completed,
    required List<String> blockedApps,
    required int sessionNumber,
  }) {
    return FocusSessionHistory(
      id: '${startTime.millisecondsSinceEpoch}_${type.name}',
      type: type,
      durationSeconds: durationSeconds,
      startTime: startTime,
      endTime: DateTime.now(),
      completed: completed,
      blockedApps: blockedApps,
      sessionNumber: sessionNumber,
    );
  }

  /// Get duration as Duration object
  Duration get duration => Duration(seconds: durationSeconds);

  /// Get formatted duration string
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  /// Get session type display name
  String get typeDisplayName {
    switch (type) {
      case FocusSessionType.focus:
        return 'Focus';
      case FocusSessionType.shortBreak:
        return 'Short Break';
      case FocusSessionType.longBreak:
        return 'Long Break';
    }
  }

  /// Get date only (for grouping by day)
  DateTime get dateOnly => DateTime(startTime.year, startTime.month, startTime.day);

  /// Check if session is from today
  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  /// Convert to map for export/display
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'durationSeconds': durationSeconds,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'completed': completed,
      'blockedApps': blockedApps,
      'sessionNumber': sessionNumber,
    };
  }
}

/// Extension to get default duration for session types
extension FocusSessionTypeExtension on FocusSessionType {
  Duration get defaultDuration {
    switch (this) {
      case FocusSessionType.focus:
        return const Duration(minutes: 25);
      case FocusSessionType.shortBreak:
        return const Duration(minutes: 5);
      case FocusSessionType.longBreak:
        return const Duration(minutes: 15);
    }
  }

  String get displayName {
    switch (this) {
      case FocusSessionType.focus:
        return 'Focus';
      case FocusSessionType.shortBreak:
        return 'Short Break';
      case FocusSessionType.longBreak:
        return 'Long Break';
    }
  }

  String get description {
    switch (this) {
      case FocusSessionType.focus:
        return '25 minutes of focused work';
      case FocusSessionType.shortBreak:
        return '5 minute rest';
      case FocusSessionType.longBreak:
        return '15 minute rest';
    }
  }
}
