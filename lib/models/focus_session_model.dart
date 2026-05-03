import 'dart:async';
import 'package:flutter/foundation.dart';
import 'hive/focus_session_history.dart';

/// Current state of a focus session
enum FocusSessionStatus {
  idle,
  running,
  paused,
  completed,
}

/// Active focus session data
class FocusSessionData {
  final FocusSessionType type;
  final Duration totalDuration;
  final Duration remainingTime;
  final DateTime startTime;
  final List<String> blockedApps;
  final int sessionNumber;

  const FocusSessionData({
    required this.type,
    required this.totalDuration,
    required this.remainingTime,
    required this.startTime,
    required this.blockedApps,
    required this.sessionNumber,
  });

  /// Create a new session
  factory FocusSessionData.create({
    required FocusSessionType type,
    Duration? customDuration,
    required List<String> blockedApps,
    required int sessionNumber,
  }) {
    final duration = customDuration ?? type.defaultDuration;
    return FocusSessionData(
      type: type,
      totalDuration: duration,
      remainingTime: duration,
      startTime: DateTime.now(),
      blockedApps: blockedApps,
      sessionNumber: sessionNumber,
    );
  }

  /// Progress from 0.0 to 1.0
  double get progress {
    if (totalDuration.inSeconds == 0) return 1.0;
    final elapsed = totalDuration.inSeconds - remainingTime.inSeconds;
    return (elapsed / totalDuration.inSeconds).clamp(0.0, 1.0);
  }

  /// Check if completed
  bool get isCompleted => remainingTime.inSeconds <= 0;

  /// Formatted remaining time (MM:SS or HH:MM:SS)
  String get formattedTime {
    final hours = remainingTime.inHours;
    final minutes = remainingTime.inMinutes.remainder(60);
    final seconds = remainingTime.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Copy with new remaining time
  FocusSessionData copyWith({
    Duration? remainingTime,
  }) {
    return FocusSessionData(
      type: type,
      totalDuration: totalDuration,
      remainingTime: remainingTime ?? this.remainingTime,
      startTime: startTime,
      blockedApps: blockedApps,
      sessionNumber: sessionNumber,
    );
  }
}

/// Focus session state manager with ChangeNotifier
class FocusSessionState extends ChangeNotifier {
  FocusSessionData? _currentSession;
  FocusSessionStatus _status = FocusSessionStatus.idle;
  int _sessionsCompletedToday = 0;
  int _totalSessionsInCycle = 4; // Pomodoro default
  List<String> _defaultBlockedApps = [];
  List<FocusSessionHistory> _todaysSessions = [];

  // Timer
  Timer? _timer;
  static const _tickDuration = Duration(seconds: 1);

  // Callbacks
  Function()? onSessionComplete;
  Function(FocusSessionData)? onTick;
  Function(List<String>)? onBlockApps;
  Function(List<String>)? onUnblockApps;

  // Getters
  FocusSessionData? get currentSession => _currentSession;
  FocusSessionStatus get status => _status;
  bool get isActive => _status == FocusSessionStatus.running;
  bool get isPaused => _status == FocusSessionStatus.paused;
  bool get isIdle => _status == FocusSessionStatus.idle;
  int get sessionsCompletedToday => _sessionsCompletedToday;
  int get totalSessionsInCycle => _totalSessionsInCycle;
  Duration? get remainingTime => _currentSession?.remainingTime;
  List<String> get defaultBlockedApps => _defaultBlockedApps;
  List<FocusSessionHistory> get todaysSessions => _todaysSessions;

  /// Current session number in cycle (1-based)
  int get currentSessionNumber {
    if (_currentSession != null) {
      return _currentSession!.sessionNumber;
    }
    return (_sessionsCompletedToday % _totalSessionsInCycle) + 1;
  }

  /// Check if it's time for a long break
  bool get isLongBreakDue => _sessionsCompletedToday > 0 && 
      _sessionsCompletedToday % _totalSessionsInCycle == 0;

  /// Get suggested next session type
  FocusSessionType get suggestedNextType {
    if (_currentSession?.type == FocusSessionType.focus) {
      return isLongBreakDue 
          ? FocusSessionType.longBreak 
          : FocusSessionType.shortBreak;
    }
    return FocusSessionType.focus;
  }

  /// Set default blocked apps
  void setDefaultBlockedApps(List<String> apps) {
    _defaultBlockedApps = List.from(apps);
    notifyListeners();
  }

  /// Set today's sessions (loaded from Hive)
  void setTodaysSessions(List<FocusSessionHistory> sessions) {
    _todaysSessions = sessions;
    _sessionsCompletedToday = sessions
        .where((s) => s.type == FocusSessionType.focus && s.completed)
        .length;
    notifyListeners();
  }

  /// Add a completed session to today's list
  void addCompletedSession(FocusSessionHistory session) {
    _todaysSessions.add(session);
    if (session.type == FocusSessionType.focus && session.completed) {
      _sessionsCompletedToday++;
    }
    notifyListeners();
  }

  /// Start a new focus session
  void startSession({
    FocusSessionType type = FocusSessionType.focus,
    Duration? customDuration,
    List<String>? blockedApps,
  }) {
    // Cancel any existing timer
    _timer?.cancel();

    // Create new session
    _currentSession = FocusSessionData.create(
      type: type,
      customDuration: customDuration,
      blockedApps: blockedApps ?? _defaultBlockedApps,
      sessionNumber: currentSessionNumber,
    );
    _status = FocusSessionStatus.running;

    // Block apps
    if (_currentSession!.blockedApps.isNotEmpty) {
      onBlockApps?.call(_currentSession!.blockedApps);
    }

    // Start timer
    _startTimer();
    notifyListeners();
  }

  /// Pause the current session
  void pauseSession() {
    if (_status != FocusSessionStatus.running || _currentSession == null) return;

    _timer?.cancel();
    _status = FocusSessionStatus.paused;
    notifyListeners();
  }

  /// Resume a paused session
  void resumeSession() {
    if (_status != FocusSessionStatus.paused || _currentSession == null) return;

    _status = FocusSessionStatus.running;
    _startTimer();
    notifyListeners();
  }

  /// Stop the current session (without completing)
  void stopSession() {
    _timer?.cancel();
    
    // Unblock apps
    if (_currentSession != null && _currentSession!.blockedApps.isNotEmpty) {
      onUnblockApps?.call(_currentSession!.blockedApps);
    }

    _currentSession = null;
    _status = FocusSessionStatus.idle;
    notifyListeners();
  }

  /// Complete the current session
  void completeSession() {
    if (_currentSession == null) return;

    _timer?.cancel();
    _status = FocusSessionStatus.completed;

    // Unblock apps
    if (_currentSession!.blockedApps.isNotEmpty) {
      onUnblockApps?.call(_currentSession!.blockedApps);
    }

    // Trigger completion callback
    onSessionComplete?.call();

    // Reset for next session
    _currentSession = null;
    _status = FocusSessionStatus.idle;
    notifyListeners();
  }

  /// Skip to next session type
  void skipToNext() {
    stopSession();
    
    final nextType = suggestedNextType;
    startSession(type: nextType);
  }

  /// Start the countdown timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tickDuration, _onTick);
  }

  /// Timer tick handler
  void _onTick(Timer timer) {
    if (_currentSession == null || _status != FocusSessionStatus.running) {
      timer.cancel();
      return;
    }

    // Decrement remaining time
    final newRemaining = _currentSession!.remainingTime - _tickDuration;
    
    if (newRemaining.inSeconds <= 0) {
      // Session complete
      _currentSession = _currentSession!.copyWith(
        remainingTime: Duration.zero,
      );
      completeSession();
    } else {
      _currentSession = _currentSession!.copyWith(
        remainingTime: newRemaining,
      );
      onTick?.call(_currentSession!);
      notifyListeners();
    }
  }

  /// Update remaining time (for background restoration)
  void updateRemainingTime(Duration remaining) {
    if (_currentSession == null) return;

    _currentSession = _currentSession!.copyWith(
      remainingTime: remaining,
    );
    notifyListeners();
  }

  /// Get total focus time today in seconds
  int get totalFocusTimeToday {
    return _todaysSessions
        .where((s) => s.type == FocusSessionType.focus && s.completed)
        .fold(0, (sum, s) => sum + s.durationSeconds);
  }

  /// Get formatted total focus time today
  String get formattedTotalFocusTime {
    final totalSeconds = totalFocusTimeToday;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Reset daily stats
  void resetDailyStats() {
    _sessionsCompletedToday = 0;
    _todaysSessions.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
