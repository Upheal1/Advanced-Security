import '../gamification/models/wellness_activity.dart';

/// Central configuration and helper methods for XP and level progression.
///
/// This keeps tuning in one place so you can adjust:
/// - base XP values
/// - per‑activity rewards
/// - level curve
/// - bonus rules (streaks / events) in a controlled way.
class XpConfig {
  XpConfig._();

  /// Base XP needed to go from level 1 → 2.
  static const int baseXpPerLevel = 100;

  /// How much additional XP each higher level requires.
  ///
  /// For example, with 50:
  /// - L1→2: 100 XP
  /// - L2→3: 150 XP
  /// - L3→4: 200 XP
  static const int xpIncrementPerLevel = 50;

  /// Optional daily soft cap for XP (not enforced yet).
  static const int? softDailyXpCap = null;

  /// Default XP rewards per wellness activity.
  ///
  /// These are deliberately conservative to avoid over‑rewarding
  /// short, meaningless interactions.
  static const Map<WellnessActivityType, int> baseActivityXp = {
    WellnessActivityType.moodLog: 5,
    WellnessActivityType.breathing: 5,
    WellnessActivityType.journal: 10,
    WellnessActivityType.challenge: 10,
    WellnessActivityType.focusSession: 15,
    WellnessActivityType.sleepLog: 5,
    WellnessActivityType.stepGoal: 10,
    WellnessActivityType.aiChat: 5,
  };

  /// Returns the amount of XP required to gain the next level from [level].
  ///
  /// This does *not* return total lifetime XP, only the XP cost of the step
  /// between `level` and `level + 1`.
  static int xpForLevelUp(int level) {
    if (level < 1) return baseXpPerLevel;
    return baseXpPerLevel + (level - 1) * xpIncrementPerLevel;
  }

  /// Returns the total lifetime XP required to *reach* [targetLevel].
  ///
  /// For example:
  /// - totalXpForLevel(1) == 0  (starting level)
  /// - totalXpForLevel(2) == 100
  /// - totalXpForLevel(3) == 250
  static int totalXpForLevel(int targetLevel) {
    if (targetLevel <= 1) return 0;
    var total = 0;
    for (var l = 1; l < targetLevel; l++) {
      total += xpForLevelUp(l);
    }
    return total;
  }

  /// Helper to compute progress within the *current* level.
  ///
  /// Returns a value between 0.0 and 1.0.
  static double levelProgress({
    required int level,
    required int totalXp,
  }) {
    if (level < 1) return 0.0;

    final currentLevelFloorXp = totalXpForLevel(level);
    final nextLevelFloorXp = totalXpForLevel(level + 1);
    final span = nextLevelFloorXp - currentLevelFloorXp;
    if (span <= 0) return 0.0;

    final inLevelXp = (totalXp - currentLevelFloorXp).clamp(0, span);
    return inLevelXp / span;
  }

  /// Compute the base XP reward for a completed [activity].
  ///
  /// Higher‑level modifiers (streaks, events, caps) should be applied by
  /// higher‑level services (e.g. an XP manager) rather than here.
  static int xpForActivity(WellnessActivity activity) {
    final base = baseActivityXp[activity.type] ?? 0;
    return base;
  }
}

