import 'package:flutter/foundation.dart';
import '../gamification/xp_config.dart';

class UserModel extends ChangeNotifier {
  UserModel({
    required this.username,
    String bio = '',
    DateTime? joinDate,
    int totalFocusMinutes = 0,
    int totalSessions = 0,
    int xp = 0,
    int level = 1,
    int streakDays = 0,
    int badges = 0,
    int rank = 100,
  })  : _xp = xp,
        _level = level,
        _streakDays = streakDays,
        _badges = badges,
        _rank = rank,
        _bio = bio,
        _joinDate = joinDate ?? DateTime.now(),
        _totalFocusMinutes = totalFocusMinutes,
        _totalSessions = totalSessions;

  String username;
  int _xp;
  int _level;
  int _streakDays;
  int _badges;
  int _rank;
  String _bio;
  DateTime _joinDate;
  int _totalFocusMinutes;
  int _totalSessions;

  int get xp => _xp;
  int get level => _level;
  int get streakDays => _streakDays;
  int get badges => _badges;
  int get rank => _rank;
  String get bio => _bio;
  DateTime get joinDate => _joinDate;
  int get totalFocusMinutes => _totalFocusMinutes;
  int get totalSessions => _totalSessions;

  double get levelProgress {
    return XpConfig.levelProgress(level: _level, totalXp: _xp);
  }

  void addXp(int amount) {
    if (amount <= 0) return;
    _xp += amount;
    while (_xp >= XpConfig.totalXpForLevel(_level + 1)) {
      _level += 1;
    }
    notifyListeners();
  }

  void incrementStreak() {
    _streakDays += 1;
    notifyListeners();
  }

  /// Set streak to a specific value (for syncing with StreakState)
  void setStreak(int streak) {
    if (streak < 0) return;
    _streakDays = streak;
    notifyListeners();
  }

  void awardBadge() {
    _badges += 1;
    notifyListeners();
  }

  void updateRank(int newRank) {
    _rank = newRank;
    notifyListeners();
  }

  void updateUsername(String newUsername) {
    username = newUsername;
    notifyListeners();
  }

  void updateBio(String newBio) {
    _bio = newBio;
    notifyListeners();
  }

  void setJoinDate(DateTime joinDate) {
    _joinDate = joinDate;
    notifyListeners();
  }

  void setTotalFocusMinutes(int minutes) {
    if (minutes < 0) return;
    _totalFocusMinutes = minutes;
    notifyListeners();
  }

  void addFocusMinutes(int minutes) {
    if (minutes <= 0) return;
    _totalFocusMinutes += minutes;
    notifyListeners();
  }

  void setTotalSessions(int sessions) {
    if (sessions < 0) return;
    _totalSessions = sessions;
    notifyListeners();
  }

  void addSession({int count = 1}) {
    if (count <= 0) return;
    _totalSessions += count;
    notifyListeners();
  }
}


