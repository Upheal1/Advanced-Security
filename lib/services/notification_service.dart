import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/notification_types.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Function(NotificationPayload)? onNotificationTap;

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

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
    );

    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      final parts = payload.split(':');
      if (parts.isNotEmpty) {
        final type = parts[0];
        final appName = parts.length > 1 ? parts[1] : '';
        onNotificationTap?.call(NotificationPayload(
          type: _parseType(type),
          appName: appName,
        ));
      }
    }
  }

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'warning':
        return NotificationType.warning;
      case 'limit':
        return NotificationType.limit;
      case 'summary':
        return NotificationType.summary;
      case 'achievement':
        return NotificationType.achievement;
      default:
        return NotificationType.info;
    }
  }

  static Future<void> showNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final notificationId = id ?? DateTime.now().millisecondsSinceEpoch % 100000;
    
    const androidDetails = AndroidNotificationDetails(
      'upheal_main',
      'UpHeal Notifications',
      channelDescription: 'Main notifications for UpHeal',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> showLimitReachedNotification({
    required String appName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'upheal_limits',
      'Usage Limits',
      channelDescription: 'Notifications when app usage limits are reached',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      2001,
      '⛔ Limit Reached',
      'You\'ve reached your daily limit for $appName',
      details,
      payload: 'limit:$appName',
    );
  }

  static Future<void> showFiveMinuteWarning({
    required String appName,
    int? remainingMinutes,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'upheal_warnings',
      'Usage Warnings',
      channelDescription: 'Warning notifications about app usage',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final minutes = remainingMinutes ?? 5;
    await _notifications.show(
      2002,
      '⚠️ Time Running Out',
      '$minutes minutes remaining for $appName',
      details,
      payload: 'warning:$appName',
    );
  }

  static Future<void> scheduleWarningNotification({
    int? id,
    required String appName,
    DateTime? scheduledTime,
    int? warningThreshold,
    int? minutesRemaining,
    int? percentUsed,
  }) async {
    final notificationId = id ?? appName.hashCode.abs() % 100000;
    final scheduled = scheduledTime ?? DateTime.now().add(const Duration(minutes: 1));
    final threshold = warningThreshold ?? 80;

    const androidDetails = AndroidNotificationDetails(
      'upheal_warnings',
      'Usage Warnings',
      channelDescription: 'Warning notifications about app usage',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      '⚠️ Approaching Limit',
      'You\'ve used $threshold% of your $appName limit',
      tz.TZDateTime.from(scheduled, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'warning:$appName',
    );
  }

  static Future<void> scheduleDailySummary({
    int? id,
    required DateTime scheduledTime,
    Map<String, int>? usageData,
  }) async {
    final notificationId = id ?? 5001;

    const androidDetails = AndroidNotificationDetails(
      'upheal_summary',
      'Daily Summary',
      channelDescription: 'Daily usage summary notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      '📊 Daily Summary',
      'Tap to see your daily screen time summary',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'summary:',
    );
  }

  static Future<void> showAchievementNotification({
    String? title,
    String? body,
    String? achievement,
    int? xpGained,
    String? description,
  }) async {
    final notificationTitle = title ?? 'Achievement Unlocked!';
    final notificationBody = body ?? description ?? 'Great job!';

    const androidDetails = AndroidNotificationDetails(
      'upheal_achievements',
      'Achievements',
      channelDescription: 'Achievement and reward notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      3001,
      '🏆 $notificationTitle',
      notificationBody,
      details,
      payload: 'achievement:$notificationTitle',
    );
  }

  static Future<void> showFocusSessionNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'upheal_focus',
      'Focus Sessions',
      channelDescription: 'Focus session notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      3002,
      title,
      body,
      details,
      payload: 'focus:session',
    );
  }

  static Future<bool> areNotificationsEnabled() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? false;
  }

  static Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final result = await android?.requestNotificationsPermission();
    return result ?? false;
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> scheduleNotification({
    int? id,
    required String title,
    required String body,
    DateTime? scheduledTime,
    DateTime? scheduledDate,
    String? payload,
  }) async {
    final notificationId = id ?? DateTime.now().millisecondsSinceEpoch % 100000;
    final scheduled = scheduledTime ?? scheduledDate ?? DateTime.now().add(const Duration(hours: 1));

    const androidDetails = AndroidNotificationDetails(
      'upheal_reminders',
      'UpHeal Reminders',
      channelDescription: 'Reminder notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduled, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  static Future<void> scheduleStreakReminder({
    int? id,
    required DateTime scheduledTime,
  }) async {
    final notificationId = id ?? 4001;

    const androidDetails = AndroidNotificationDetails(
      'upheal_streaks',
      'Streak Reminders',
      channelDescription: 'Streak reminder notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      '🔥 Keep Your Streak!',
      'Don\'t break your wellness streak - check in today!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'streak:reminder',
    );
  }
}

class UpHealNotificationService {
  static final UpHealNotificationService _instance = UpHealNotificationService._internal();
  factory UpHealNotificationService() => _instance;
  UpHealNotificationService._internal();

  Future<void> initialize() async {
    await NotificationService.initialize();
  }

  Future<void> showStreakReminder({required int streakDays}) async {
    final body = streakDays > 0
        ? 'You\'re on a $streakDays day streak! Don\'t break it today.'
        : 'Start your wellness journey today!';
    await NotificationService.showNotification(
      title: '🔥 Keep Your Streak Going!',
      body: body,
      payload: 'streak:$body',
    );
  }

  Future<void> showMotivationalMessage() async {
    final messages = [
      'Every step forward is progress. Keep going! 🌟',
      'Your mental wellness journey is unique. Be patient with yourself. 💜',
      'Small daily improvements lead to stunning results. 📈',
    ];
    final random = DateTime.now().millisecondsSinceEpoch % messages.length;
    await NotificationService.showNotification(
      title: '💭 Daily Inspiration',
      body: messages[random],
      payload: 'motivational:${messages[random]}',
    );
  }

  Future<void> showFocusSessionComplete({
    required int minutes,
    required int xpEarned,
  }) async {
    await NotificationService.showFocusSessionNotification(
      title: '🎯 Focus Session Complete!',
      body: 'Great job! You focused for $minutes minutes and earned $xpEarned XP.',
    );
  }

  Future<void> showAchievementUnlocked({
    required String title,
    required String description,
  }) async {
    await NotificationService.showAchievementNotification(
      title: title,
      body: description,
    );
  }

  Future<void> showLevelUp({required int newLevel}) async {
    await NotificationService.showNotification(
      title: '⬆️ Level Up!',
      body: 'Congratulations! You\'ve reached Level $newLevel. Keep growing!',
      payload: 'level_up:$newLevel',
    );
  }
}