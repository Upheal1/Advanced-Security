import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_types.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification channel IDs for usage limits
  static const String _usageWarningChannelId = 'usage_warnings';
  static const String _usageLimitChannelId = 'usage_limits';
  static const String _dailySummaryChannelId = 'daily_summary';
  static const String _achievementChannelId = 'achievements';

  // Notification IDs
  static const int _warningBaseId = 5000;
  static const int _limitBaseId = 6000;
  static const int _summaryId = 7000;
  static const int _achievementBaseId = 8000;

  // Callback for handling notification taps
  static Function(NotificationPayload)? onNotificationTap;

  static Future<void> initialize() async {
    // Initialize timezone database (for scheduled notifications)
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );
    await _requestPermissions();
    await _createNotificationChannels();
  }

  /// Handle notification response (tap)
  static void _onNotificationResponse(NotificationResponse response) {
    if (response.payload == null) return;

    try {
      final json = jsonDecode(response.payload!);
      final payload = NotificationPayload.fromJson(json);
      onNotificationTap?.call(payload);
      debugPrint('Notification tapped: ${payload.type}');
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }

  /// Handle background notification response
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    debugPrint('Background notification response: ${response.payload}');
  }

  static Future<void> _createNotificationChannels() async {
    // Create notification channels
    const blockedAppsChannel = AndroidNotificationChannel(
      'blocked_apps',
      'Blocked Apps',
      description: 'Notifications when blocked apps are accessed',
      importance: Importance.high,
    );

    const focusStartChannel = AndroidNotificationChannel(
      'focus_channel',
      'Focus Mode',
      description: 'Notifications for focus mode start',
      importance: Importance.high,
    );

    const focusCompleteChannel = AndroidNotificationChannel(
      'focus_complete',
      'Focus Complete',
      description: 'Focus completion notifications',
      importance: Importance.high,
    );

    const streakChannel = AndroidNotificationChannel(
      'streak_channel',
      'Focus Streaks',
      description: 'Focus streak notifications',
      importance: Importance.defaultImportance,
    );

    const dailyJournalChannel = AndroidNotificationChannel(
      'daily_journal',
      'Daily Journal Reminder',
      description: 'Daily reminder to write your journal',
      importance: Importance.high,
    );

    // Usage limit notification channels
    const usageWarningChannel = AndroidNotificationChannel(
      _usageWarningChannelId,
      'Usage Warnings',
      description: 'Notifications for approaching app usage limits',
      importance: Importance.high,
    );

    const usageLimitChannel = AndroidNotificationChannel(
      _usageLimitChannelId,
      'Usage Limits',
      description: 'Notifications when app usage limit is reached',
      importance: Importance.max,
    );

    const dailySummaryChannel = AndroidNotificationChannel(
      _dailySummaryChannelId,
      'Daily Summary',
      description: 'Daily screen time summary notifications',
      importance: Importance.defaultImportance,
    );

    const achievementChannel = AndroidNotificationChannel(
      _achievementChannelId,
      'Achievements',
      description: 'Achievement and reward notifications',
      importance: Importance.high,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(blockedAppsChannel);
    await androidPlugin?.createNotificationChannel(focusStartChannel);
    await androidPlugin?.createNotificationChannel(focusCompleteChannel);
    await androidPlugin?.createNotificationChannel(streakChannel);
    await androidPlugin?.createNotificationChannel(dailyJournalChannel);
    await androidPlugin?.createNotificationChannel(usageWarningChannel);
    await androidPlugin?.createNotificationChannel(usageLimitChannel);
    await androidPlugin?.createNotificationChannel(dailySummaryChannel);
    await androidPlugin?.createNotificationChannel(achievementChannel);
  }

  static Future<void> _requestPermissions() async {
    // iOS permissions (Android controlled via system app settings)
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android 13+ notification permission
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  /// Request notification permissions (public method)
  static Future<bool> requestPermissions() async {
    try {
      if (Platform.isIOS) {
        final iosPlugin = _notifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final result = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return result ?? false;
      } else if (Platform.isAndroid) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final result = await androidPlugin?.requestNotificationsPermission();
        return result ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  // ==================== Usage Limit Notifications ====================

  /// Schedule a warning notification for approaching limit
  static Future<void> scheduleWarningNotification({
    required String appName,
    required int minutesRemaining,
    int percentUsed = 80,
  }) async {
    // Check if notifications are enabled in settings
    final settings = await _getNotificationSettings();
    if (!settings.enabled || !settings.warningsEnabled) return;

    final id = _warningBaseId + appName.hashCode.abs() % 1000;
    
    final payload = NotificationPayload(
      type: NotificationType.warning,
      appName: appName,
      data: {'minutesRemaining': minutesRemaining, 'percentUsed': percentUsed},
    );

    String title;
    String body;
    
    if (percentUsed >= 95) {
      title = '⚠️ Almost at limit!';
      body = '$appName: Only $minutesRemaining minutes remaining';
    } else if (percentUsed >= 90) {
      title = '⏰ 90% of limit used';
      body = '$appName: $minutesRemaining minutes left today';
    } else {
      title = '📊 80% of limit used';
      body = '$appName: $minutesRemaining minutes remaining';
    }

    final androidDetails = AndroidNotificationDetails(
      _usageWarningChannelId,
      'Usage Warnings',
      channelDescription: 'Notifications for approaching app usage limits',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF9800),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(payload.toJson()),
    );
  }

  /// Show a notification when limit is reached
  static Future<void> showLimitReachedNotification({
    required String appName,
  }) async {
    // Check if notifications are enabled in settings
    final settings = await _getNotificationSettings();
    if (!settings.enabled || !settings.limitsEnabled) return;

    final id = _limitBaseId + appName.hashCode.abs() % 1000;
    
    final payload = NotificationPayload(
      type: NotificationType.limit,
      appName: appName,
      data: {'limitReached': true},
    );

    final androidDetails = AndroidNotificationDetails(
      _usageLimitChannelId,
      'Usage Limits',
      channelDescription: 'Notifications when app usage limit is reached',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFF44336),
      ongoing: true,
      autoCancel: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      '🚫 Time Limit Reached',
      'Your daily limit for $appName has been reached. Take a break!',
      notificationDetails,
      payload: jsonEncode(payload.toJson()),
    );
  }

  /// Schedule daily summary notification
  static Future<void> scheduleDailySummary({
    required DateTime scheduledTime,
    required Map<String, int> usageData,
  }) async {
    // Check if notifications are enabled in settings
    final settings = await _getNotificationSettings();
    if (!settings.enabled || !settings.summaryEnabled) return;

    // Cancel any existing daily summary
    await _notifications.cancel(_summaryId);

    final totalMinutes = usageData.values.fold<int>(0, (sum, v) => sum + v);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    
    String timeString;
    if (hours > 0) {
      timeString = '${hours}h ${minutes}m';
    } else {
      timeString = '${minutes}m';
    }

    final topApps = usageData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topApp = topApps.isNotEmpty ? topApps.first.key : 'No apps';

    final payload = NotificationPayload(
      type: NotificationType.summary,
      data: {'totalMinutes': totalMinutes},
    );

    // Schedule for the specified time
    final now = DateTime.now();
    var scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDateTime, tz.local);

    final androidDetails = AndroidNotificationDetails(
      _dailySummaryChannelId,
      'Daily Summary',
      channelDescription: 'Daily screen time summary notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF2196F3),
      styleInformation: BigTextStyleInformation(
        'Total screen time: $timeString\n'
        'Most used app: $topApp\n'
        'Apps used: ${usageData.length}',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      _summaryId,
      '📱 Daily Screen Time Summary',
      'Today: $timeString • Most used: $topApp',
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode(payload.toJson()),
    );

    debugPrint('Daily summary scheduled for ${scheduledDateTime.toString()}');
  }

  /// Show achievement notification
  static Future<void> showAchievementNotification({
    required String achievement,
    required int xpGained,
    String? description,
  }) async {
    // Check if notifications are enabled in settings
    final settings = await _getNotificationSettings();
    if (!settings.enabled || !settings.achievementsEnabled) return;

    final id = _achievementBaseId + DateTime.now().millisecondsSinceEpoch % 1000;
    
    final payload = NotificationPayload(
      type: NotificationType.achievement,
      data: {'achievement': achievement, 'xpGained': xpGained},
    );

    final androidDetails = AndroidNotificationDetails(
      _achievementChannelId,
      'Achievements',
      channelDescription: 'Achievement and reward notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFFC107),
      styleInformation: description != null
          ? BigTextStyleInformation(
              '$achievement\n$description\n\nYou earned $xpGained XP!',
            )
          : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      '🏆 Achievement Unlocked!',
      '$achievement • +$xpGained XP',
      notificationDetails,
      payload: jsonEncode(payload.toJson()),
    );
  }

  /// Show 5-minute warning notification
  static Future<void> showFiveMinuteWarning({required String appName}) async {
    await scheduleWarningNotification(
      appName: appName,
      minutesRemaining: 5,
      percentUsed: 95,
    );
  }

  /// Show focus session notification (start, complete, break)
  static Future<void> showFocusSessionNotification({
    required String title,
    required String body,
  }) async {
    // Check if notifications are enabled in settings
    final settings = await _getNotificationSettings();
    if (!settings.enabled) return;

    final id = 4000 + DateTime.now().millisecondsSinceEpoch % 1000;
    
    final payload = NotificationPayload(
      type: NotificationType.info,
      data: {'focusSession': true},
    );

    const androidDetails = AndroidNotificationDetails(
      'focus_complete',
      'Focus Complete',
      channelDescription: 'Focus session notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF7C3AED),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(payload.toJson()),
    );
  }

  /// Cancel notifications for a specific app
  static Future<void> cancelAppNotifications(String appName) async {
    final warningId = _warningBaseId + appName.hashCode.abs() % 1000;
    final limitId = _limitBaseId + appName.hashCode.abs() % 1000;
    await _notifications.cancel(warningId);
    await _notifications.cancel(limitId);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get notification settings from SharedPreferences
  static Future<NotificationSettings> _getNotificationSettings() async {
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

  /// Get pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // ==================== Original Notification Methods ====================

  /// Schedule a daily notification at 22:00 local time (production mode).
  static Future<void> scheduleDailyJournalReminder() async {
    // Cancel any existing notification with this ID to avoid duplicates
    await _notifications.cancel(2000);
    
    final now = tz.TZDateTime.now(tz.local);
    // Next 22:00 local
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 22, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_journal',
      'Daily Journal Reminder',
      channelDescription: 'Daily reminder to write your UpHeal journal',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF6B46C1),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    // Daily schedule at 22:00 local time.
    await _notifications.zonedSchedule(
  2000, // id
  '📝 Evening Reflection',
  '🌿 Your journal is here whenever you\'re ready.',
  scheduled, // MUST be tz.TZDateTime
  notificationDetails,
  androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  matchDateTimeComponents: DateTimeComponents.time,
  payload: 'evening_reflection',
);
    print('Scheduled daily journal reminder for $scheduled (local time: ${now.hour}:${now.minute.toString().padLeft(2, '0')})');
  }

  /// Debug helper: show a test notification after a short delay (no scheduling).
  static Future<void> debugOneShotTestAfter(Duration delay) async {
    await Future.delayed(delay);
    await showTestNotification();
  }

  /// Helper for manual testing: show an immediate notification.
  static Future<void> showTestNotification() async {
    final androidDetails = AndroidNotificationDetails(
      'focus_channel',
      'Focus Mode',
      channelDescription: 'Notifications for focus mode',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6B46C1),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      9999,
      'Test Notification',
      'If you see this, notifications are working.',
      notificationDetails,
    );
  }

  static Future<void> showFocusStartNotification() async {
    final androidDetails = AndroidNotificationDetails(
      'focus_channel',
      'Focus Mode',
      channelDescription: 'Notifications for focus mode',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6B46C1),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      1,
      '🎯 Focus Mode Started',
      'Stay focused! Your blocked apps are now restricted.',
      notificationDetails,
    );
  }

  static Future<void> showFocusCompleteNotification(int xpEarned) async {
    final androidDetails = AndroidNotificationDetails(
      'focus_complete',
      'Focus Complete',
      channelDescription: 'Focus completion notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF45D9A8),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      2,
      '🎉 Focus Session Complete!',
      'Great job! You earned $xpEarned XP!',
      notificationDetails,
    );
  }

  static Future<void> showStreakNotification(int streak) async {
    final androidDetails = AndroidNotificationDetails(
      'streak_channel',
      'Focus Streaks',
      channelDescription: 'Focus streak notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6B46C1),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      3,
      '🔥 Focus Streak!',
      'Amazing! You have a $streak day focus streak!',
      notificationDetails,
    );
  }

  static Future<void> showBlockedAppNotification(String appName) async {
    final androidDetails = AndroidNotificationDetails(
      'blocked_apps',
      'Blocked Apps',
      channelDescription: 'Notifications when blocked apps are accessed',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6B46C1),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      999,
      '🚫 App Blocked During Focus',
      'You tried to open $appName! Stay focused! 💪',
      notificationDetails,
    );
  }

  /// Show a generic notification immediately
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
    String? payload,
  }) async {
    final settings = await _getNotificationSettings();
    if (!settings.enabled) return;

    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'streak_channel',
      'Streak Notifications',
      channelDescription: 'Notifications for streak reminders and achievements',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF6B35),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Schedule a notification for a specific time
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? channelId,
    String? payload,
  }) async {
    final settings = await _getNotificationSettings();
    if (!settings.enabled) return;

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'streak_channel',
      'Streak Notifications',
      channelDescription: 'Notifications for streak reminders and achievements',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF6B35),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );

    debugPrint('Notification $id scheduled for $scheduledDate');
  }

  /// Cancel a specific notification by ID
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
