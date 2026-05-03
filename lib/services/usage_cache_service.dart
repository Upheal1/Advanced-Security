import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/hive/app_usage_cache.dart';

/// Service for managing offline cache of app usage data
/// Provides local storage fallback when online data unavailable
class UsageCacheService {
  static const String _boxName = 'app_usage_cache';
  static const int _defaultDaysToKeep = 30;

  late Box<List<AppUsageCache>> _cacheBox;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initialize Hive box for cache storage
  Future<void> initialize() async {
    try {
      debugPrint('[UsageCacheService] Initializing...');
      _cacheBox = await Hive.openBox<List<AppUsageCache>>(_boxName);
      _initialized = true;
      debugPrint('[UsageCacheService] Initialized successfully');
    } catch (e) {
      debugPrint('[UsageCacheService] Initialization error: $e');
      rethrow;
    }
  }

  /// Get cache key for a specific date
  String _getCacheKey(DateTime date) {
    return date.toIso8601String().split('T').first; // Format: YYYY-MM-DD
  }

  /// Save usage data for a specific date
  Future<void> saveUsageData(
    List<Map<String, dynamic>> rawData,
    DateTime date,
  ) async {
    try {
      if (!_initialized) {
        debugPrint('[UsageCacheService] Not initialized, skipping save');
        return;
      }

      debugPrint('[UsageCacheService] Saving ${rawData.length} items for $date');

      final cacheItems = rawData
          .map((map) => AppUsageCache.fromMap(map, date))
          .toList();

      final key = _getCacheKey(date);
      await _cacheBox.put(key, cacheItems);

      debugPrint('[UsageCacheService] Saved ${cacheItems.length} items');
    } catch (e) {
      debugPrint('[UsageCacheService] Error saving data: $e');
      // Don't rethrow - cache failure shouldn't break app
    }
  }

  /// Get cached usage data for a specific date
  Future<List<AppUsageCache>> getUsageData(DateTime date) async {
    try {
      if (!_initialized) {
        debugPrint('[UsageCacheService] Not initialized, returning empty list');
        return [];
      }

      final key = _getCacheKey(date);
      final cached = _cacheBox.get(key);

      if (cached == null) {
        debugPrint('[UsageCacheService] No cache found for $date');
        return [];
      }

      debugPrint('[UsageCacheService] Retrieved ${cached.length} items from cache');
      return cached;
    } catch (e) {
      debugPrint('[UsageCacheService] Error retrieving data: $e');
      return [];
    }
  }

  /// Get usage data for a date range
  Future<List<AppUsageCache>> getUsageDataForRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (!_initialized) return [];

      debugPrint(
        '[UsageCacheService] Getting data range from ${_getCacheKey(startDate)} '
        'to ${_getCacheKey(endDate)}',
      );

      final result = <AppUsageCache>[];
      var currentDate = startDate;

      while (!currentDate.isAfter(endDate)) {
        final key = _getCacheKey(currentDate);
        final cached = _cacheBox.get(key);

        if (cached != null) {
          result.addAll(cached);
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }

      debugPrint('[UsageCacheService] Retrieved ${result.length} total items from range');
      return result;
    } catch (e) {
      debugPrint('[UsageCacheService] Error retrieving range: $e');
      return [];
    }
  }

  /// Check if valid cache exists for a date
  Future<bool> hasValidCache(DateTime date) async {
    try {
      if (!_initialized) return false;

      final key = _getCacheKey(date);
      final cached = _cacheBox.get(key);

      if (cached == null || cached.isEmpty) {
        return false;
      }

      // Check if cache is still valid (less than 24 hours old)
      final isValid = cached.every((item) => item.isValid);
      debugPrint('[UsageCacheService] Cache valid for $date: $isValid');

      return isValid;
    } catch (e) {
      debugPrint('[UsageCacheService] Error checking cache: $e');
      return false;
    }
  }

  /// Clear cache older than specified days
  Future<void> clearOldCache({int daysToKeep = _defaultDaysToKeep}) async {
    try {
      if (!_initialized) return;

      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final keysToDelete = <String>[];

      debugPrint(
        '[UsageCacheService] Clearing cache older than '
        '${cutoffDate.toIso8601String().split("T").first}',
      );

      for (final key in _cacheBox.keys) {
        if (key is String) {
          try {
            final keyDate = DateTime.parse(key);
            if (keyDate.isBefore(cutoffDate)) {
              keysToDelete.add(key);
            }
          } catch (e) {
            debugPrint('[UsageCacheService] Error parsing key $key: $e');
          }
        }
      }

      for (final key in keysToDelete) {
        await _cacheBox.delete(key);
      }

      debugPrint('[UsageCacheService] Deleted ${keysToDelete.length} old cache entries');
    } catch (e) {
      debugPrint('[UsageCacheService] Error clearing old cache: $e');
    }
  }

  /// Clear all cached data
  Future<void> clearAll() async {
    try {
      if (!_initialized) return;

      debugPrint('[UsageCacheService] Clearing all cache');
      await _cacheBox.clear();
      debugPrint('[UsageCacheService] All cache cleared');
    } catch (e) {
      debugPrint('[UsageCacheService] Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      if (!_initialized) return {};

      int totalItems = 0;
      int validItems = 0;
      DateTime? oldestDate;
      DateTime? newestDate;

      for (final items in _cacheBox.values) {
        totalItems += items.length;
        validItems += items.where((item) => item.isValid).length;

        for (final item in items) {
          if (oldestDate == null || item.date.isBefore(oldestDate)) {
            oldestDate = item.date;
          }
          if (newestDate == null || item.date.isAfter(newestDate)) {
            newestDate = item.date;
          }
        }
      }

      return {
        'totalItems': totalItems,
        'validItems': validItems,
        'cacheEntries': _cacheBox.length,
        'oldestDate': oldestDate?.toIso8601String(),
        'newestDate': newestDate?.toIso8601String(),
      };
    } catch (e) {
      debugPrint('[UsageCacheService] Error getting stats: $e');
      return {};
    }
  }

  /// Close cache box
  Future<void> close() async {
    try {
      if (_initialized) {
        await _cacheBox.close();
        _initialized = false;
        debugPrint('[UsageCacheService] Closed');
      }
    } catch (e) {
      debugPrint('[UsageCacheService] Error closing: $e');
    }
  }
}
