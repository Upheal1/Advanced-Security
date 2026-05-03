import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/hive/block_rule.dart';

/// Service for managing app blocking rules and daily usage tracking
/// Uses Hive for local persistence
class AppBlockingService {
  static const String _rulesBoxName = 'block_rules';
  static const String _usageBoxName = 'daily_usage';

  static Box<BlockRule>? _rulesBox;
  static Box<DailyUsage>? _usageBox;
  static bool _initialized = false;

  /// Initialize Hive boxes for rules and usage
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (!Hive.isBoxOpen(_rulesBoxName)) {
        _rulesBox = await Hive.openBox<BlockRule>(_rulesBoxName);
      } else {
        _rulesBox = Hive.box<BlockRule>(_rulesBoxName);
      }

      if (!Hive.isBoxOpen(_usageBoxName)) {
        _usageBox = await Hive.openBox<DailyUsage>(_usageBoxName);
      } else {
        _usageBox = Hive.box<DailyUsage>(_usageBoxName);
      }

      _initialized = true;
      debugPrint('[AppBlockingService] Initialized successfully');
    } catch (e) {
      debugPrint('[AppBlockingService] Initialization error: $e');
      rethrow;
    }
  }

  /// Get blocking rule for a specific app
  static BlockRule? getRule(String packageName) {
    _ensureInitialized();
    return _rulesBox!.get(packageName);
  }

  /// Get all blocking rules
  static List<BlockRule> getAllRules() {
    _ensureInitialized();
    return _rulesBox!.values.toList();
  }

  /// Get list of packages that are explicitly blocked
  static List<String> getBlockedPackages() {
    _ensureInitialized();
    try {
      return _rulesBox!.values
          .where((rule) => rule.isBlocked)
          .map((rule) => rule.packageName)
          .toList();
    } catch (e) {
      debugPrint('Error getting blocked packages: $e');
      return [];
    }
  }

  /// Set or update a blocking rule
  static Future<void> setRule(BlockRule rule) async {
    _ensureInitialized();
    await _rulesBox!.put(rule.packageName, rule);
    debugPrint('[AppBlockingService] Rule saved: $rule');
  }

  /// Remove a blocking rule
  static Future<void> removeRule(String packageName) async {
    _ensureInitialized();
    await _rulesBox!.delete(packageName);
    debugPrint('[AppBlockingService] Rule removed for: $packageName');
  }

  /// Get today's usage for a specific app
  static int getUsageToday(String packageName) {
    _ensureInitialized();
    final today = DateTime.now();
    final key = _usageKey(today, packageName);
    final usage = _usageBox!.get(key);
    return usage?.usedMinutes ?? 0;
  }

  /// Add usage time for today (incremental)
  static Future<void> addUsageToday(String packageName, int minutesDelta) async {
    _ensureInitialized();
    final today = DateTime.now();
    final key = _usageKey(today, packageName);

    final existing = _usageBox!.get(key);
    final newUsage = DailyUsage(
      packageName: packageName,
      date: _todayDate(today),
      usedMinutes: (existing?.usedMinutes ?? 0) + minutesDelta,
      emergencyAllowedUntil: existing?.emergencyAllowedUntil,
    );

    await _usageBox!.put(key, newUsage);
    debugPrint('[AppBlockingService] Usage updated: $packageName += ${minutesDelta}m (total: ${newUsage.usedMinutes}m)');
  }

  /// Get remaining minutes today (limit - used), returns null if no limit
  static int? getRemainingToday(String packageName) {
    final rule = getRule(packageName);
    if (rule == null || rule.dailyLimitMinutes == 0) return null;

    final used = getUsageToday(packageName);
    final remaining = rule.dailyLimitMinutes - used;
    return remaining > 0 ? remaining : 0;
  }

  /// Check if app is currently in emergency allow window
  static bool isInEmergencyAllow(String packageName) {
    _ensureInitialized();
    final today = DateTime.now();
    final key = _usageKey(today, packageName);
    final usage = _usageBox!.get(key);

    if (usage?.emergencyAllowedUntil == null) return false;
    return DateTime.now().isBefore(usage!.emergencyAllowedUntil!);
  }

  /// Check if emergency allow can be used today (once per day limit)
  static bool canUseEmergencyAllow(String packageName) {
    final rule = getRule(packageName);
    if (rule == null || !rule.emergencyAllowed) return false;

    final today = DateTime.now();
    final todayDate = _todayDate(today);

    // Check if already used today
    if (rule.lastEmergencyDate != null) {
      final lastDate = _todayDate(rule.lastEmergencyDate!);
      if (lastDate == todayDate) {
        return false; // Already used today
      }
    }

    return true;
  }

  /// Grant emergency allow for 5 minutes
  static Future<void> grantEmergencyAllow(String packageName) async {
    _ensureInitialized();
    final rule = getRule(packageName);
    if (rule == null || !rule.emergencyAllowed) {
      throw Exception('Emergency allow not enabled for this app');
    }

    if (!canUseEmergencyAllow(packageName)) {
      throw Exception('Emergency allow already used today');
    }

    final now = DateTime.now();
    final today = _todayDate(now);
    final key = _usageKey(now, packageName);

    // Set emergency allow expiration (5 minutes from now)
    final allowUntil = now.add(const Duration(minutes: 5));

    final existing = _usageBox!.get(key);
    final newUsage = DailyUsage(
      packageName: packageName,
      date: today,
      usedMinutes: existing?.usedMinutes ?? 0,
      emergencyAllowedUntil: allowUntil,
    );

    await _usageBox!.put(key, newUsage);

    // Update rule to mark today as used
    await setRule(rule.copyWith(lastEmergencyDate: now));

    debugPrint('[AppBlockingService] Emergency allow granted until $allowUntil');
  }

  /// Check if app should be blocked right now
  /// Returns: {isBlocked: bool, reason: String?, remainingMinutes: int?}
  static Map<String, dynamic> evaluateBlock(String packageName) {
    // #region agent log
    debugPrint('DEBUG_H5: AppBlockingService.evaluateBlock called for: $packageName');
    // #endregion
    final rule = getRule(packageName);
    // #region agent log
    debugPrint('DEBUG_H5: AppBlockingService rule for $packageName: $rule');
    // #endregion

    // No rule = not blocked
    if (rule == null) {
      return {'isBlocked': false, 'reason': null, 'remainingMinutes': null};
    }

    // Check emergency allow window
    if (isInEmergencyAllow(packageName)) {
      return {'isBlocked': false, 'reason': 'emergency_allowed', 'remainingMinutes': null};
    }

    // Permanently blocked
    if (rule.isBlocked) {
      return {
        'isBlocked': true,
        'reason': 'blocked_by_user',
        'remainingMinutes': _minutesUntilEndOfDay(),
      };
    }

    // Check daily limit
    if (rule.dailyLimitMinutes > 0) {
      final used = getUsageToday(packageName);
      if (used >= rule.dailyLimitMinutes) {
        final remaining = _minutesUntilEndOfDay();
        return {
          'isBlocked': true,
          'reason': 'daily_limit_reached',
          'remainingMinutes': remaining,
        };
      }
    }

    // Not blocked
    return {'isBlocked': false, 'reason': null, 'remainingMinutes': null};
  }

  /// Clear old usage data (keep last 30 days)
  static Future<void> clearOldUsage({int daysToKeep = 30}) async {
    _ensureInitialized();
    final cutoff = DateTime.now().subtract(Duration(days: daysToKeep));
    final keysToDelete = <String>[];

    for (final key in _usageBox!.keys) {
      try {
        final parts = key.toString().split(':');
        if (parts.isEmpty) continue;
        final dateStr = parts[0];
        final date = DateTime.parse(dateStr);
        if (date.isBefore(cutoff)) {
          keysToDelete.add(key.toString());
        }
      } catch (e) {
        // Invalid key format, skip
      }
    }

    for (final key in keysToDelete) {
      await _usageBox!.delete(key);
    }

    debugPrint('[AppBlockingService] Cleared ${keysToDelete.length} old usage entries');
  }

  // Helper methods

  static void _ensureInitialized() {
    if (!_initialized || _rulesBox == null || _usageBox == null) {
      throw Exception('AppBlockingService not initialized. Call initialize() first.');
    }
  }

  static String _usageKey(DateTime date, String packageName) {
    final dateStr = _dateKey(date);
    return '$dateStr:$packageName';
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime _todayDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _minutesUntilEndOfDay() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final diff = endOfDay.difference(now);
    return diff.inMinutes;
  }
}