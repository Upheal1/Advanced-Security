import 'dart:async';
import 'package:flutter/foundation.dart';

enum BlockReasonType {
  dailyLimitReached,
  focusSessionActive,
  blockedByUser,
}

class BlockedAppViewModel extends ChangeNotifier {
  BlockedAppViewModel({
    required this.packageName,
    required this.appName,
    required this.reason,
    required Duration remaining,
    this.canEmergencyAllow = false,
    this.hasUsedEmergencyToday = false,
    this.showTakeBreath = true,
    this.showReturnHome = true,
    this.onEmergencyAllow,
  }) : _remaining = remaining {
    // Drive the remaining time display in the UI.
    _startCountdown();
  }

  final String packageName;
  final String appName;
  final BlockReasonType reason;
  final bool canEmergencyAllow;
  final bool hasUsedEmergencyToday;
  final bool showTakeBreath;
  final bool showReturnHome;
  final Future<void> Function()? onEmergencyAllow;

  Duration _remaining;
  Timer? _timer;
  bool _emergencyGranted = false;

  Duration get remaining => _remaining;
  bool get emergencyGranted => _emergencyGranted;

  /// Whether to show the emergency allow button
  bool get allowEmergencyAllow =>
      canEmergencyAllow && !hasUsedEmergencyToday && !_emergencyGranted;

  String get reasonText {
    switch (reason) {
      case BlockReasonType.focusSessionActive:
        return 'Focus session active';
      case BlockReasonType.dailyLimitReached:
        return 'Daily limit reached';
      case BlockReasonType.blockedByUser:
        return 'Blocked by you';
    }
  }

  String get remainingText {
    if (_emergencyGranted) {
      return 'Allowed';
    }
    final totalMinutes = _remaining.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// Grant emergency allow (called from UI)
  Future<void> grantEmergencyAllow() async {
    if (onEmergencyAllow != null) {
      await onEmergencyAllow!.call();
      _emergencyGranted = true;
      notifyListeners();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    // Tick once per minute to keep UI light and readable (hh:mm).
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_remaining.inMinutes <= 0) {
        _remaining = Duration.zero;
        _timer?.cancel();
      } else {
        _remaining = Duration(minutes: _remaining.inMinutes - 1);
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

