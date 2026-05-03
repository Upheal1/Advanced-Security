import 'package:shared_preferences/shared_preferences.dart';

import '../models/streak_model.dart';
import '../models/user_model.dart';

/// Result of a comeback reward check.
class ComebackRewardResult {
  final bool granted;
  final int xpGranted;
  final String? message;

  const ComebackRewardResult({
    required this.granted,
    this.xpGranted = 0,
    this.message,
  });

  static const ComebackRewardResult none =
      ComebackRewardResult(granted: false, xpGranted: 0, message: null);
}

/// Gentle comeback rewards for users returning after a break.
///
/// This logic is intentionally simple and conservative so it feels supportive
/// rather than pressuring. It uses streak history to detect a real break and
/// gives a small XP bonus once per comeback day.
class ComebackRewardService {
  static const String _lastRewardKey = 'comeback_reward_last_granted';

  static DateTime _normalizeDate(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  /// Check if today qualifies as a comeback day and, if so, grant a small XP
  /// reward. Returns a [ComebackRewardResult] the UI can use to show feedback.
  static Future<ComebackRewardResult> checkAndApply({
    required StreakState streakState,
    required UserModel user,
  }) async {
    final now = DateTime.now();
    final today = _normalizeDate(now);

    // Only consider comeback rewards when a new streak has just started.
    if (streakState.currentStreak != 1 || streakState.streakHistory.isEmpty) {
      return ComebackRewardResult.none;
    }

    // Find the most recent completed day before today.
    final previousCompletedDays = streakState.streakHistory
        .where((day) =>
            day.isCompleted && _normalizeDate(day.date).isBefore(today))
        .map((day) => _normalizeDate(day.date))
        .toList();

    if (previousCompletedDays.isEmpty) {
      // This is likely the user's first ever streak day, not a comeback.
      return ComebackRewardResult.none;
    }

    previousCompletedDays.sort();
    final lastCompletedDay = previousCompletedDays.last;
    final gapDays = today.difference(lastCompletedDay).inDays;

    // Require at least a full day gap to treat as a "break".
    if (gapDays < 2) {
      return ComebackRewardResult.none;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastRewardStr = prefs.getString(_lastRewardKey);
    if (lastRewardStr != null) {
      final parsed = DateTime.tryParse(lastRewardStr);
      if (parsed != null && _normalizeDate(parsed) == today) {
        // Already granted a comeback reward today.
        return ComebackRewardResult.none;
      }
    }

    // Gentle, small reward for coming back after a break.
    const xpReward = 20;
    user.addXp(xpReward);

    await prefs.setString(_lastRewardKey, today.toIso8601String());

    return const ComebackRewardResult(
      granted: true,
      xpGranted: xpReward,
      message:
          'Welcome back! You\'ve earned a small bonus for showing up again today.',
    );
  }
}

