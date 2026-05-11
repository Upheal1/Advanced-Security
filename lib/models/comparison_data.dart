/// Models for usage comparison and trend analysis

/// Trend direction indicator
enum TrendDirection {
  up,      // Usage increased (bad)
  down,    // Usage decreased (good)
  stable,  // No significant change
}

extension TrendDirectionExtension on TrendDirection {
  bool get isImprovement => this == TrendDirection.down;
  bool get isRegression => this == TrendDirection.up;
  bool get isStable => this == TrendDirection.stable;
  
  String get label {
    switch (this) {
      case TrendDirection.up:
        return 'Increased';
      case TrendDirection.down:
        return 'Decreased';
      case TrendDirection.stable:
        return 'Stable';
    }
  }
  
  String get emoji {
    switch (this) {
      case TrendDirection.up:
        return '📈';
      case TrendDirection.down:
        return '📉';
      case TrendDirection.stable:
        return '➡️';
    }
  }
}

/// Comparison period type
enum ComparisonType {
  weekVsWeek,
  monthVsMonth,
}

extension ComparisonTypeExtension on ComparisonType {
  String get label {
    switch (this) {
      case ComparisonType.weekVsWeek:
        return 'Week vs Week';
      case ComparisonType.monthVsMonth:
        return 'Month vs Month';
    }
  }
  
  String get currentLabel {
    switch (this) {
      case ComparisonType.weekVsWeek:
        return 'This Week';
      case ComparisonType.monthVsMonth:
        return 'This Month';
    }
  }
  
  String get previousLabel {
    switch (this) {
      case ComparisonType.weekVsWeek:
        return 'Last Week';
      case ComparisonType.monthVsMonth:
        return 'Last Month';
    }
  }
}

/// Daily usage data point for charts
class DailyUsagePoint {
  final DateTime date;
  final int usageSeconds;
  final String dayLabel;
  
  const DailyUsagePoint({
    required this.date,
    required this.usageSeconds,
    required this.dayLabel,
  });
  
  double get usageHours => usageSeconds / 3600;
  double get usageMinutes => usageSeconds / 60;
  
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'usageSeconds': usageSeconds,
    'dayLabel': dayLabel,
  };
  
  factory DailyUsagePoint.fromJson(Map<String, dynamic> json) {
    return DailyUsagePoint(
      date: DateTime.parse(json['date']),
      usageSeconds: json['usageSeconds'] as int,
      dayLabel: json['dayLabel'] as String,
    );
  }
}

/// Comparison data for a period
class ComparisonPeriod {
  final DateTime startDate;
  final DateTime endDate;
  final int totalUsageSeconds;
  final List<DailyUsagePoint> dailyUsage;
  final Map<String, int> appUsage; // packageName -> seconds
  
  const ComparisonPeriod({
    required this.startDate,
    required this.endDate,
    required this.totalUsageSeconds,
    required this.dailyUsage,
    required this.appUsage,
  });
  
  /// Total usage in hours
  double get totalHours => totalUsageSeconds / 3600;
  
  /// Total usage in minutes
  double get totalMinutes => totalUsageSeconds / 60;
  
  /// Number of days in period
  int get days => endDate.difference(startDate).inDays + 1;
  
  /// Daily average in seconds
  double get dailyAverageSeconds => days > 0 ? totalUsageSeconds / days : 0;
  
  /// Daily average in hours
  double get dailyAverageHours => dailyAverageSeconds / 3600;
  
  /// Daily average in minutes
  double get dailyAverageMinutes => dailyAverageSeconds / 60;
  
  /// Get formatted date range
  String get dateRangeLabel {
    final startStr = '${startDate.month}/${startDate.day}';
    final endStr = '${endDate.month}/${endDate.day}';
    return '$startStr - $endStr';
  }
  
  Map<String, dynamic> toJson() => {
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'totalUsageSeconds': totalUsageSeconds,
    'dailyUsage': dailyUsage.map((d) => d.toJson()).toList(),
    'appUsage': appUsage,
  };
  
  factory ComparisonPeriod.fromJson(Map<String, dynamic> json) {
    return ComparisonPeriod(
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      totalUsageSeconds: json['totalUsageSeconds'] as int,
      dailyUsage: (json['dailyUsage'] as List)
          .map((d) => DailyUsagePoint.fromJson(d))
          .toList(),
      appUsage: Map<String, int>.from(json['appUsage']),
    );
  }
  
  factory ComparisonPeriod.empty() {
    return ComparisonPeriod(
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      totalUsageSeconds: 0,
      dailyUsage: [],
      appUsage: {},
    );
  }
}

/// App-level comparison data
class AppComparison {
  final String packageName;
  final String appName;
  final int currentUsageSeconds;
  final int previousUsageSeconds;
  
  const AppComparison({
    required this.packageName,
    required this.appName,
    required this.currentUsageSeconds,
    required this.previousUsageSeconds,
  });
  
  /// Difference in seconds (positive = increased usage)
  int get differenceSeconds => currentUsageSeconds - previousUsageSeconds;
  
  /// Difference in minutes
  double get differenceMinutes => differenceSeconds / 60;
  
  /// Difference in hours
  double get differenceHours => differenceSeconds / 3600;
  
  /// Percentage change (-100 to +infinity)
  double get changePercent {
    if (previousUsageSeconds == 0) {
      return currentUsageSeconds > 0 ? 100.0 : 0.0;
    }
    return ((currentUsageSeconds - previousUsageSeconds) / previousUsageSeconds) * 100;
  }
  
  /// Absolute percentage change
  double get absoluteChangePercent => changePercent.abs();
  
  /// Trend direction based on change
  TrendDirection get trend {
    if (changePercent > 5) return TrendDirection.up;
    if (changePercent < -5) return TrendDirection.down;
    return TrendDirection.stable;
  }
  
  /// Whether this is an improvement (reduced usage)
  bool get isImprovement => differenceSeconds < 0;
  
  /// Whether this is a regression (increased usage)
  bool get isRegression => differenceSeconds > 0;
  
  /// Current usage formatted
  String get currentUsageFormatted => _formatDuration(currentUsageSeconds);
  
  /// Previous usage formatted
  String get previousUsageFormatted => _formatDuration(previousUsageSeconds);
  
  /// Difference formatted with sign
  String get differenceFormatted {
    final formatted = _formatDuration(differenceSeconds.abs());
    return differenceSeconds >= 0 ? '+$formatted' : '-$formatted';
  }
  
  static String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).round()}m';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }
  
  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appName': appName,
    'currentUsageSeconds': currentUsageSeconds,
    'previousUsageSeconds': previousUsageSeconds,
  };
  
  factory AppComparison.fromJson(Map<String, dynamic> json) {
    return AppComparison(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      currentUsageSeconds: json['currentUsageSeconds'] as int,
      previousUsageSeconds: json['previousUsageSeconds'] as int,
    );
  }
}

/// Complete comparison result
class ComparisonResult {
  final ComparisonType type;
  final ComparisonPeriod current;
  final ComparisonPeriod previous;
  final List<AppComparison> appComparisons;
  
  const ComparisonResult({
    required this.type,
    required this.current,
    required this.previous,
    required this.appComparisons,
  });
  
  /// Total usage difference in seconds
  int get totalDifferenceSeconds => 
      current.totalUsageSeconds - previous.totalUsageSeconds;
  
  /// Total usage difference in hours
  double get totalDifferenceHours => totalDifferenceSeconds / 3600;
  
  /// Total usage change percentage
  double get totalChangePercent {
    if (previous.totalUsageSeconds == 0) {
      return current.totalUsageSeconds > 0 ? 100.0 : 0.0;
    }
    return (totalDifferenceSeconds / previous.totalUsageSeconds) * 100;
  }
  
  /// Daily average difference in seconds
  double get dailyAverageDifferenceSeconds =>
      current.dailyAverageSeconds - previous.dailyAverageSeconds;
  
  /// Daily average difference in minutes
  double get dailyAverageDifferenceMinutes =>
      dailyAverageDifferenceSeconds / 60;
  
  /// Daily average change percentage
  double get dailyAverageChangePercent {
    if (previous.dailyAverageSeconds == 0) {
      return current.dailyAverageSeconds > 0 ? 100.0 : 0.0;
    }
    return (dailyAverageDifferenceSeconds / previous.dailyAverageSeconds) * 100;
  }
  
  /// Overall trend direction
  TrendDirection get overallTrend {
    if (totalChangePercent > 5) return TrendDirection.up;
    if (totalChangePercent < -5) return TrendDirection.down;
    return TrendDirection.stable;
  }
  
  /// Apps that improved (reduced usage), sorted by improvement
  List<AppComparison> get improvedApps {
    return appComparisons
        .where((app) => app.isImprovement)
        .toList()
      ..sort((a, b) => a.differenceSeconds.compareTo(b.differenceSeconds));
  }
  
  /// Apps that regressed (increased usage), sorted by regression
  List<AppComparison> get regressedApps {
    return appComparisons
        .where((app) => app.isRegression)
        .toList()
      ..sort((a, b) => b.differenceSeconds.compareTo(a.differenceSeconds));
  }
  
  /// Apps with no significant change
  List<AppComparison> get stableApps {
    return appComparisons
        .where((app) => app.trend == TrendDirection.stable)
        .toList();
  }
  
  /// Top N most improved apps
  List<AppComparison> topImproved([int n = 3]) {
    return improvedApps.take(n).toList();
  }
  
  /// Top N most regressed apps
  List<AppComparison> topRegressed([int n = 3]) {
    return regressedApps.take(n).toList();
  }
  
  /// Get insight message based on overall trend
  String get insightMessage {
    final changeAbs = totalChangePercent.abs().round();
    if (overallTrend == TrendDirection.down) {
      return '🎉 Great job! You reduced screen time by $changeAbs%';
    } else if (overallTrend == TrendDirection.up) {
      return '📱 Screen time increased by $changeAbs%. Consider setting limits.';
    } else {
      return '👍 Screen time is stable. Keep up the good habits!';
    }
  }
  
  factory ComparisonResult.empty(ComparisonType type) {
    return ComparisonResult(
      type: type,
      current: ComparisonPeriod.empty(),
      previous: ComparisonPeriod.empty(),
      appComparisons: [],
    );
  }
}
