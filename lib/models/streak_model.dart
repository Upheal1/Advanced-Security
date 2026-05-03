import 'package:flutter/foundation.dart';

/// Represents a single day's activity for streak tracking
class StreakDay {
  final DateTime date;
  final bool isCompleted;
  final int activitiesCount;
  final int xpEarned;
  final List<String> completedActivities;
  
  const StreakDay({
    required this.date,
    required this.isCompleted,
    this.activitiesCount = 0,
    this.xpEarned = 0,
    this.completedActivities = const [],
  });
  
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'isCompleted': isCompleted,
    'activitiesCount': activitiesCount,
    'xpEarned': xpEarned,
    'completedActivities': completedActivities,
  };
  
  factory StreakDay.fromJson(Map<String, dynamic> json) => StreakDay(
    date: DateTime.parse(json['date'] as String),
    isCompleted: json['isCompleted'] as bool? ?? false,
    activitiesCount: json['activitiesCount'] as int? ?? 0,
    xpEarned: json['xpEarned'] as int? ?? 0,
    completedActivities: List<String>.from(json['completedActivities'] ?? []),
  );
  
  StreakDay copyWith({
    DateTime? date,
    bool? isCompleted,
    int? activitiesCount,
    int? xpEarned,
    List<String>? completedActivities,
  }) => StreakDay(
    date: date ?? this.date,
    isCompleted: isCompleted ?? this.isCompleted,
    activitiesCount: activitiesCount ?? this.activitiesCount,
    xpEarned: xpEarned ?? this.xpEarned,
    completedActivities: completedActivities ?? this.completedActivities,
  );
}

/// Milestone types for streak achievements
enum StreakMilestoneType {
  firstDay,      // Day 1
  weekWarrior,   // 7 days
  twoWeeks,      // 14 days
  monthMaster,   // 30 days
  quarterChamp,  // 90 days
  halfYear,      // 180 days
  yearLegend,    // 365 days
}

/// Represents a streak milestone achievement
class StreakMilestone {
  final StreakMilestoneType type;
  final int daysRequired;
  final String title;
  final String description;
  final String emoji;
  final int xpReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  
  const StreakMilestone({
    required this.type,
    required this.daysRequired,
    required this.title,
    required this.description,
    required this.emoji,
    required this.xpReward,
    this.isUnlocked = false,
    this.unlockedAt,
  });
  
  static List<StreakMilestone> get allMilestones => [
    const StreakMilestone(
      type: StreakMilestoneType.firstDay,
      daysRequired: 1,
      title: 'First Step',
      description: 'Started your wellness journey!',
      emoji: '🌱',
      xpReward: 50,
    ),
    const StreakMilestone(
      type: StreakMilestoneType.weekWarrior,
      daysRequired: 7,
      title: 'Week Warrior',
      description: 'One full week of consistency!',
      emoji: '⚔️',
      xpReward: 100,
    ),
    const StreakMilestone(
      type: StreakMilestoneType.twoWeeks,
      daysRequired: 14,
      title: 'Habit Builder',
      description: 'Two weeks strong - habits forming!',
      emoji: '🏗️',
      xpReward: 200,
    ),
    const StreakMilestone(
      type: StreakMilestoneType.monthMaster,
      daysRequired: 30,
      title: 'Month Master',
      description: 'A full month of dedication!',
      emoji: '🏆',
      xpReward: 500,
    ),
    const StreakMilestone(
      type: StreakMilestoneType.quarterChamp,
      daysRequired: 90,
      title: 'Quarter Champion',
      description: '90 days of unwavering commitment!',
      emoji: '👑',
      xpReward: 1000,
    ),
    const StreakMilestone(
      type: StreakMilestoneType.halfYear,
      daysRequired: 180,
      title: 'Half-Year Hero',
      description: 'Six months of incredible progress!',
      emoji: '🦸',
      xpReward: 2000,
    ),
    const StreakMilestone(
      type: StreakMilestoneType.yearLegend,
      daysRequired: 365,
      title: 'Year Legend',
      description: 'ONE FULL YEAR! You are unstoppable!',
      emoji: '🌟',
      xpReward: 5000,
    ),
  ];
  
  StreakMilestone copyWith({bool? isUnlocked, DateTime? unlockedAt}) => StreakMilestone(
    type: type,
    daysRequired: daysRequired,
    title: title,
    description: description,
    emoji: emoji,
    xpReward: xpReward,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    unlockedAt: unlockedAt ?? this.unlockedAt,
  );
  
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'daysRequired': daysRequired,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };
}

/// Activity types that count towards streaks
enum StreakActivityType {
  journaling,
  assessment,
  challenge,
  sleepTracking,
  stepGoal,
  focusSession,
  meditation,
  socialEngagement,
  miniGame,
}

extension StreakActivityTypeExtension on StreakActivityType {
  String get displayName {
    switch (this) {
      case StreakActivityType.journaling:
        return 'Journaling';
      case StreakActivityType.assessment:
        return 'Self Assessment';
      case StreakActivityType.challenge:
        return 'Daily Challenge';
      case StreakActivityType.sleepTracking:
        return 'Sleep Tracking';
      case StreakActivityType.stepGoal:
        return 'Step Goal';
      case StreakActivityType.focusSession:
        return 'Focus Session';
      case StreakActivityType.meditation:
        return 'Meditation';
      case StreakActivityType.socialEngagement:
        return 'Community';
      case StreakActivityType.miniGame:
        return 'Brain Games';
    }
  }
  
  String get emoji {
    switch (this) {
      case StreakActivityType.journaling:
        return '📝';
      case StreakActivityType.assessment:
        return '🧠';
      case StreakActivityType.challenge:
        return '🎯';
      case StreakActivityType.sleepTracking:
        return '😴';
      case StreakActivityType.stepGoal:
        return '👟';
      case StreakActivityType.focusSession:
        return '🎯';
      case StreakActivityType.meditation:
        return '🧘';
      case StreakActivityType.socialEngagement:
        return '👥';
      case StreakActivityType.miniGame:
        return '🎮';
    }
  }
}

/// Main state model for streak tracking
class StreakState extends ChangeNotifier {
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalDaysActive = 0;
  int _freezeTokens = 1;  // Start with 1 free freeze
  int _totalXpEarned = 0;
  DateTime? _lastActiveDate;
  DateTime? _streakStartDate;
  bool _isTodayCompleted = false;
  bool _isLoading = true;
  int _lastStreakBeforeBreak = 0;
  DateTime? _lastBreakDate;
  
  List<StreakDay> _streakHistory = [];
  List<StreakMilestone> _milestones = StreakMilestone.allMilestones;
  Set<StreakActivityType> _todayActivities = {};
  
  // Getters
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get totalDaysActive => _totalDaysActive;
  int get freezeTokens => _freezeTokens;
  int get totalXpEarned => _totalXpEarned;
  DateTime? get lastActiveDate => _lastActiveDate;
  DateTime? get streakStartDate => _streakStartDate;
  bool get isTodayCompleted => _isTodayCompleted;
  bool get isLoading => _isLoading;
  List<StreakDay> get streakHistory => List.unmodifiable(_streakHistory);
  List<StreakMilestone> get milestones => List.unmodifiable(_milestones);
  Set<StreakActivityType> get todayActivities => Set.unmodifiable(_todayActivities);
  int get lastStreakBeforeBreak => _lastStreakBeforeBreak;
  DateTime? get lastBreakDate => _lastBreakDate;

  /// Indicates that the user recently had a break but has started again.
  ///
  /// This can be used for recovery/comeback UX without punishing users.
  bool get isInRecoveryWindow {
    if (_lastBreakDate == null || _currentStreak == 0) return false;
    final now = DateTime.now();
    // One week soft recovery window; can be tuned later.
    return now.difference(_lastBreakDate!).inDays < 7;
  }

  /// Current streak length counted as part of a recovery period.
  int get recoveryStreak => isInRecoveryWindow ? _currentStreak : 0;
  
  /// Check if streak is at risk (user hasn't completed today's activities)
  bool get isStreakAtRisk {
    if (_currentStreak == 0) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_lastActiveDate == null) return true;
    final lastActive = DateTime(_lastActiveDate!.year, _lastActiveDate!.month, _lastActiveDate!.day);
    
    // If last active was yesterday and today not completed
    final yesterday = today.subtract(const Duration(days: 1));
    return lastActive.isAtSameMomentAs(yesterday) && !_isTodayCompleted;
  }
  
  /// Hours remaining until streak is lost
  int get hoursUntilStreakLoss {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return endOfDay.difference(now).inHours;
  }
  
  /// Progress towards next milestone
  double get nextMilestoneProgress {
    final nextMilestone = _milestones.firstWhere(
      (m) => !m.isUnlocked,
      orElse: () => _milestones.last,
    );
    if (nextMilestone.isUnlocked) return 1.0;
    return _currentStreak / nextMilestone.daysRequired;
  }
  
  /// Next milestone to achieve
  StreakMilestone? get nextMilestone {
    try {
      return _milestones.firstWhere((m) => !m.isUnlocked);
    } catch (_) {
      return null;
    }
  }
  
  /// Days until next milestone
  int get daysUntilNextMilestone {
    final next = nextMilestone;
    if (next == null) return 0;
    return next.daysRequired - _currentStreak;
  }
  
  /// Get streak multiplier for XP calculations
  double get streakMultiplier {
    if (_currentStreak < 7) return 1.0;
    if (_currentStreak < 14) return 1.25;
    if (_currentStreak < 30) return 1.5;
    if (_currentStreak < 90) return 2.0;
    if (_currentStreak < 180) return 2.5;
    if (_currentStreak < 365) return 3.0;
    return 5.0;  // Year+ streak
  }
  
  /// Update loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Initialize streak data
  void initializeData({
    required int currentStreak,
    required int longestStreak,
    required int totalDaysActive,
    required int freezeTokens,
    required int totalXpEarned,
    DateTime? lastActiveDate,
    DateTime? streakStartDate,
    required List<StreakDay> history,
    required List<StreakMilestone> milestones,
    required Set<StreakActivityType> todayActivities,
    required bool isTodayCompleted,
  }) {
    _currentStreak = currentStreak;
    _longestStreak = longestStreak;
    _totalDaysActive = totalDaysActive;
    _freezeTokens = freezeTokens;
    _totalXpEarned = totalXpEarned;
    _lastActiveDate = lastActiveDate;
    _streakStartDate = streakStartDate;
    _streakHistory = history;
    _milestones = milestones;
    _todayActivities = todayActivities;
    _isTodayCompleted = isTodayCompleted;
    _isLoading = false;
    notifyListeners();
  }
  
  /// Record an activity for today
  void recordActivity(StreakActivityType activity, {int xpEarned = 0}) {
    _todayActivities.add(activity);
    _totalXpEarned += (xpEarned * streakMultiplier).round();
    
    // Check if we've met the daily requirement (at least 1 activity)
    if (_todayActivities.isNotEmpty && !_isTodayCompleted) {
      _completeTodayStreak();
    }
    
    notifyListeners();
  }
  
  /// Complete today's streak
  void _completeTodayStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if already completed today
    if (_isTodayCompleted && _lastActiveDate != null) {
      final lastActive = DateTime(_lastActiveDate!.year, _lastActiveDate!.month, _lastActiveDate!.day);
      if (lastActive.isAtSameMomentAs(today)) {
        // Already completed today, don't process again
        return;
      }
    }
    
    // Save the previous lastActiveDate before updating
    final previousLastActiveDate = _lastActiveDate;
    final previousLastActiveDay = previousLastActiveDate != null
        ? DateTime(previousLastActiveDate.year, previousLastActiveDate.month, previousLastActiveDate.day)
        : null;
    
    _isTodayCompleted = true;
    _lastActiveDate = today;
    _totalDaysActive++;
    
    // Check if this extends the streak or starts a new one
    if (previousLastActiveDay == null || _streakStartDate == null) {
      // Starting a new streak
      _streakStartDate = today;
      _currentStreak = 1;
    } else {
      // Check if last active date was yesterday (continuous streak)
      final yesterday = today.subtract(const Duration(days: 1));
      
      if (previousLastActiveDay.isAtSameMomentAs(yesterday)) {
        // Continuous streak - increment
        _currentStreak++;
      } else if (previousLastActiveDay.isAtSameMomentAs(today)) {
        // Already completed today, shouldn't happen but handle gracefully
        return;
      } else {
        // Gap detected - start new streak
        _streakStartDate = today;
        _currentStreak = 1;
      }
    }
    
    // Update longest streak
    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }
    
    // Add to history
    _streakHistory.insert(0, StreakDay(
      date: today,
      isCompleted: true,
      activitiesCount: _todayActivities.length,
      xpEarned: 0, // Will be calculated
      completedActivities: _todayActivities.map((a) => a.name).toList(),
    ));
    
    // Check for new milestones
    _checkMilestones();
    
    notifyListeners();
  }
  
  /// Check and unlock any new milestones
  void _checkMilestones() {
    final now = DateTime.now();
    for (int i = 0; i < _milestones.length; i++) {
      final milestone = _milestones[i];
      if (!milestone.isUnlocked && _currentStreak >= milestone.daysRequired) {
        _milestones[i] = milestone.copyWith(
          isUnlocked: true,
          unlockedAt: now,
        );
        _totalXpEarned += milestone.xpReward;
      }
    }
  }
  
  /// Use a freeze token to protect the streak
  bool useFreeze() {
    if (_freezeTokens <= 0) return false;
    
    _freezeTokens--;
    
    // Add a frozen day to history
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayNormalized = DateTime(yesterday.year, yesterday.month, yesterday.day);
    
    _streakHistory.insert(0, StreakDay(
      date: yesterdayNormalized,
      isCompleted: true, // Counted as completed due to freeze
      activitiesCount: 0,
      completedActivities: ['streak_freeze'],
    ));
    
    notifyListeners();
    return true;
  }
  
  /// Add freeze tokens (earned or purchased)
  void addFreezeTokens(int count) {
    _freezeTokens += count;
    notifyListeners();
  }
  
  /// Break the streak (called when user misses a day without freeze)
  void breakStreak() {
    // Preserve the streak length that was just lost so we can offer
    // supportive recovery/comeback experiences instead of only punishment.
    if (_currentStreak > 0) {
      _lastStreakBeforeBreak = _currentStreak;
      _lastBreakDate = DateTime.now();
    }
    _currentStreak = 0;
    _streakStartDate = null;
    _isTodayCompleted = false;
    _todayActivities.clear();
    notifyListeners();
  }
  
  /// Reset for new day
  void resetForNewDay() {
    _isTodayCompleted = false;
    _todayActivities.clear();
    notifyListeners();
  }
  
  /// Get streak day for a specific date
  StreakDay? getStreakDay(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    try {
      return _streakHistory.firstWhere(
        (day) => DateTime(day.date.year, day.date.month, day.date.day)
            .isAtSameMomentAs(normalized),
      );
    } catch (_) {
      return null;
    }
  }
  
  /// Get all completed days in date range
  List<DateTime> getCompletedDaysInRange(DateTime start, DateTime end) {
    return _streakHistory
        .where((day) => 
            day.isCompleted && 
            day.date.isAfter(start.subtract(const Duration(days: 1))) &&
            day.date.isBefore(end.add(const Duration(days: 1))))
        .map((day) => day.date)
        .toList();
  }
  
  /// Calculate completion rate for a time period
  double getCompletionRate(int days) {
    if (_streakHistory.isEmpty) return 0.0;
    
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recentDays = _streakHistory.where(
      (day) => day.date.isAfter(cutoff)
    ).toList();
    
    if (recentDays.isEmpty) return 0.0;
    
    final completedCount = recentDays.where((d) => d.isCompleted).length;
    return completedCount / days;
  }
}
