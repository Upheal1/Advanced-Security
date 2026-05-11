import 'package:hive/hive.dart';

part 'app_usage_cache.g.dart';

/// Hive model for caching app usage data
/// This allows offline-first access to screen time data
@HiveType(typeId: 0)
class AppUsageCache {
  @HiveField(0)
  final String appName;

  @HiveField(1)
  final String packageName;

  @HiveField(2)
  final int totalTimeMs; // Duration in milliseconds

  @HiveField(3)
  final DateTime date; // Date of the usage data

  @HiveField(4)
  final DateTime lastUpdated; // When this record was cached

  AppUsageCache({
    required this.appName,
    required this.packageName,
    required this.totalTimeMs,
    required this.date,
    required this.lastUpdated,
  });

  /// Create cache from raw usage map
  factory AppUsageCache.fromMap(Map<String, dynamic> map, DateTime date) {
    return AppUsageCache(
      appName: map['appName'] as String? ?? 'Unknown',
      packageName: map['packageName'] as String? ?? 'unknown',
      totalTimeMs: map['usageTime'] as int? ?? 0,
      date: date,
      lastUpdated: DateTime.now(),
    );
  }

  /// Convert to map for display
  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'packageName': packageName,
      'usageTime': totalTimeMs,
      'date': date.toIso8601String(),
    };
  }

  /// Check if cache is still valid (less than 24 hours old)
  bool get isValid {
    final age = DateTime.now().difference(lastUpdated);
    return age.inHours < 24;
  }

  /// Get formatted duration string
  String get formattedDuration {
    final hours = totalTimeMs ~/ (1000 * 60 * 60);
    final minutes = (totalTimeMs ~/ (1000 * 60)) % 60;
    final seconds = (totalTimeMs ~/ 1000) % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  String toString() =>
      'AppUsageCache(appName: $appName, packageName: $packageName, '
      'totalTimeMs: $totalTimeMs, date: ${date.toIso8601String()})';
}
