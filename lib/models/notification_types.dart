import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';

/// Types of notifications in the app
enum NotificationType {
  /// Warning notification when approaching usage limit
  warning,
  
  /// Notification when usage limit is reached
  limit,
  
  /// Daily usage summary notification
  summary,
  
  /// Achievement/reward notification
  achievement,
  
  /// General informational notification
  info,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.warning:
        return 'Usage Warning';
      case NotificationType.limit:
        return 'Limit Reached';
      case NotificationType.summary:
        return 'Daily Summary';
      case NotificationType.achievement:
        return 'Achievement';
      case NotificationType.info:
        return 'Information';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.limit:
        return Icons.block_rounded;
      case NotificationType.summary:
        return Icons.summarize_rounded;
      case NotificationType.achievement:
        return Icons.emoji_events_rounded;
      case NotificationType.info:
        return Icons.info_outline_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.limit:
        return Colors.red;
      case NotificationType.summary:
        return Colors.blue;
      case NotificationType.achievement:
        return Colors.amber;
      case NotificationType.info:
        return Colors.grey;
    }
  }
}

/// Payload model for notification data
class NotificationPayload {
  final NotificationType type;
  final String? appName;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  NotificationPayload({
    required this.type,
    this.appName,
    Map<String, dynamic>? data,
    DateTime? timestamp,
  })  : data = data ?? {},
        timestamp = timestamp ?? DateTime.now();

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.info,
      ),
      appName: json['appName'] as String?,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'appName': appName,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'NotificationPayload(type: $type, appName: $appName, data: $data)';
  }
}

/// Handler for deep linking from notifications
class DeepLinkHandler {
  /// Navigate based on notification payload
  static void handleNotification(
    BuildContext context,
    NotificationPayload payload,
  ) {
    switch (payload.type) {
      case NotificationType.warning:
      case NotificationType.limit:
        // Navigate to analytics screen to see usage
        _navigateToAnalytics(context, payload.appName);
        break;
      case NotificationType.summary:
        // Navigate to analytics screen with summary view
        _navigateToAnalytics(context, null);
        break;
      case NotificationType.achievement:
        // Navigate to profile/achievements screen
        _navigateToProfile(context);
        break;
      case NotificationType.info:
        // Just show the notification, no navigation needed
        break;
    }
  }

  static void _navigateToAnalytics(BuildContext context, String? appName) {
    const AnalyticsRoute().go(context);
  }

  static void _navigateToProfile(BuildContext context) {
    const ProfileRoute().go(context);
  }

  /// Get the route name for a notification type
  static String getRouteForType(NotificationType type) {
    switch (type) {
      case NotificationType.warning:
      case NotificationType.limit:
      case NotificationType.summary:
        return AnalyticsRoute.path;
      case NotificationType.achievement:
        return ProfileRoute.path;
      case NotificationType.info:
        return HomeRoute.path;
    }
  }
}

/// Notification settings model
class NotificationSettings {
  final bool enabled;
  final bool warningsEnabled;
  final bool limitsEnabled;
  final bool summaryEnabled;
  final bool achievementsEnabled;
  final int warningThreshold; // Percentage (e.g., 80, 90, 95)
  final DateTime summaryTime;
  final bool soundEnabled;
  final bool vibrationEnabled;

  NotificationSettings({
    this.enabled = true,
    this.warningsEnabled = true,
    this.limitsEnabled = true,
    this.summaryEnabled = true,
    this.achievementsEnabled = true,
    this.warningThreshold = 80,
    DateTime? summaryTime,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  }) : summaryTime = summaryTime ?? DateTime(2024, 1, 1, 20, 0); // Default 8 PM

  // Factory to create default settings
  static NotificationSettings get defaults => NotificationSettings();

  NotificationSettings copyWith({
    bool? enabled,
    bool? warningsEnabled,
    bool? limitsEnabled,
    bool? summaryEnabled,
    bool? achievementsEnabled,
    int? warningThreshold,
    DateTime? summaryTime,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      warningsEnabled: warningsEnabled ?? this.warningsEnabled,
      limitsEnabled: limitsEnabled ?? this.limitsEnabled,
      summaryEnabled: summaryEnabled ?? this.summaryEnabled,
      achievementsEnabled: achievementsEnabled ?? this.achievementsEnabled,
      warningThreshold: warningThreshold ?? this.warningThreshold,
      summaryTime: summaryTime ?? this.summaryTime,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      warningsEnabled: json['warningsEnabled'] ?? true,
      limitsEnabled: json['limitsEnabled'] ?? true,
      summaryEnabled: json['summaryEnabled'] ?? true,
      achievementsEnabled: json['achievementsEnabled'] ?? true,
      warningThreshold: json['warningThreshold'] ?? 80,
      summaryTime: json['summaryTime'] != null
          ? DateTime.parse(json['summaryTime'])
          : DateTime(2024, 1, 1, 20, 0), // Default 8 PM
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'warningsEnabled': warningsEnabled,
      'limitsEnabled': limitsEnabled,
      'summaryEnabled': summaryEnabled,
      'achievementsEnabled': achievementsEnabled,
      'warningThreshold': warningThreshold,
      'summaryTime': summaryTime.toIso8601String(),
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }
}
