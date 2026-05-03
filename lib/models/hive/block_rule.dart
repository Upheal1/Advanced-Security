import 'package:hive/hive.dart';

part 'block_rule.g.dart';

/// Hive model for app blocking rules
/// Stores daily limit and blocking settings per app
@HiveType(typeId: 3) // Using typeId 3 (0,1,2 already used)
class BlockRule {
  @HiveField(0)
  final String packageName;

  @HiveField(1)
  final String? appName; // Optional display name

  @HiveField(2)
  final int dailyLimitMinutes; // 0 = no limit, >0 = limit in minutes

  @HiveField(3)
  final bool isBlocked; // True = permanently blocked, false = only limited

  @HiveField(4)
  final bool emergencyAllowed; // Allow emergency 5-min override

  @HiveField(5)
  final DateTime? lastEmergencyDate; // Last time emergency was used

  BlockRule({
    required this.packageName,
    this.appName,
    this.dailyLimitMinutes = 0,
    this.isBlocked = false,
    this.emergencyAllowed = false,
    this.lastEmergencyDate,
  });

  /// Copy with method for updating fields
  BlockRule copyWith({
    String? packageName,
    String? appName,
    int? dailyLimitMinutes,
    bool? isBlocked,
    bool? emergencyAllowed,
    DateTime? lastEmergencyDate,
  }) {
    return BlockRule(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      isBlocked: isBlocked ?? this.isBlocked,
      emergencyAllowed: emergencyAllowed ?? this.emergencyAllowed,
      lastEmergencyDate: lastEmergencyDate ?? this.lastEmergencyDate,
    );
  }

  @override
  String toString() =>
      'BlockRule(package: $packageName, name: $appName, limit: ${dailyLimitMinutes}m, '
      'blocked: $isBlocked, emergency: $emergencyAllowed)';
}

/// Daily usage tracking model
@HiveType(typeId: 4)
class DailyUsage {
  @HiveField(0)
  final String packageName;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final int usedMinutes;

  @HiveField(3)
  final DateTime? emergencyAllowedUntil; // Timestamp when emergency allow expires

  DailyUsage({
    required this.packageName,
    required this.date,
    required this.usedMinutes,
    this.emergencyAllowedUntil,
  });

  /// Create key for Hive box
  String get key => '${_dateKey(date)}:$packageName';

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DailyUsage copyWith({
    int? usedMinutes,
    DateTime? emergencyAllowedUntil,
  }) {
    return DailyUsage(
      packageName: packageName,
      date: date,
      usedMinutes: usedMinutes ?? this.usedMinutes,
      emergencyAllowedUntil: emergencyAllowedUntil ?? this.emergencyAllowedUntil,
    );
  }

  @override
  String toString() =>
      'DailyUsage(package: $packageName, date: ${_dateKey(date)}, used: ${usedMinutes}m)';
}
