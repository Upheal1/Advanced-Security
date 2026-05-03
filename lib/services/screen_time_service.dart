import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:usage_stats/usage_stats.dart';
import '../models/screen_time_model.dart';
import 'usage_cache_service.dart';

/// Cache entry for period-specific data with TTL validation
class _CacheEntry {
  final List<Map<String, dynamic>> data;
  final DateTime timestamp;
  
  _CacheEntry({required this.data, required this.timestamp});
  
  bool isValid(Duration cacheDuration) => DateTime.now().difference(timestamp) < cacheDuration;
}

class ScreenTimeService {
  static const MethodChannel _channel = MethodChannel('screen_time_service');
  static ScreenTimeModel? _screenTimeModel;
  static Timer? _usageTimer;
  static UsageCacheService? _cacheService;
  static bool _usingCachedData = false;

  // Cache configuration
  static const Duration CACHE_DURATION = Duration(minutes: 5);
  
  // Period-specific caches
  static final Map<String, _CacheEntry> _periodCaches = {};

  /// Get whether currently showing cached data
  static bool get isUsingCachedData => _usingCachedData;

  /// Set cache service (called from main.dart)
  static void setCacheService(UsageCacheService cacheService) {
    _cacheService = cacheService;
    debugPrint('[ScreenTimeService] Cache service set');
  }
  static Future<void> initialize(ScreenTimeModel screenTimeModel) async {
    _screenTimeModel = screenTimeModel;
    
    // Set up method call handler
    _channel.setMethodCallHandler(_handleMethodCall);
    
    // Start periodic usage tracking
    _startUsageTracking();
  }

  // Handle method calls from native code
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onAppUsageChanged':
        final String packageName = call.arguments['packageName'];
        final String appName = call.arguments['appName'];
        final int usageTimeMinutes = call.arguments['usageTimeMinutes'];
        final String category = call.arguments['category'] ?? 'Unknown';
        
        if (_screenTimeModel != null) {
          // Invalidate cache when usage changes
          _invalidateCache();
          
          await _screenTimeModel!.addAppUsage(
            packageName,
            appName,
            Duration(minutes: usageTimeMinutes),
            category,
          );
        }
        break;
        
      case 'onContentBlocked':
        final String content = call.arguments['content'];
        final String reason = call.arguments['reason'];
        _showContentBlockedNotification(content, reason);
        break;
        
      case 'onAppBlocked':
        final String appName = call.arguments['appName'];
        _showAppBlockedNotification(appName);
        break;
    }
  }

  // Start periodic usage tracking
  static void _startUsageTracking() {
    _usageTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _trackCurrentAppUsage();
    });
  }

  // Track current app usage using usage_stats
  static Future<void> _trackCurrentAppUsage() async {
    try {
      bool hasPermission = await checkUsageStatsPermission();
      if (!hasPermission) return;

      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(hours: 1));
      
      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);
      
      if (_screenTimeModel != null) {
        for (var info in usageStats) {
          final packageName = info.packageName ?? 'unknown';
          final appName = _getAppName(packageName);
          final usageTimeMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
          final category = _getAppCategory(packageName);
          
          if (usageTimeMs > 0 && !_screenTimeModel!.isAppBlocked(packageName)) {
            await _screenTimeModel!.addAppUsage(
              packageName,
              appName,
              Duration(milliseconds: usageTimeMs),
              category,
            );
          }
        }
      }
    } catch (e) {
      print('Error tracking app usage: $e');
    }
  }

  // Get real usage statistics from Android using usage_stats (with cache fallback)
  static Future<List<Map<String, dynamic>>> getRealUsageStats() async {
    try {
      debugPrint('[ScreenTimeService] getRealUsageStats called');
      _usingCachedData = false;

      bool hasPermission = await checkUsageStatsPermission();
      if (!hasPermission) {
        debugPrint('[ScreenTimeService] No permission, trying cache');
        return await _getFromCache(DateTime.now());
      }

      DateTime endDate = DateTime.now();
      // Explicitly set to midnight (00:00:00) to ensure we start counting from the beginning of the day
      DateTime startDate = DateTime(endDate.year, endDate.month, endDate.day, 0, 0, 0);
      
      // Invalidate cache if we've crossed into a new day
      final today = DateTime(endDate.year, endDate.month, endDate.day);
      final cacheKey = 'accurate_today';
      if (_periodCaches.containsKey(cacheKey)) {
        final cached = _periodCaches[cacheKey]!;
        // Check if cache is from a different day
        if (cached.timestamp.year != today.year || 
            cached.timestamp.month != today.month || 
            cached.timestamp.day != today.day) {
          debugPrint('[ScreenTimeService] New day detected, invalidating cache');
          _periodCaches.remove(cacheKey);
        }
      }
      
      debugPrint('[ScreenTimeService] Querying usage from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
      
      // Get today's cumulative usage
      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);
      
      // Get yesterday's end-of-day baseline to subtract (Android returns cumulative totals)
      DateTime yesterdayEnd = startDate.subtract(const Duration(seconds: 1));
      DateTime yesterdayStart = DateTime(yesterdayEnd.year, yesterdayEnd.month, yesterdayEnd.day, 0, 0, 0);
      List<UsageInfo> yesterdayStats = await UsageStats.queryUsageStats(yesterdayStart, yesterdayEnd);
      
      // Build a map of yesterday's totals for each app
      Map<String, int> yesterdayTotals = {};
      for (var info in yesterdayStats) {
        final packageName = info.packageName ?? 'unknown';
        final yesterdayTimeMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
        if (yesterdayTimeMs > 0) {
          yesterdayTotals[packageName] = yesterdayTimeMs;
        }
      }
      
      debugPrint('[ScreenTimeService] Yesterday baseline: ${yesterdayTotals.length} apps');
      
      Map<String, Map<String, dynamic>> appMap = {};
      for (var info in usageStats) {
        final packageName = info.packageName ?? 'unknown';
        final appName = _getAppName(packageName);
        final cumulativeTimeMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
        
        // Subtract yesterday's baseline to get today's actual usage
        final yesterdayBaseline = yesterdayTotals[packageName] ?? 0;
        final todayUsageMs = cumulativeTimeMs - yesterdayBaseline;
        
        // Debug log for apps with significant usage
        if (cumulativeTimeMs > 60000) {
          debugPrint('[ScreenTimeService] $appName: cumulative=$cumulativeTimeMs ms, yesterday=$yesterdayBaseline ms, today=$todayUsageMs ms');
        }
        
        // Only count if usage is positive and significant
        if (todayUsageMs > 10000 && !_isSystemApp(packageName, appName)) {
          final category = _getAppCategory(packageName);
          
          if (appMap.containsKey(packageName)) {
            final existing = appMap[packageName]!;
            final existingTime = existing['usageTime'] as int;
            appMap[packageName] = {
              'packageName': packageName,
              'appName': appName,
              'usageTime': existingTime + todayUsageMs,
              'category': category,
              'lastTimeUsed': info.lastTimeUsed,
            };
          } else {
            appMap[packageName] = {
              'packageName': packageName,
              'appName': appName,
              'usageTime': todayUsageMs,
              'category': category,
              'lastTimeUsed': info.lastTimeUsed,
            };
          }
        }
      }
      
      List<Map<String, dynamic>> result = appMap.values.toList();
      result.sort((a, b) => (b['usageTime'] as int).compareTo(a['usageTime'] as int));
      
      // Save to cache in background (use today's date, not startDate to ensure proper day tracking)
      if (_cacheService != null) {
        final today = DateTime(endDate.year, endDate.month, endDate.day);
        _cacheService!.saveUsageData(result, today).catchError((e) {
          debugPrint('[ScreenTimeService] Error caching data: $e');
        });
        debugPrint('[ScreenTimeService] Cached ${result.length} items for today');
      }

      _usingCachedData = false;
      return result;
    } catch (e) {
      debugPrint('[ScreenTimeService] Error getting real usage stats: $e, trying cache');
      return await _getFromCache(DateTime.now());
    }
  }

  /// Get data from cache
  static Future<List<Map<String, dynamic>>> _getFromCache(DateTime date) async {
    try {
      if (_cacheService == null) {
        debugPrint('[ScreenTimeService] No cache service available');
        return [];
      }

      // Ensure we're only getting cache for today (not yesterday)
      final today = DateTime(date.year, date.month, date.day);
      final cached = await _cacheService!.getUsageData(today);
      
      if (cached.isEmpty) {
        debugPrint('[ScreenTimeService] No cached data for $today');
        return [];
      }

      // Verify cache is from today (not stale)
      final cacheDate = cached.first.date;
      final cacheDay = DateTime(cacheDate.year, cacheDate.month, cacheDate.day);
      if (!cacheDay.isAtSameMomentAs(today)) {
        debugPrint('[ScreenTimeService] Cache is from a different day, clearing');
        await _cacheService!.clearAll();
        return [];
      }

      _usingCachedData = true;
      debugPrint('[ScreenTimeService] Returning ${cached.length} cached items from today');

      // Convert to map format
      return cached
          .map((item) => {
                'appName': item.appName,
                'packageName': item.packageName,
                'usageTime': item.totalTimeMs,
                'date': item.date.toIso8601String(),
              })
          .toList();
    } catch (e) {
      debugPrint('[ScreenTimeService] Error getting cached data: $e');
      return [];
    }
  }

  // Get accurate usage stats with caching by period
  static Future<List<Map<String, dynamic>>> getAccurateUsageStats(
      {String period = 'today'}) async {
    try {
      // Check cache first
      final cacheKey = 'accurate_$period';
      if (_periodCaches.containsKey(cacheKey)) {
        final cached = _periodCaches[cacheKey]!;
        if (cached.isValid(CACHE_DURATION)) {
          return cached.data;
        }
      }

      bool hasPermission = await checkUsageStatsPermission();
      if (!hasPermission) return [];

      final now = DateTime.now();
      List<UsageInfo> bestStats;
      
      switch (period) {
        case 'yesterday':
          final yesterdayStart = DateTime(now.year, now.month, now.day - 1);
          final todayStart = DateTime(now.year, now.month, now.day);
          bestStats = await UsageStats.queryUsageStats(yesterdayStart, todayStart);
          break;
        case 'weekly':
          final today = DateTime.now();
          final daysSinceMonday = today.weekday - 1;
          final weekStart = DateTime(today.year, today.month, today.day - daysSinceMonday);
          bestStats = await UsageStats.queryUsageStats(weekStart, now);
          break;
        case 'monthly':
          final monthAgo = now.subtract(const Duration(days: 30));
          bestStats = await UsageStats.queryUsageStats(monthAgo, now);
          break;
        case '3months':
          final threeMonthsAgo = now.subtract(const Duration(days: 90));
          bestStats = await UsageStats.queryUsageStats(threeMonthsAgo, now);
          break;
        case '6months':
          final sixMonthsAgo = now.subtract(const Duration(days: 180));
          bestStats = await UsageStats.queryUsageStats(sixMonthsAgo, now);
          break;
        case '1year':
          final yearAgo = now.subtract(const Duration(days: 365));
          bestStats = await UsageStats.queryUsageStats(yearAgo, now);
          break;
        default:
          final todayStart = DateTime(now.year, now.month, now.day);
          bestStats = await UsageStats.queryUsageStats(todayStart, now);
          break;
      }
      
      Map<String, Map<String, dynamic>> appMap = {};
      
      for (var info in bestStats) {
        final packageName = info.packageName ?? 'unknown';
        final appName = _getAppName(packageName);
        final usageTimeMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
        final category = _getAppCategory(packageName);
        
        if (usageTimeMs > 60000 && !_isSystemApp(packageName, appName)) {
          if (appMap.containsKey(packageName)) {
            final existing = appMap[packageName]!;
            final existingTime = existing['usageTime'] as int;
            appMap[packageName] = {
              'packageName': packageName,
              'appName': appName,
              'usageTime': existingTime + usageTimeMs,
              'category': category,
              'lastTimeUsed': info.lastTimeUsed,
            };
          } else {
            appMap[packageName] = {
              'packageName': packageName,
              'appName': appName,
              'usageTime': usageTimeMs,
              'category': category,
              'lastTimeUsed': info.lastTimeUsed,
            };
          }
        }
      }
      
      List<Map<String, dynamic>> result = appMap.values.toList();
      result.sort((a, b) => (b['usageTime'] as int).compareTo(a['usageTime'] as int));
      
      // Cache the result
      _periodCaches[cacheKey] = _CacheEntry(data: result, timestamp: DateTime.now());
      
      return result;
    } catch (e) {
      print('Error getting accurate usage stats: $e');
      return [];
    }
  }

  // Get ultra-accurate usage stats with very strict filtering
  // Get ultra-accurate usage stats with caching
  static Future<List<Map<String, dynamic>>> getUltraAccurateUsageStats(
      {String period = 'today'}) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Check cache first, but invalidate if it's from a different day
      final cacheKey = 'ultra_$period';
      if (_periodCaches.containsKey(cacheKey)) {
        final cached = _periodCaches[cacheKey]!;
        // Check if cache is from today and still valid
        final cacheDay = DateTime(cached.timestamp.year, cached.timestamp.month, cached.timestamp.day);
        if (cacheDay.isAtSameMomentAs(today) && cached.isValid(CACHE_DURATION)) {
          return cached.data;
        } else {
          // Cache is from a different day, remove it
          debugPrint('[ScreenTimeService] getUltraAccurate: Invalidating stale cache from different day');
          _periodCaches.remove(cacheKey);
        }
      }

      bool hasPermission = await checkUsageStatsPermission();
      if (!hasPermission) return [];
      List<UsageInfo> bestStats;
      
      switch (period) {
        case 'yesterday':
          final yesterdayStart = DateTime(now.year, now.month, now.day - 1);
          final todayStart = DateTime(now.year, now.month, now.day);
          bestStats = await UsageStats.queryUsageStats(yesterdayStart, todayStart);
          break;
        case 'weekly':
          final today = DateTime.now();
          final daysSinceMonday = today.weekday - 1;
          final weekStart = DateTime(today.year, today.month, today.day - daysSinceMonday);
          bestStats = await UsageStats.queryUsageStats(weekStart, now);
          break;
        case 'monthly':
          final monthAgo = now.subtract(const Duration(days: 30));
          bestStats = await UsageStats.queryUsageStats(monthAgo, now);
          break;
        case '3months':
          final threeMonthsAgo = now.subtract(const Duration(days: 90));
          bestStats = await UsageStats.queryUsageStats(threeMonthsAgo, now);
          break;
        case '6months':
          final sixMonthsAgo = now.subtract(const Duration(days: 180));
          bestStats = await UsageStats.queryUsageStats(sixMonthsAgo, now);
          break;
        case '1year':
          final yearAgo = now.subtract(const Duration(days: 365));
          bestStats = await UsageStats.queryUsageStats(yearAgo, now);
          break;
        default:
          final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
          bestStats = await UsageStats.queryUsageStats(todayStart, now);
          break;
      }
      
      // For 'today' period, subtract yesterday's baseline (Android returns cumulative totals)
      Map<String, int> yesterdayTotals = {};
      if (period == 'today' || period.isEmpty) {
        final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
        DateTime yesterdayEnd = todayStart.subtract(const Duration(seconds: 1));
        DateTime yesterdayStart = DateTime(yesterdayEnd.year, yesterdayEnd.month, yesterdayEnd.day, 0, 0, 0);
        List<UsageInfo> yesterdayStats = await UsageStats.queryUsageStats(yesterdayStart, yesterdayEnd);
        
        for (var info in yesterdayStats) {
          final packageName = info.packageName ?? 'unknown';
          final yesterdayTimeMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
          if (yesterdayTimeMs > 0) {
            yesterdayTotals[packageName] = yesterdayTimeMs;
          }
        }
        debugPrint('[ScreenTimeService] getUltraAccurate: Yesterday baseline: ${yesterdayTotals.length} apps');
      }
      
      Map<String, Map<String, dynamic>> appMap = {};
      
      for (var info in bestStats) {
        final packageName = info.packageName ?? 'unknown';
        final appName = _getAppName(packageName);
        final cumulativeTimeMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
        
        // For 'today' period, subtract yesterday's baseline
        int usageTimeMs = cumulativeTimeMs;
        if ((period == 'today' || period.isEmpty) && yesterdayTotals.isNotEmpty) {
          final yesterdayBaseline = yesterdayTotals[packageName] ?? 0;
          usageTimeMs = cumulativeTimeMs - yesterdayBaseline;
          
          if (cumulativeTimeMs > 60000) {
            debugPrint('[ScreenTimeService] getUltraAccurate: $appName: cumulative=$cumulativeTimeMs ms, yesterday=$yesterdayBaseline ms, today=$usageTimeMs ms');
          }
        }
        
        final category = _getAppCategory(packageName);
        
        // Only count if usage is positive and significant
        if (usageTimeMs > 60000 && !_isSystemApp(packageName, appName)) {
          if (appMap.containsKey(packageName)) {
            final existing = appMap[packageName]!;
            final existingTime = existing['usageTime'] as int;
            appMap[packageName] = {
              'packageName': packageName,
              'appName': appName,
              'usageTime': existingTime + usageTimeMs,
              'category': category,
              'lastTimeUsed': info.lastTimeUsed,
            };
          } else {
            appMap[packageName] = {
              'packageName': packageName,
              'appName': appName,
              'usageTime': usageTimeMs,
              'category': category,
              'lastTimeUsed': info.lastTimeUsed,
            };
          }
        }
      }
      
      List<Map<String, dynamic>> result = appMap.values.toList();
      result.sort((a, b) => (b['usageTime'] as int).compareTo(a['usageTime'] as int));
      
      // Cache the result
      _periodCaches[cacheKey] = _CacheEntry(data: result, timestamp: DateTime.now());
      
      return result;
    } catch (e) {
      print('Error getting ultra accurate usage stats: $e');
      return [];
    }
  }

  // Note: _isSuspiciousApp was used for filtering suspicious apps but is now
  // handled by _isSystemApp method. Kept as comment for reference.

  // Get better weekly data with caching
  static Future<List<Map<String, dynamic>>> getBetterWeeklyUsage() async {
    return getAccurateUsageStats(period: 'weekly');
  }

  // Get daily usage for trend with caching
  static Future<List<Map<String, dynamic>>> getDailyUsageForTrend() async {
    try {
      // Check cache
      const cacheKey = 'daily_trend';
      if (_periodCaches.containsKey(cacheKey)) {
        final cached = _periodCaches[cacheKey]!;
        if (cached.isValid(CACHE_DURATION)) {
          return cached.data;
        }
      }

      bool hasPermission = await checkUsageStatsPermission();
      if (!hasPermission) return [];

      final today = DateTime.now();
      List<Map<String, dynamic>> dailyData = [];
      
      for (int i = 6; i >= 0; i--) {
        final dayStart = DateTime(today.year, today.month, today.day - i);
        final dayEnd = DateTime(today.year, today.month, today.day - i + 1);
        
        List<UsageInfo> dayStats = await UsageStats.queryUsageStats(dayStart, dayEnd);
        
        int dayTotalTime = 0;
        Map<String, int> appTimes = {};
        
        for (var info in dayStats) {
          final packageName = info.packageName ?? 'unknown';
          final appName = _getAppName(packageName);
          final usageTimeMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
          
          if (usageTimeMs > 60000 && !_isSystemApp(packageName, appName)) {
            dayTotalTime += usageTimeMs;
            
            if (appTimes.containsKey(packageName)) {
              appTimes[packageName] = appTimes[packageName]! + usageTimeMs;
            } else {
              appTimes[packageName] = usageTimeMs;
            }
          }
        }
        
        final dayHours = dayTotalTime / (1000 * 60 * 60);
        dailyData.add({
          'day': 7 - i,
          'date': dayStart,
          'totalHours': dayHours,
          'totalMinutes': dayTotalTime / (1000 * 60),
          'appCount': appTimes.length,
          'topApp': appTimes.isNotEmpty 
              ? _getAppName(appTimes.entries.reduce((a, b) => a.value > b.value ? a : b).key) 
              : 'None',
        });
      }
      
      // Cache the result
      _periodCaches[cacheKey] = _CacheEntry(data: dailyData, timestamp: DateTime.now());
      
      return dailyData;
    } catch (e) {
      print('Error getting daily usage trend: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getDailyUsageForPreviousWeek() async {
    try {
      // Check cache
      const cacheKey = 'daily_trend_previous_week';
      if (_periodCaches.containsKey(cacheKey)) {
        final cached = _periodCaches[cacheKey]!;
        if (cached.isValid(CACHE_DURATION)) {
          return cached.data;
        }
      }

      bool hasPermission = await checkUsageStatsPermission();
      if (!hasPermission) return [];

      final today = DateTime.now();
      List<Map<String, dynamic>> dailyData = [];
      
      // Fetch data from 8-14 days ago (previous week)
      for (int i = 13; i >= 7; i--) {
        final dayStart = DateTime(today.year, today.month, today.day - i);
        final dayEnd = DateTime(today.year, today.month, today.day - i + 1);
        
        List<UsageInfo> dayStats = await UsageStats.queryUsageStats(dayStart, dayEnd);
        
        int dayTotalTime = 0;
        Map<String, int> appTimes = {};
        
        for (var info in dayStats) {
          final packageName = info.packageName ?? 'unknown';
          final appName = _getAppName(packageName);
          final usageTimeMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
          
          if (usageTimeMs > 60000 && !_isSystemApp(packageName, appName)) {
            dayTotalTime += usageTimeMs;
            
            if (appTimes.containsKey(packageName)) {
              appTimes[packageName] = appTimes[packageName]! + usageTimeMs;
            } else {
              appTimes[packageName] = usageTimeMs;
            }
          }
        }
        
        final dayHours = dayTotalTime / (1000 * 60 * 60);
        dailyData.add({
          'day': 13 - i,
          'date': dayStart,
          'totalHours': dayHours,
          'totalMinutes': dayTotalTime / (1000 * 60),
          'appCount': appTimes.length,
          'topApp': appTimes.isNotEmpty 
              ? _getAppName(appTimes.entries.reduce((a, b) => a.value > b.value ? a : b).key) 
              : 'None',
        });
      }
      
      // Cache the result
      _periodCaches[cacheKey] = _CacheEntry(data: dailyData, timestamp: DateTime.now());
      
      return dailyData;
    } catch (e) {
      print('Error getting previous week daily usage: $e');
      return [];
    }
  }

  // Request usage stats permission
  static Future<bool> requestUsageStatsPermission() async {
    try {
      // Use the working parental control channel to open settings
      await _channel.invokeMethod('requestUsageStatsPermission');
      return true;
    } catch (e) {
      print('Error requesting usage stats permission: $e');
      return true; // Still return true to show the dialog
    }
  }

  // Check if usage stats permission is granted
  static Future<bool> checkUsageStatsPermission() async {
    try {
      bool? hasPermission = await UsageStats.checkUsagePermission();
      return hasPermission ?? false;
    } catch (e) {
      print('Error checking usage stats permission: $e');
      return false;
    }
  }

  // Get app usage statistics for a specific period
  static Future<Map<String, dynamic>?> getUsageStats({Duration? period}) async {
    try {
      bool hasPermission = await checkUsageStatsPermission();
      if (!hasPermission) {
        return null;
      }

      DateTime endDate = DateTime.now();
      DateTime startDate = period != null 
          ? endDate.subtract(period)
          : DateTime(endDate.year, endDate.month, endDate.day);

      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);
      
      int totalScreenTime = 0;
      Map<String, int> appUsage = {};
      Map<String, int> categoryUsage = {};
      
      for (var info in usageStats) {
        final packageName = info.packageName ?? 'unknown';
        final appName = _getAppName(packageName);
        final usageTime = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
        final category = _getAppCategory(packageName);
        
        if (usageTime > 0) {
          totalScreenTime += usageTime;
          
          appUsage[appName] = (appUsage[appName] ?? 0) + usageTime;
          categoryUsage[category] = (categoryUsage[category] ?? 0) + usageTime;
        }
      }
      
      return {
        'totalScreenTime': totalScreenTime,
        'appUsage': appUsage,
        'categoryUsage': categoryUsage,
        'period': period?.inDays ?? 1,
      };
    } catch (e) {
      print('Error getting usage stats: $e');
      return null;
    }
  }

  // Helper method to get app name from package name
  static String _getAppName(String packageName) {
    if (packageName == 'unknown') return 'Unknown App';
    
    // Map of known package names to proper app names
    final appNameMap = {
      'com.zhiliaoapp.musically': 'TikTok',
      'com.ss.android.ugc.aweme': 'TikTok',
      'com.instagram.android': 'Instagram',
      'com.facebook.katana': 'Facebook',
      'com.twitter.android': 'Twitter',
      'com.snapchat.android': 'Snapchat',
      'com.whatsapp': 'WhatsApp',
      'com.telegram.messenger': 'Telegram',
      'com.discord': 'Discord',
      'com.google.android.youtube': 'YouTube',
      'com.netflix.mediaclient': 'Netflix',
      'com.amazon.avod.thirdpartyclient': 'Prime Video',
      'com.google.android.apps.photos': 'Google Photos',
      'com.google.android.gm': 'Gmail',
      'com.google.android.apps.docs': 'Google Docs',
      'com.microsoft.office.excel': 'Excel',
      'com.microsoft.office.word': 'Word',
      'com.microsoft.office.powerpoint': 'PowerPoint',
      'com.google.android.apps.maps': 'Google Maps',
      'com.ubercab': 'Uber',
      'com.ubercab.eats': 'Uber Eats',
      'com.doordash.consumer': 'DoorDash',
      'com.grubhub.android': 'Grubhub',
      'com.airbnb.android': 'Airbnb',
      'com.booking': 'Booking.com',
      'com.google.android.apps.translate': 'Google Translate',
      'com.google.android.apps.calendar': 'Google Calendar',
      'com.google.android.apps.drive': 'Google Drive',
      'com.google.android.apps.meetings': 'Google Meet',
      'com.zoom.us': 'Zoom',
      'com.skype.raider': 'Skype',
      'com.microsoft.teams': 'Microsoft Teams',
      'com.slack': 'Slack',
      'com.trello': 'Trello',
      'com.notion.id': 'Notion',
      'com.evernote': 'Evernote',
      'com.google.android.apps.keep': 'Google Keep',
      'com.google.android.apps.tachyon': 'Google Duo',
      'com.google.android.apps.messaging': 'Messages',
      'com.android.chrome': 'Chrome',
      'com.mozilla.firefox': 'Firefox',
      'com.opera.browser': 'Opera',
      'com.microsoft.emmx': 'Edge',
      'com.samsung.android.browser': 'Samsung Internet',
      'com.google.android.apps.books': 'Google Play Books',
      'com.amazon.kindle': 'Kindle',
      'com.audible.application': 'Audible',
      'com.google.android.apps.podcasts': 'Google Podcasts',
      'com.spotify.music': 'Spotify',
      'com.soundcloud.android': 'SoundCloud',
      'com.pandora.android': 'Pandora',
      'com.iheartradio.android': 'iHeartRadio',
      'com.google.android.apps.fitness': 'Google Fit',
      'com.myfitnesspal.android': 'MyFitnessPal',
      'com.strava': 'Strava',
      'com.nike.ntc': 'Nike Training Club',
      'com.adobe.reader': 'Adobe Acrobat Reader',
      'com.adobe.photoshop.express': 'Adobe Photoshop Express',
      'com.canva.editor': 'Canva',
      'com.pinterest': 'Pinterest',
      'com.reddit.frontpage': 'Reddit',
      'com.linkedin.android': 'LinkedIn',
      'com.github.android': 'GitHub',
      'com.stackexchange.marvin': 'Stack Overflow',
      'com.medium.reader': 'Medium',
      'com.quora.android': 'Quora',
      'com.tumblr': 'Tumblr',
      'com.flickr.android': 'Flickr',
      'com.vsco.cam': 'VSCO',
      'com.adobe.lightroom': 'Lightroom',
      'com.snapseed': 'Snapseed',
      'com.instagram.layout': 'Layout',
      'com.boomerang': 'Boomerang',
      'com.hyperlapse': 'Hyperlapse',
    };
    
    // Check if we have a known mapping
    if (appNameMap.containsKey(packageName)) {
      return appNameMap[packageName]!;
    }
    
    // Extract app name from package name as fallback
    List<String> parts = packageName.split('.');
    if (parts.isNotEmpty) {
      String lastPart = parts.last;
      // Capitalize first letter
      return lastPart[0].toUpperCase() + lastPart.substring(1);
    }
    return packageName;
  }

  // Helper method to check if an app is a system app or launcher
  static bool _isSystemApp(String packageName, String appName) {
    // Filter out system launchers
    if (packageName.contains('launcher') || 
        appName.toLowerCase().contains('launcher') ||
        packageName.contains('home')) {
      return true;
    }
    
    // Filter out system apps
    if (packageName.startsWith('com.android.') ||
        packageName.startsWith('com.google.android.') ||
        packageName.startsWith('android.') ||
        packageName.contains('system') ||
        packageName.contains('settings') ||
        packageName.contains('keyboard') ||
        packageName.contains('inputmethod') ||
        packageName.contains('wallpaper') ||
        packageName.contains('livewallpaper')) {
      return true;
    }
    
    // Filter out specific system packages
    final systemPackages = [
      'com.android.systemui',
      'com.android.launcher',
      'com.android.launcher3',
      'com.google.android.launcher',
      'com.samsung.android.launcher',
      'com.miui.home',
      'com.huawei.android.launcher',
      'com.oneplus.launcher',
      'com.oppo.launcher',
      'com.vivo.launcher',
      'com.android.incallui', // Phone call interface - this is what you asked about!
      'com.android.phone', // Phone app
      'com.android.contacts', // Contacts app
      'com.android.dialer', // Dialer app
      'com.android.settings', // Settings app
      'com.android.calendar', // Calendar app
      'com.android.calculator2', // Calculator app
      'com.android.deskclock', // Clock app
      'com.android.gallery3d', // Gallery app
      'com.android.music', // Music app
      'com.android.camera2', // Camera app
      'com.android.camera', // Camera app
      'com.android.gallery', // Gallery app
      'com.android.mms', // Messages app
      'com.android.email', // Email app
      'com.android.browser', // Browser app
      'com.android.chrome', // Chrome browser
      'com.google.android.apps.maps', // Google Maps
      'com.google.android.apps.photos', // Google Photos
      'com.google.android.gm', // Gmail
      'com.google.android.apps.docs', // Google Docs
      'com.google.android.apps.drive', // Google Drive
      'com.google.android.apps.calendar', // Google Calendar
      'com.google.android.apps.keep', // Google Keep
      'com.google.android.apps.translate', // Google Translate
      'com.google.android.apps.meetings', // Google Meet
      'com.google.android.apps.tachyon', // Google Duo
      'com.google.android.apps.messaging', // Google Messages
      'com.google.android.apps.books', // Google Books
      'com.google.android.apps.podcasts', // Google Podcasts
      'com.google.android.apps.fitness', // Google Fit
      'com.tencent.mm', // WeChat (often considered system-like in some regions)
      'com.tencent.mobileqq', // QQ (often considered system-like in some regions)
    ];
    
    return systemPackages.contains(packageName);
  }

  // Helper method to categorize apps
  static String _getAppCategory(String packageName) {
    // Social media apps
    if (packageName.contains('facebook') || 
        packageName.contains('twitter') || 
        packageName.contains('instagram') || 
        packageName.contains('snapchat') || 
        packageName.contains('tiktok') ||
        packageName.contains('whatsapp') ||
        packageName.contains('telegram')) {
      return 'Social';
    }
    
    // Entertainment apps
    if (packageName.contains('youtube') || 
        packageName.contains('netflix') || 
        packageName.contains('spotify') || 
        packageName.contains('twitch') ||
        packageName.contains('discord') ||
        packageName.contains('reddit')) {
      return 'Entertainment';
    }
    
    // Productivity apps
    if (packageName.contains('gmail') || 
        packageName.contains('outlook') || 
        packageName.contains('office') || 
        packageName.contains('google') ||
        packageName.contains('microsoft') ||
        packageName.contains('slack') ||
        packageName.contains('zoom')) {
      return 'Productivity';
    }
    
    // Games
    if (packageName.contains('game') || 
        packageName.contains('play') || 
        packageName.contains('unity')) {
      return 'Games';
    }
    
    // Default category
    return 'Other';
  }

  // Block an app
  static Future<bool> blockApp(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod('blockApp', {
        'packageName': packageName,
      });
      
      if (result && _screenTimeModel != null) {
        await _screenTimeModel!.blockApp(packageName);
      }
      
      return result;
    } catch (e) {
      print('Error blocking app: $e');
      return false;
    }
  }

  // Unblock an app
  static Future<bool> unblockApp(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod('unblockApp', {
        'packageName': packageName,
      });
      
      if (result && _screenTimeModel != null) {
        await _screenTimeModel!.unblockApp(packageName);
      }
      
      return result;
    } catch (e) {
      print('Error unblocking app: $e');
      return false;
    }
  }

  // Check if content should be blocked
  static Future<bool> checkContentFilter(String content) async {
    try {
      final bool result = await _channel.invokeMethod('checkContentFilter', {
        'content': content,
      });
      
      return result;
    } catch (e) {
      print('Error checking content filter: $e');
      return false;
    }
  }

  // Add NSFW keyword
  static Future<bool> addNsfwKeyword(String keyword) async {
    try {
      final bool result = await _channel.invokeMethod('addNsfwKeyword', {
        'keyword': keyword,
      });
      
      if (result && _screenTimeModel != null) {
        await _screenTimeModel!.addNsfwKeyword(keyword);
      }
      
      return result;
    } catch (e) {
      print('Error adding NSFW keyword: $e');
      return false;
    }
  }

  // Remove NSFW keyword
  static Future<bool> removeNsfwKeyword(String keyword) async {
    try {
      final bool result = await _channel.invokeMethod('removeNsfwKeyword', {
        'keyword': keyword,
      });
      
      if (result && _screenTimeModel != null) {
        await _screenTimeModel!.removeNsfwKeyword(keyword);
      }
      
      return result;
    } catch (e) {
      print('Error removing NSFW keyword: $e');
      return false;
    }
  }

  // Enable anti-removal protection
  static Future<bool> enableAntiRemoval() async {
    try {
      final bool result = await _channel.invokeMethod('enableAntiRemoval');
      return result;
    } catch (e) {
      print('Error enabling anti-removal: $e');
      return false;
    }
  }

  // Disable anti-removal protection
  static Future<bool> disableAntiRemoval() async {
    try {
      final bool result = await _channel.invokeMethod('disableAntiRemoval');
      return result;
    } catch (e) {
      print('Error disabling anti-removal: $e');
      return false;
    }
  }

  // Show content blocked notification
  static void _showContentBlockedNotification(String content, String reason) {
    print('Content blocked: $content - Reason: $reason');
  }

  // Show app blocked notification
  static void _showAppBlockedNotification(String appName) {
    print('App blocked: $appName');
  }

  // Invalidate all caches
  static void _invalidateCache() {
    _periodCaches.clear();
  }

  /// Public: Invalidate all cached period data to force refresh
  static void invalidateCaches() {
    _periodCaches.clear();
    _usingCachedData = false;
    debugPrint('[ScreenTimeService] Caches invalidated');
  }

  // Note: _invalidatePeriodCache can be used for selective cache invalidation
  // if needed in the future. For now, _invalidateCache() clears all caches.
  // static void _invalidatePeriodCache(String period) {
  //   _periodCaches.remove('accurate_$period');
  //   _periodCaches.remove('ultra_$period');
  //   if (period == 'weekly') {
  //     _periodCaches.remove('daily_trend');
  //   }
  // }

  // Cleanup
  static void dispose() {
    _usageTimer?.cancel();
    _usageTimer = null;
    _invalidateCache();
  }
}