import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/focus_session_model.dart';
import '../models/hive/focus_session_history.dart';
import '../services/notification_service.dart';
import '../services/screen_time_service.dart';

/// Service for managing focus sessions with persistence and background support
class FocusSessionService {
  static const String _boxName = 'focus_sessions';
  static const String _prefsKeyBlockedApps = 'focus_default_blocked_apps';
  static const String _prefsKeyActiveSession = 'focus_active_session';
  static const String _prefsKeySessionStart = 'focus_session_start';
  static const String _prefsKeySessionDuration = 'focus_session_duration';
  static const String _prefsKeySessionType = 'focus_session_type';
  static const String _prefsKeySessionNumber = 'focus_session_number';
  
  static Box<FocusSessionHistory>? _box;
  static FocusSessionState? _state;
  
  /// Initialize the service
  static Future<void> initialize(FocusSessionState state) async {
    _state = state;
    
    // Open Hive box
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<FocusSessionHistory>(_boxName);
    } else {
      _box = Hive.box<FocusSessionHistory>(_boxName);
    }
    
    // Load default blocked apps
    await _loadDefaultBlockedApps();
    
    // Load today's sessions
    await _loadTodaysSessions();
    
    // Check for and restore any active session from background
    await _restoreActiveSession();
    
    // Set up callbacks
    _setupCallbacks();
    
    debugPrint('FocusSessionService initialized');
  }
  
  /// Set up state callbacks
  static void _setupCallbacks() {
    if (_state == null) return;
    
    _state!.onSessionComplete = _onSessionComplete;
    _state!.onBlockApps = _blockApps;
    _state!.onUnblockApps = _unblockApps;
    _state!.onTick = _onTick;
  }
  
  /// Load default blocked apps from preferences
  static Future<void> _loadDefaultBlockedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appsJson = prefs.getStringList(_prefsKeyBlockedApps);
      if (appsJson != null && appsJson.isNotEmpty) {
        _state?.setDefaultBlockedApps(appsJson);
      }
    } catch (e) {
      debugPrint('Error loading default blocked apps: $e');
    }
  }
  
  /// Save default blocked apps to preferences
  static Future<void> saveDefaultBlockedApps(List<String> apps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKeyBlockedApps, apps);
      _state?.setDefaultBlockedApps(apps);
    } catch (e) {
      debugPrint('Error saving default blocked apps: $e');
    }
  }
  
  /// Load today's completed sessions from Hive
  static Future<void> _loadTodaysSessions() async {
    if (_box == null || _state == null) return;
    
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      final todaysSessions = _box!.values
          .where((session) => session.startTime.isAfter(todayStart))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      
      _state!.setTodaysSessions(todaysSessions);
    } catch (e) {
      debugPrint('Error loading today\'s sessions: $e');
    }
  }
  
  /// Restore active session from background (if app was killed)
  static Future<void> _restoreActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasActiveSession = prefs.getBool(_prefsKeyActiveSession) ?? false;
      
      if (!hasActiveSession) return;
      
      final startTimeMs = prefs.getInt(_prefsKeySessionStart);
      final durationSeconds = prefs.getInt(_prefsKeySessionDuration);
      final typeIndex = prefs.getInt(_prefsKeySessionType);
      final sessionNumber = prefs.getInt(_prefsKeySessionNumber) ?? 1;
      
      if (startTimeMs == null || durationSeconds == null || typeIndex == null) {
        await _clearActiveSessionPrefs();
        return;
      }
      
      final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
      final totalDuration = Duration(seconds: durationSeconds);
      final type = FocusSessionType.values[typeIndex];
      
      // Calculate remaining time
      final elapsed = DateTime.now().difference(startTime);
      final remaining = totalDuration - elapsed;
      
      if (remaining.inSeconds <= 0) {
        // Session completed while app was in background
        await _saveCompletedSession(
          type: type,
          durationSeconds: durationSeconds,
          startTime: startTime,
          completed: true,
          blockedApps: _state?.defaultBlockedApps ?? [],
          sessionNumber: sessionNumber,
        );
        await _clearActiveSessionPrefs();
        await _showSessionCompleteNotification(type);
      } else {
        // Resume session
        _state?.startSession(
          type: type,
          customDuration: remaining,
        );
        debugPrint('Restored active session with ${remaining.inSeconds}s remaining');
      }
    } catch (e) {
      debugPrint('Error restoring active session: $e');
      await _clearActiveSessionPrefs();
    }
  }
  
  /// Save active session state for background persistence
  static Future<void> _saveActiveSessionState() async {
    if (_state?.currentSession == null) {
      await _clearActiveSessionPrefs();
      return;
    }
    
    try {
      final session = _state!.currentSession!;
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_prefsKeyActiveSession, true);
      await prefs.setInt(_prefsKeySessionStart, session.startTime.millisecondsSinceEpoch);
      await prefs.setInt(_prefsKeySessionDuration, session.totalDuration.inSeconds);
      await prefs.setInt(_prefsKeySessionType, session.type.index);
      await prefs.setInt(_prefsKeySessionNumber, session.sessionNumber);
    } catch (e) {
      debugPrint('Error saving active session state: $e');
    }
  }
  
  /// Clear active session from preferences
  static Future<void> _clearActiveSessionPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyActiveSession);
      await prefs.remove(_prefsKeySessionStart);
      await prefs.remove(_prefsKeySessionDuration);
      await prefs.remove(_prefsKeySessionType);
      await prefs.remove(_prefsKeySessionNumber);
    } catch (e) {
      debugPrint('Error clearing active session prefs: $e');
    }
  }
  
  /// Called on each timer tick
  static void _onTick(FocusSessionData session) {
    // Save state periodically for background restoration
    if (session.remainingTime.inSeconds % 30 == 0) {
      _saveActiveSessionState();
    }
  }
  
  /// Called when a session completes
  static Future<void> _onSessionComplete() async {
    if (_state?.currentSession == null) return;
    
    final session = _state!.currentSession!;
    
    // Save to Hive
    await _saveCompletedSession(
      type: session.type,
      durationSeconds: session.totalDuration.inSeconds,
      startTime: session.startTime,
      completed: true,
      blockedApps: session.blockedApps,
      sessionNumber: session.sessionNumber,
    );
    
    // Clear active session prefs
    await _clearActiveSessionPrefs();
    
    // Show completion notification
    await _showSessionCompleteNotification(session.type);
  }
  
  /// Save a completed session to Hive
  static Future<void> _saveCompletedSession({
    required FocusSessionType type,
    required int durationSeconds,
    required DateTime startTime,
    required bool completed,
    required List<String> blockedApps,
    required int sessionNumber,
  }) async {
    if (_box == null) return;
    
    try {
      final history = FocusSessionHistory.create(
        type: type,
        durationSeconds: durationSeconds,
        startTime: startTime,
        completed: completed,
        blockedApps: blockedApps,
        sessionNumber: sessionNumber,
      );
      
      await _box!.put(history.id, history);
      _state?.addCompletedSession(history);
      
      debugPrint('Saved focus session: ${history.id}');
    } catch (e) {
      debugPrint('Error saving completed session: $e');
    }
  }
  
  /// Block apps during focus session
  static Future<void> _blockApps(List<String> apps) async {
    try {
      for (final packageName in apps) {
        await ScreenTimeService.blockApp(packageName);
      }
      debugPrint('Blocked ${apps.length} apps for focus session');
    } catch (e) {
      debugPrint('Error blocking apps: $e');
    }
  }
  
  /// Unblock apps after focus session
  static Future<void> _unblockApps(List<String> apps) async {
    try {
      for (final packageName in apps) {
        await ScreenTimeService.unblockApp(packageName);
      }
      debugPrint('Unblocked ${apps.length} apps after focus session');
    } catch (e) {
      debugPrint('Error unblocking apps: $e');
    }
  }
  
  /// Show session complete notification
  static Future<void> _showSessionCompleteNotification(FocusSessionType type) async {
    try {
      String title;
      String body;
      
      switch (type) {
        case FocusSessionType.focus:
          title = '🎉 Focus Session Complete!';
          body = 'Great work! Take a well-deserved break.';
          break;
        case FocusSessionType.shortBreak:
          title = '⏰ Break Over';
          body = 'Ready to focus again? Start your next session!';
          break;
        case FocusSessionType.longBreak:
          title = '☕ Long Break Over';
          body = 'Feeling refreshed? Let\'s get back to work!';
          break;
      }
      
      await NotificationService.showFocusSessionNotification(
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('Error showing session complete notification: $e');
    }
  }
  
  /// Get session history for a date range
  static List<FocusSessionHistory> getSessionsInRange(DateTime start, DateTime end) {
    if (_box == null) return [];
    
    return _box!.values
        .where((session) => 
            session.startTime.isAfter(start) && 
            session.startTime.isBefore(end))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  
  /// Get total focus time for a date
  static int getTotalFocusTimeForDate(DateTime date) {
    if (_box == null) return 0;
    
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    
    return _box!.values
        .where((s) => 
            s.type == FocusSessionType.focus && 
            s.completed &&
            s.startTime.isAfter(dayStart) && 
            s.startTime.isBefore(dayEnd))
        .fold(0, (sum, s) => sum + s.durationSeconds);
  }
  
  /// Get weekly focus statistics
  static Map<String, dynamic> getWeeklyStats() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    
    final sessions = getSessionsInRange(weekStartDate, now);
    final focusSessions = sessions.where((s) => 
        s.type == FocusSessionType.focus && s.completed).toList();
    
    final totalSeconds = focusSessions.fold(0, (sum, s) => sum + s.durationSeconds);
    final sessionCount = focusSessions.length;
    
    // Daily breakdown
    final dailyMinutes = <int, int>{};
    for (var i = 0; i < 7; i++) {
      dailyMinutes[i] = 0;
    }
    
    for (final session in focusSessions) {
      final dayIndex = session.startTime.weekday - 1;
      dailyMinutes[dayIndex] = (dailyMinutes[dayIndex] ?? 0) + 
          (session.durationSeconds ~/ 60);
    }
    
    return {
      'totalMinutes': totalSeconds ~/ 60,
      'sessionCount': sessionCount,
      'dailyMinutes': dailyMinutes,
      'averagePerDay': sessionCount > 0 ? (totalSeconds ~/ 60) ~/ 7 : 0,
    };
  }
  
  /// Clear all session history
  static Future<void> clearHistory() async {
    if (_box == null) return;
    await _box!.clear();
    _state?.resetDailyStats();
  }
  
  /// Close the service
  static Future<void> close() async {
    await _box?.close();
    _box = null;
    _state = null;
  }
}
