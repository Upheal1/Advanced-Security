import 'package:flutter/foundation.dart';
import 'package:usage_stats/usage_stats.dart';
import '../models/comparison_data.dart';
import 'screen_time_service.dart';

/// Service for calculating and fetching usage comparisons
class ComparisonService {
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  /// Get week vs week comparison
  static Future<ComparisonResult> getWeekComparison() async {
    try {
      final now = DateTime.now();
      
      // Current week (start from Monday)
      final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
      final currentWeekEnd = now;
      
      // Previous week
      final previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));
      final previousWeekEnd = currentWeekStart.subtract(const Duration(days: 1));
      
      // Fetch data for both periods
      final currentPeriod = await _fetchPeriodData(
        currentWeekStart,
        currentWeekEnd,
        ComparisonType.weekVsWeek,
      );
      
      final previousPeriod = await _fetchPeriodData(
        previousWeekStart,
        previousWeekEnd,
        ComparisonType.weekVsWeek,
      );
      
      // Calculate app comparisons
      final appComparisons = calculateAppComparisons(
        currentPeriod.appUsage,
        previousPeriod.appUsage,
      );
      
      return ComparisonResult(
        type: ComparisonType.weekVsWeek,
        current: currentPeriod,
        previous: previousPeriod,
        appComparisons: appComparisons,
      );
    } catch (e) {
      debugPrint('[ComparisonService] Error getting week comparison: $e');
      return ComparisonResult.empty(ComparisonType.weekVsWeek);
    }
  }
  
  /// Get month vs month comparison
  static Future<ComparisonResult> getMonthComparison() async {
    try {
      final now = DateTime.now();
      
      // Current month
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = now;
      
      // Previous month
      final previousMonthEnd = currentMonthStart.subtract(const Duration(days: 1));
      final previousMonthStart = DateTime(previousMonthEnd.year, previousMonthEnd.month, 1);
      
      // Fetch data for both periods
      final currentPeriod = await _fetchPeriodData(
        currentMonthStart,
        currentMonthEnd,
        ComparisonType.monthVsMonth,
      );
      
      final previousPeriod = await _fetchPeriodData(
        previousMonthStart,
        previousMonthEnd,
        ComparisonType.monthVsMonth,
      );
      
      // Calculate app comparisons
      final appComparisons = calculateAppComparisons(
        currentPeriod.appUsage,
        previousPeriod.appUsage,
      );
      
      return ComparisonResult(
        type: ComparisonType.monthVsMonth,
        current: currentPeriod,
        previous: previousPeriod,
        appComparisons: appComparisons,
      );
    } catch (e) {
      debugPrint('[ComparisonService] Error getting month comparison: $e');
      return ComparisonResult.empty(ComparisonType.monthVsMonth);
    }
  }
  
  /// Fetch period data using direct usage_stats queries
  static Future<ComparisonPeriod> _fetchPeriodData(
    DateTime startDate,
    DateTime endDate,
    ComparisonType type,
  ) async {
    try {
      // Check permission first
      final hasPermission = await ScreenTimeService.checkUsageStatsPermission();
      if (!hasPermission) {
        return ComparisonPeriod(
          startDate: startDate,
          endDate: endDate,
          totalUsageSeconds: 0,
          dailyUsage: [],
          appUsage: {},
        );
      }

      // Get daily usage for the period
      final dailyUsage = <DailyUsagePoint>[];
      final appUsage = <String, int>{};
      int totalSeconds = 0;
      
      // Iterate through each day in the period
      DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day);
      final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);
      
      while (!currentDate.isAfter(endDateTime)) {
        // Get usage for this specific day using direct usage_stats query
        final startOfDay = DateTime(currentDate.year, currentDate.month, currentDate.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        try {
          final usageStats = await UsageStats.queryUsageStats(startOfDay, endOfDay);
          
          int dayTotalSeconds = 0;
          final dayAppUsage = <String, int>{};
          
          for (final info in usageStats) {
            final packageName = info.packageName ?? 'unknown';
            final usageMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
            final usageSec = usageMs ~/ 1000;
            
            // Filter out system apps and minimal usage
            if (usageSec > 0 && !_isSystemApp(packageName)) {
              dayTotalSeconds += usageSec;
              dayAppUsage[packageName] = (dayAppUsage[packageName] ?? 0) + usageSec;
            }
          }
          
          // Add to daily points
          final dayLabel = type == ComparisonType.weekVsWeek
              ? _dayNames[currentDate.weekday - 1]
              : '${currentDate.month}/${currentDate.day}';
          
          dailyUsage.add(DailyUsagePoint(
            date: currentDate,
            usageSeconds: dayTotalSeconds,
            dayLabel: dayLabel,
          ));
          
          totalSeconds += dayTotalSeconds;
          
          // Aggregate app usage
          for (final entry in dayAppUsage.entries) {
            appUsage[entry.key] = (appUsage[entry.key] ?? 0) + entry.value;
          }
        } catch (e) {
          debugPrint('[ComparisonService] Error fetching day ${currentDate.toIso8601String()}: $e');
        }
        
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      return ComparisonPeriod(
        startDate: startDate,
        endDate: endDate,
        totalUsageSeconds: totalSeconds,
        dailyUsage: dailyUsage,
        appUsage: appUsage,
      );
    } catch (e) {
      debugPrint('[ComparisonService] Error fetching period data: $e');
      return ComparisonPeriod(
        startDate: startDate,
        endDate: endDate,
        totalUsageSeconds: 0,
        dailyUsage: [],
        appUsage: {},
      );
    }
  }
  
  /// Check if package is a system app
  static bool _isSystemApp(String packageName) {
    final systemPrefixes = [
      'com.android.',
      'com.google.android.inputmethod',
      'com.samsung.android.app.cocktailbarservice',
      'com.samsung.android.app.routines',
      'com.sec.android',
      'android.',
    ];
    
    final systemApps = [
      'com.android.systemui',
      'com.android.launcher',
      'com.android.settings',
      'com.android.vending', // Play Store is ok
    ];
    
    // Allow Play Store
    if (packageName == 'com.android.vending') return false;
    
    for (final prefix in systemPrefixes) {
      if (packageName.startsWith(prefix)) return true;
    }
    
    return systemApps.contains(packageName);
  }
  
  /// Calculate app-level comparisons between two periods
  static List<AppComparison> calculateAppComparisons(
    Map<String, int> currentAppUsage,
    Map<String, int> previousAppUsage,
  ) {
    // Get all unique package names
    final allApps = <String>{
      ...currentAppUsage.keys,
      ...previousAppUsage.keys,
    };
    
    final comparisons = <AppComparison>[];
    
    for (final packageName in allApps) {
      final currentSeconds = currentAppUsage[packageName] ?? 0;
      final previousSeconds = previousAppUsage[packageName] ?? 0;
      
      // Only include apps with meaningful usage
      if (currentSeconds > 60 || previousSeconds > 60) {
        comparisons.add(AppComparison(
          packageName: packageName,
          appName: _getAppName(packageName),
          currentUsageSeconds: currentSeconds,
          previousUsageSeconds: previousSeconds,
        ));
      }
    }
    
    // Sort by absolute change (biggest changes first)
    comparisons.sort((a, b) => 
        b.differenceSeconds.abs().compareTo(a.differenceSeconds.abs()));
    
    return comparisons;
  }
  
  /// Get trend direction from change percentage
  static TrendDirection getTrendDirection(double changePercent) {
    if (changePercent > 5) return TrendDirection.up;
    if (changePercent < -5) return TrendDirection.down;
    return TrendDirection.stable;
  }
  
  /// Get human-readable app name from package name
  static String _getAppName(String packageName) {
    // Try to extract a readable name from the package
    final parts = packageName.split('.');
    if (parts.isNotEmpty) {
      // Common app name mappings
      final nameMap = {
        'instagram': 'Instagram',
        'facebook': 'Facebook',
        'messenger': 'Messenger',
        'whatsapp': 'WhatsApp',
        'twitter': 'X (Twitter)',
        'youtube': 'YouTube',
        'tiktok': 'TikTok',
        'snapchat': 'Snapchat',
        'spotify': 'Spotify',
        'netflix': 'Netflix',
        'chrome': 'Chrome',
        'gmail': 'Gmail',
        'maps': 'Maps',
        'photos': 'Photos',
        'camera': 'Camera',
        'calculator': 'Calculator',
        'calendar': 'Calendar',
        'clock': 'Clock',
        'settings': 'Settings',
        'launcher': 'Launcher',
        'dialer': 'Phone',
        'contacts': 'Contacts',
        'messages': 'Messages',
        'reddit': 'Reddit',
        'discord': 'Discord',
        'telegram': 'Telegram',
        'pinterest': 'Pinterest',
        'linkedin': 'LinkedIn',
        'amazon': 'Amazon',
        'uber': 'Uber',
        'lyft': 'Lyft',
      };
      
      // Check each part of the package name
      for (final part in parts.reversed) {
        final lower = part.toLowerCase();
        if (nameMap.containsKey(lower)) {
          return nameMap[lower]!;
        }
      }
      
      // Fall back to last meaningful part
      final lastPart = parts.last;
      if (lastPart.length > 2) {
        // Capitalize first letter
        return lastPart[0].toUpperCase() + lastPart.substring(1);
      }
    }
    
    return packageName;
  }
  
  /// Get comparison for a specific app
  static Future<AppComparison?> getAppComparison(
    String packageName,
    ComparisonType type,
  ) async {
    try {
      final result = type == ComparisonType.weekVsWeek
          ? await getWeekComparison()
          : await getMonthComparison();
      
      return result.appComparisons.firstWhere(
        (app) => app.packageName == packageName,
        orElse: () => AppComparison(
          packageName: packageName,
          appName: _getAppName(packageName),
          currentUsageSeconds: 0,
          previousUsageSeconds: 0,
        ),
      );
    } catch (e) {
      debugPrint('[ComparisonService] Error getting app comparison: $e');
      return null;
    }
  }
}
