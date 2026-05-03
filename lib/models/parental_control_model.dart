import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../models/notification_types.dart';

class ParentalControlModel extends ChangeNotifier {
  // قناة الاتصال مع الكود الأصلي
  static const MethodChannel platform = MethodChannel('com.example.parental_control/native');
  
  bool _isParentalControlEnabled = false;
  bool _isContentFilteringEnabled = false;
  bool _isAppLimitingEnabled = false;
  bool _isAntiRemovalEnabled = false;
  String? _parentPassword;
  List<String> _blockedApps = [];
  List<String> _blockedKeywords = [];
  Map<String, int> _appTimeLimits = {}; // app name -> minutes
  Map<String, int> _appUsageTime = {}; // app name -> minutes used today
  
  // Usage monitoring
  Timer? _usageMonitorTimer;
  final Map<String, bool> _warningsSent = {}; // Track which warnings have been sent
  final Map<String, bool> _limitNotificationsSent = {}; // Track limit reached notifications
  
  // Getters
  bool get isParentalControlEnabled => _isParentalControlEnabled;
  bool get isContentFilteringEnabled => _isContentFilteringEnabled;
  bool get isAppLimitingEnabled => _isAppLimitingEnabled;
  bool get isAntiRemovalEnabled => _isAntiRemovalEnabled;
  List<String> get blockedApps => _blockedApps;
  List<String> get blockedKeywords => _blockedKeywords;
  Map<String, int> get appTimeLimits => _appTimeLimits;
  Map<String, int> get appUsageTime => _appUsageTime;

  ParentalControlModel() {
    _loadParentalSettings();
    _startUsageMonitoring();
    _scheduleDailySummary();
  }

  @override
  void dispose() {
    _usageMonitorTimer?.cancel();
    super.dispose();
  }

  /// Start real-time usage monitoring
  void _startUsageMonitoring() {
    // Check usage every minute
    _usageMonitorTimer?.cancel();
    _usageMonitorTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkUsageLimits();
    });
  }

  /// Check usage limits and trigger notifications
  Future<void> _checkUsageLimits() async {
    if (!_isAppLimitingEnabled) return;

    final settings = await _getNotificationSettings();
    if (!settings.enabled) return;

    for (final entry in _appTimeLimits.entries) {
      final appName = entry.key;
      final limitMinutes = entry.value;
      final usedMinutes = _appUsageTime[appName] ?? 0;

      if (limitMinutes <= 0) continue;

      final percentUsed = (usedMinutes / limitMinutes * 100).round();
      final minutesRemaining = limitMinutes - usedMinutes;

      // Check if limit is reached
      if (usedMinutes >= limitMinutes) {
        if (!(_limitNotificationsSent[appName] ?? false)) {
          await NotificationService.showLimitReachedNotification(
            appName: appName,
          );
          _limitNotificationsSent[appName] = true;
        }
        continue;
      }

      // Check for 5-minute warning
      if (minutesRemaining <= 5 && minutesRemaining > 0) {
        final warningKey = '${appName}_5min';
        if (!(_warningsSent[warningKey] ?? false)) {
          await NotificationService.showFiveMinuteWarning(appName: appName);
          _warningsSent[warningKey] = true;
        }
        continue;
      }

      // Check for percentage-based warnings
      if (percentUsed >= settings.warningThreshold) {
        final warningKey = '${appName}_${settings.warningThreshold}';
        if (!(_warningsSent[warningKey] ?? false)) {
          await NotificationService.scheduleWarningNotification(
            appName: appName,
            minutesRemaining: minutesRemaining,
            percentUsed: percentUsed,
          );
          _warningsSent[warningKey] = true;
        }
      }

      // Additional 90% warning
      if (percentUsed >= 90 && settings.warningThreshold < 90) {
        final warningKey = '${appName}_90';
        if (!(_warningsSent[warningKey] ?? false)) {
          await NotificationService.scheduleWarningNotification(
            appName: appName,
            minutesRemaining: minutesRemaining,
            percentUsed: 90,
          );
          _warningsSent[warningKey] = true;
        }
      }
    }
  }

  /// Schedule daily summary for 8 PM
  Future<void> _scheduleDailySummary() async {
    final settings = await _getNotificationSettings();
    if (!settings.enabled || !settings.summaryEnabled) return;

    await NotificationService.scheduleDailySummary(
      scheduledTime: settings.summaryTime,
      usageData: _appUsageTime,
    );
  }

  /// Get notification settings
  Future<NotificationSettings> _getNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('notification_settings');
      if (settingsJson != null) {
        final json = jsonDecode(settingsJson);
        return NotificationSettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
    return NotificationSettings();
  }

  // تحميل إعدادات الرقابة الأبوية
  Future<void> _loadParentalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isParentalControlEnabled = prefs.getBool('parentalControlEnabled') ?? false;
    _isContentFilteringEnabled = prefs.getBool('contentFilteringEnabled') ?? false;
    _isAppLimitingEnabled = prefs.getBool('appLimitingEnabled') ?? false;
    _isAntiRemovalEnabled = prefs.getBool('antiRemovalEnabled') ?? false;
    _parentPassword = prefs.getString('parentPassword');
    
    // تحميل التطبيقات المحظورة
    final blockedAppsJson = prefs.getString('blockedApps');
    if (blockedAppsJson != null) {
      _blockedApps = blockedAppsJson.split(',');
    }
    
    // تحميل الكلمات المحظورة
    final blockedKeywordsJson = prefs.getString('blockedKeywords');
    if (blockedKeywordsJson != null) {
      _blockedKeywords = blockedKeywordsJson.split(',');
    }
    
    notifyListeners();
  }

  // حفظ إعدادات الرقابة الأبوية
  Future<void> _saveParentalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('parentalControlEnabled', _isParentalControlEnabled);
    await prefs.setBool('contentFilteringEnabled', _isContentFilteringEnabled);
    await prefs.setBool('appLimitingEnabled', _isAppLimitingEnabled);
    await prefs.setBool('antiRemovalEnabled', _isAntiRemovalEnabled);
    await prefs.setString('parentPassword', _parentPassword ?? '');
    await prefs.setString('blockedApps', _blockedApps.join(','));
    await prefs.setString('blockedKeywords', _blockedKeywords.join(','));
  }

  // إعداد كلمة مرور الوالدين
  Future<bool> setParentPassword(String password) async {
    if (password.length < 6) return false;
    
    _parentPassword = password;
    _isParentalControlEnabled = true;
    await _saveParentalSettings();
    notifyListeners();
    return true;
  }

  // التحقق من كلمة مرور الوالدين
  Future<bool> verifyParentPassword(String password) async {
    return _parentPassword == password;
  }

  // تفعيل/إلغاء فلترة المحتوى
  Future<void> toggleContentFiltering() async {
    if (!_isParentalControlEnabled) return;
    
    _isContentFilteringEnabled = !_isContentFilteringEnabled;
    await _saveParentalSettings();
    notifyListeners();
  }

  // تفعيل/إلغاء تحديد التطبيقات
  Future<void> toggleAppLimiting() async {
    if (!_isParentalControlEnabled) return;
    
    _isAppLimitingEnabled = !_isAppLimitingEnabled;
    await _saveParentalSettings();
    notifyListeners();
  }

  // تفعيل/إلغاء الحماية من الإزالة
  Future<void> toggleAntiRemoval() async {
    if (!_isParentalControlEnabled) return;
    
    _isAntiRemovalEnabled = !_isAntiRemovalEnabled;
    await _saveParentalSettings();
    notifyListeners();
  }

  // إضافة تطبيق محظور
  Future<void> addBlockedApp(String appName) async {
    if (!_blockedApps.contains(appName)) {
      _blockedApps.add(appName);
      await _saveParentalSettings();
      notifyListeners();
    }
  }

  // إزالة تطبيق من المحظورات
  Future<void> removeBlockedApp(String appName) async {
    _blockedApps.remove(appName);
    await _saveParentalSettings();
    notifyListeners();
  }

  // إضافة كلمة محظورة
  Future<void> addBlockedKeyword(String keyword) async {
    if (!_blockedKeywords.contains(keyword.toLowerCase())) {
      _blockedKeywords.add(keyword.toLowerCase());
      await _saveParentalSettings();
      notifyListeners();
    }
  }

  // إزالة كلمة من المحظورات
  Future<void> removeBlockedKeyword(String keyword) async {
    _blockedKeywords.remove(keyword.toLowerCase());
    await _saveParentalSettings();
    notifyListeners();
  }

  // تحديد وقت استخدام التطبيق
  Future<void> setAppTimeLimit(String appName, int minutes) async {
    _appTimeLimits[appName] = minutes;
    await _saveParentalSettings();
    notifyListeners();
  }

  // فحص المحتوى للكلمات المحظورة
  bool checkContentForBlockedKeywords(String content) {
    if (!_isContentFilteringEnabled) return false;
    
    final lowerContent = content.toLowerCase();
    for (String keyword in _blockedKeywords) {
      if (lowerContent.contains(keyword)) {
        return true; // محتوى محظور
      }
    }
    return false;
  }

  // فحص ما إذا كان التطبيق محظور
  bool isAppBlocked(String appName) {
    return _blockedApps.contains(appName);
  }

  // فحص ما إذا كان التطبيق تجاوز حد الوقت
  bool isAppTimeLimitExceeded(String appName) {
    if (!_isAppLimitingEnabled) return false;
    
    final timeLimit = _appTimeLimits[appName] ?? 0;
    final usageTime = _appUsageTime[appName] ?? 0;
    
    return usageTime >= timeLimit;
  }

  // تحديث وقت استخدام التطبيق
  Future<void> updateAppUsageTime(String appName, int minutes) async {
    _appUsageTime[appName] = (_appUsageTime[appName] ?? 0) + minutes;
    notifyListeners();
  }

  // إعادة تعيين وقت الاستخدام اليومي
  Future<void> resetDailyUsage() async {
    _appUsageTime.clear();
    _warningsSent.clear();
    _limitNotificationsSent.clear();
    notifyListeners();
    
    // Re-schedule daily summary
    await _scheduleDailySummary();
  }

  // طلب أذونات الحماية من الإزالة
  Future<void> requestAntiRemovalPermission() async {
    try {
      await platform.invokeMethod('requestAntiRemovalPermission');
    } on PlatformException catch (e) {
      debugPrint('Failed to request anti-removal permission: ${e.message}');
    }
  }

  // حظر التطبيق
  Future<void> blockApp(String appName) async {
    try {
      await platform.invokeMethod('blockApp', {'appName': appName});
    } on PlatformException catch (e) {
      debugPrint('Failed to block app: ${e.message}');
    }
  }

  // إلغاء حظر التطبيق
  Future<void> unblockApp(String appName) async {
    try {
      await platform.invokeMethod('unblockApp', {'appName': appName});
    } on PlatformException catch (e) {
      debugPrint('Failed to unblock app: ${e.message}');
    }
  }

  // الحصول على إحصائيات الرقابة الأبوية
  Map<String, dynamic> getParentalStats() {
    return {
      'isEnabled': _isParentalControlEnabled,
      'contentFiltering': _isContentFilteringEnabled,
      'appLimiting': _isAppLimitingEnabled,
      'antiRemoval': _isAntiRemovalEnabled,
      'blockedAppsCount': _blockedApps.length,
      'blockedKeywordsCount': _blockedKeywords.length,
      'appTimeLimitsCount': _appTimeLimits.length,
    };
  }

  // تعطيل الرقابة الأبوية بالكامل
  Future<void> disableParentalControl() async {
    _isParentalControlEnabled = false;
    _isContentFilteringEnabled = false;
    _isAppLimitingEnabled = false;
    _isAntiRemovalEnabled = false;
    _parentPassword = null;
    _blockedApps.clear();
    _blockedKeywords.clear();
    _appTimeLimits.clear();
    _appUsageTime.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
