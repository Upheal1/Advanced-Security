import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../avatar/services/avatar_provider.dart';
import '../constants/app_colors.dart';
import '../gamification/xp_config.dart';
import '../models/achievement.dart';
import '../models/auth_model.dart';
import '../models/challenge_model.dart';
import '../models/mission_model.dart';
import '../models/journal_model.dart';
import '../models/navigation_model.dart';
import '../models/streak_model.dart';
import '../models/user_model.dart';
import '../services/challenge_service.dart';
import '../widgets/drawer_menu_button.dart';
import 'avatar_display.dart';

/// Profile — Upheal-style achievement hub (warm palette, tabs, badges, board).
/// Uses existing [Provider] models only (no backend changes).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tabIndex = 0;

  static const _bg = Color(0xFFFAFAF8);
  static const _mountainGray = Color(0xFF4A5565);
  static const _muted = Color(0xFF7C8496);
  static const _skyBlue = Color(0xFF7EB6FF);
  static const _sage = Color(0xFF6BA88A);
  static const _teal = Color(0xFF5A9B9B);
  static const _gold = Color(0xFFE8C547);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<JournalModel>().loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0D12) : _bg;
    final card = isDark ? const Color(0xFF16191F) : Colors.white;
    final onCard = isDark ? Colors.white : _mountainGray;
    final subtle = isDark ? Colors.white60 : _muted;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Consumer6<AuthModel, UserModel, AvatarProvider, StreakState,
            MissionsModel, ChallengeService>(
          builder: (context, auth, user, avatar, streak, missions, challenges,
              _) {
            final journal = context.watch<JournalModel>();
            final journalCount = journal.entries.length;
            final displayName = auth.userName ?? user.username;
            final achievements = _computeAchievements(
              user: user,
              tasksCompleted:
                  missions.completedCount + challenges.completedTotalCount,
            );
            final earned = achievements.where((a) => a.isUnlocked).length;
            final totalBadges = achievements.length;
            final nextLevelXp = XpConfig.totalXpForLevel(user.level + 1);
            final levelProgress =
                XpConfig.levelProgress(level: user.level, totalXp: user.xp);
            final daysOnJourney = DateTime.now()
                .difference(
                  DateTime(
                    user.joinDate.year,
                    user.joinDate.month,
                    user.joinDate.day,
                  ),
                )
                .inDays
                .clamp(0, 99999);
            final title = _levelTitle(user.level);
            final taskDone = (missions.completedCount +
                    challenges.completedTotalCount)
                .clamp(0, 9999);
            final taskTotal = missions.missions.length +
                ChallengeModel.getDefaultChallenges().length;
            final roadmapPct = taskTotal <= 0
                ? 0
                : ((taskDone / taskTotal) * 100).round().clamp(0, 100);

            final weekJournal = _weekDaysWithActivity(
                streak, StreakActivityType.journaling.name);
            final weekMind = _weekDaysWithActivity(
                streak, StreakActivityType.meditation.name);
            final weekMood = _weekDaysWithActivity(
              streak,
              StreakActivityType.assessment.name,
            );

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A2332),
                                Color(0xFF0B0D12),
                              ],
                            )
                          : LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _skyBlue.withValues(alpha: 0.38),
                                _sage.withValues(alpha: 0.14),
                                _bg,
                              ],
                            ),
                    ),
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            DrawerMenuButton(iconColor: onCard),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Settings',
                              onPressed: () => Navigator.of(context)
                                  .pushNamed('/notification-settings'),
                              icon: Icon(LucideIcons.settings, color: onCard),
                            ),
                            IconButton(
                              tooltip: 'Edit avatar',
                              onPressed: () =>
                                  Navigator.of(context).pushNamed('/avatar'),
                              icon: Icon(
                                LucideIcons.pencil,
                                color: _teal.withValues(alpha: 0.95),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _ProfileHeaderCard(
                          card: card,
                          isDark: isDark,
                          onCard: onCard,
                          subtle: subtle,
                          displayName: displayName,
                          user: user,
                          title: title,
                          avatar: avatar,
                          nextLevelXp: nextLevelXp,
                          levelProgress: levelProgress,
                          gold: _gold,
                          skyBlue: _skyBlue,
                          sage: _sage,
                          reduceMotion: reduceMotion,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _QuickStatsRow(
                          card: card,
                          isDark: isDark,
                          onCard: onCard,
                          subtle: subtle,
                          streak: streak.currentStreak,
                          dayText: '${daysOnJourney.clamp(0, 90)}/90',
                          badgesText: '$earned',
                          rank: user.rank,
                          onBadgesTap: () =>
                              Navigator.of(context).pushNamed('/badges'),
                        ),
                        const SizedBox(height: 16),
                        _TabBar(
                          selected: _tabIndex,
                          onChanged: (i) => setState(() => _tabIndex = i),
                          isDark: isDark,
                          onCard: onCard,
                          subtle: subtle,
                        ),
                        const SizedBox(height: 16),
                        if (_tabIndex == 0) ...[
                          _ThisWeekCard(
                            card: card,
                            isDark: isDark,
                            onCard: onCard,
                            subtle: subtle,
                            journal: weekJournal,
                            mindfulness: weekMind,
                            mood: weekMood,
                            taskFraction: '$taskDone/$taskTotal',
                            sage: _sage,
                            skyBlue: _skyBlue,
                            gold: _gold,
                            purple: const Color(0xFFB794F4),
                          ),
                          const SizedBox(height: 14),
                          _StreakHighlightCard(
                            card: card,
                            isDark: isDark,
                            onCard: onCard,
                            subtle: subtle,
                            streakDays: user.streakDays,
                            isAtRisk: streak.isStreakAtRisk,
                            hoursLeft: streak.hoursUntilStreakLoss,
                            nextMilestoneDays:
                                streak.nextMilestone?.daysRequired,
                            daysUntilNextMilestone:
                                streak.daysUntilNextMilestone,
                          ),
                          const SizedBox(height: 14),
                          _JourneyNumbersCard(
                            card: card,
                            isDark: isDark,
                            onCard: onCard,
                            subtle: subtle,
                            user: user,
                            streak: streak,
                            roadmapPct: roadmapPct,
                            taskDone: taskDone,
                            taskTotal: taskTotal,
                            journalEntryCount: journalCount,
                            teal: _teal,
                          ),
                          const SizedBox(height: 14),
                          _RecentMilestonesCard(
                            card: card,
                            isDark: isDark,
                            onCard: onCard,
                            subtle: subtle,
                            achievements: achievements,
                            streak: streak,
                            sage: _sage,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'EXPLORE',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                              color: subtle,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ProfileActionTile(
                            isDark: isDark,
                            card: card,
                            onCard: onCard,
                            subtle: subtle,
                            icon: LucideIcons.bookOpen,
                            iconBg: const Color(0xFFE8F8EF),
                            iconColor: _sage,
                            title: 'My journal entries',
                            subtitle: journalCount == 1
                                ? '1 entry written'
                                : '$journalCount entries written',
                            onTap: () => context
                                .read<NavigationModel>()
                                .setIndex(9),
                          ),
                          const SizedBox(height: 10),
                          _ProfileActionTile(
                            isDark: isDark,
                            card: card,
                            onCard: onCard,
                            subtle: subtle,
                            icon: LucideIcons.users,
                            iconBg: const Color(0xFFE8F1FE),
                            iconColor: const Color(0xFF3B82F6),
                            title: 'My support groups',
                            subtitle: 'Community & groups',
                            onTap: () => context
                                .read<NavigationModel>()
                                .setIndex(4),
                          ),
                          const SizedBox(height: 10),
                          _ProfileActionTile(
                            isDark: isDark,
                            card: card,
                            onCard: onCard,
                            subtle: subtle,
                            icon: LucideIcons.sparkles,
                            iconBg: const Color(0xFFFFF9DB),
                            iconColor: _gold,
                            title: 'Book a session',
                            subtitle: 'Human support when you need it',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Session booking opens from your care plan soon.',
                                    style: GoogleFonts.inter(),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: () => Navigator.of(context)
                                  .pushNamed('/achievements'),
                              icon: Icon(LucideIcons.trophy,
                                  size: 18, color: AppColors.purple),
                              label: Text(
                                'View all achievements',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.purple,
                                ),
                              ),
                            ),
                          ),
                        ] else if (_tabIndex == 1) ...[
                          _BadgesGrid(
                            card: card,
                            isDark: isDark,
                            onCard: onCard,
                            subtle: subtle,
                            earned: earned,
                            total: totalBadges,
                            achievements: achievements,
                            gold: _gold,
                          ),
                        ] else ...[
                          _LeaderboardCard(
                            card: card,
                            isDark: isDark,
                            onCard: onCard,
                            subtle: subtle,
                            displayName: displayName,
                            user: user,
                            earned: earned,
                            gold: _gold,
                            skyBlue: _skyBlue,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static String _levelTitle(int level) {
    if (level <= 5) return 'Base Camp Explorer';
    if (level <= 10) return 'Trail Navigator';
    if (level <= 20) return 'Mountain Guide';
    if (level <= 30) return 'Summit Seeker';
    return 'Peak Master';
  }

  static int _weekDaysWithActivity(StreakState streak, String activityName) {
    final now = DateTime.now();
    var count = 0;
    for (var i = 0; i < 7; i++) {
      final d = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final day = streak.getStreakDay(d);
      if (day != null &&
          day.isCompleted &&
          day.completedActivities.contains(activityName)) {
        count++;
      }
    }
    return count;
  }
}

List<Achievement> _computeAchievements({
  required UserModel user,
  required int tasksCompleted,
}) {
  int progressFor(Achievement a) {
    switch (a.type) {
      case AchievementType.focusStreak:
        return user.streakDays;
      case AchievementType.totalSessions:
        return user.totalSessions;
      case AchievementType.totalTime:
        return user.totalFocusMinutes;
      case AchievementType.level:
        return user.level;
      case AchievementType.special:
        return tasksCompleted;
    }
  }


  final all = Achievement.getDefaultAchievements()
      .map((a) {
        final p = progressFor(a);
        final unlocked = p >= a.requirement;
        return a.copyWith(
          currentProgress: p,
          isUnlocked: unlocked,
          unlockedAt: unlocked ? (a.unlockedAt ?? DateTime.now()) : null,
        );
      })
      .toList(growable: false);

  // Show a premium mix: prioritize unlocked, then highest progress.
  all.sort((a, b) {
    final au = a.isUnlocked ? 1 : 0;
    final bu = b.isUnlocked ? 1 : 0;
    if (au != bu) return bu - au;
    final ap = a.currentProgress ?? 0;
    final bp = b.currentProgress ?? 0;
    return bp.compareTo(ap);
  });

  return all;
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.card,
    required this.isDark,
    required this.onCard,
    required this.subtle,
    required this.displayName,
    required this.user,
    required this.title,
    required this.avatar,
    required this.nextLevelXp,
    required this.levelProgress,
    required this.gold,
    required this.skyBlue,
    required this.sage,
    required this.reduceMotion,
  });

  final Color card;
  final bool isDark;
  final Color onCard;
  final Color subtle;
  final String displayName;
  final UserModel user;
  final String title;
  final AvatarProvider avatar;
  final int nextLevelXp;
  final double levelProgress;
  final Color gold;
  final Color skyBlue;
  final Color sage;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final xpFmt = NumberFormat.decimalPattern();
    final barTween = reduceMotion ? 1.0 : levelProgress;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          AvatarDisplay(
            mood: avatar.mood,
            avatarAssetPath: avatar.selectedAvatarAsset,
            size: 100,
            onEditPressed: () => Navigator.of(context).pushNamed('/avatar'),
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: onCard,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gold, gold.withValues(alpha: 0.85)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'LVL ${user.level}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: subtle,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Level ${user.level} — $title',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: subtle.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(LucideIcons.zap, size: 18, color: gold),
              const SizedBox(width: 6),
              Text(
                '${xpFmt.format(user.xp)} XP',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: onCard,
                ),
              ),
              const Spacer(),
              Text(
                'Level ${user.level + 1} at ${xpFmt.format(nextLevelXp)} XP',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: barTween),
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFECECE8),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [sage, skyBlue],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${xpFmt.format(user.xp)} / ${xpFmt.format(nextLevelXp)} XP',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: subtle,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({
    required this.card,
    required this.isDark,
    required this.onCard,
    required this.subtle,
    required this.streak,
    required this.dayText,
    required this.badgesText,
    required this.rank,
    required this.onBadgesTap,
  });

  final Color card;
  final bool isDark;
  final Color onCard;
  final Color subtle;
  final int streak;
  final String dayText;
  final String badgesText;
  final int rank;
  final VoidCallback onBadgesTap;

  @override
  Widget build(BuildContext context) {
    Widget cell({
      required IconData icon,
      required Color iconColor,
      required String value,
      required String label,
      VoidCallback? onTap,
    }) {
      return Expanded(
        child: Semantics(
          label: '$label $value',
          button: onTap != null,
          child: Material(
            color: card,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(icon, color: iconColor, size: 22),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: onCard,
                      ),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: subtle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        cell(
          icon: LucideIcons.flame,
          iconColor: const Color(0xFFF97316),
          value: '$streak',
          label: 'Streak',
        ),
        const SizedBox(width: 10),
        cell(
          icon: LucideIcons.star,
          iconColor: _ProfileScreenState._gold,
          value: dayText,
          label: 'Day',
        ),
        const SizedBox(width: 10),
        cell(
          icon: LucideIcons.trophy,
          iconColor: const Color(0xFF9B7ED9),
          value: badgesText,
          label: 'Badges',
          onTap: onBadgesTap,
        ),
        const SizedBox(width: 10),
        cell(
          icon: LucideIcons.users,
          iconColor: const Color(0xFF3B82F6),
          value: '#$rank',
          label: 'Rank',
        ),
      ],
    );
  }
}

class _StreakHighlightCard extends StatelessWidget {
  const _StreakHighlightCard({
    required this.card,
    required this.isDark,
    required this.onCard,
    required this.subtle,
    required this.streakDays,
    required this.isAtRisk,
    required this.hoursLeft,
    required this.nextMilestoneDays,
    required this.daysUntilNextMilestone,
  });

  final Color card;
  final bool isDark;
  final Color onCard;
  final Color subtle;
  final int streakDays;
  final bool isAtRisk;
  final int hoursLeft;
  final int? nextMilestoneDays;
  final int daysUntilNextMilestone;

  @override
  Widget build(BuildContext context) {
    final next = nextMilestoneDays ?? 7;
    final progress = next <= 0 ? 0.0 : (streakDays / next).clamp(0.0, 1.0);
    final headline = isAtRisk
        ? 'Streak at risk'
        : streakDays == 0

        ? 'Start your streak'
        : 'Streak active';

    final sub = isAtRisk
        ? '$hoursLeft hours left today to save it'
        : streakDays == 0
        ? 'Complete one activity today'
        : '$daysUntilNextMilestone days to next milestone';

    return _ShadowCard(
      isDark: isDark,
      card: card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.flame,
                size: 20,
                color: isAtRisk ? const Color(0xFFF97316) : _ProfileScreenState._sage,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headline,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: onCard,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF7F7F4),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$streakDays days',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: onCard,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: GoogleFonts.inter(fontSize: 13, color: subtle),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: subtle.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                isAtRisk ? const Color(0xFFF97316) : _ProfileScreenState._sage,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Progress, not perfection — keep climbing.',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: subtle.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.isDark,
    required this.card,
    required this.onCard,
    required this.subtle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool isDark;
  final Color card;
  final Color onCard;
  final Color subtle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDark
                        ? iconColor.withValues(alpha: 0.2)
                        : iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: onCard,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: subtle,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: subtle, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.selected,
    required this.onChanged,
    required this.isDark,
    required this.onCard,
    required this.subtle,
  });

  final int selected;
  final ValueChanged<int> onChanged;
  final bool isDark;
  final Color onCard;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final track = isDark ? const Color(0xFF1E2329) : const Color(0xFFEEF1F4);
    final tabs = [
      (LucideIcons.clipboardList, 'Stats'),
      (LucideIcons.award, 'Badges'),
      (LucideIcons.trophy, 'Board'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final sel = selected == i;
          return Expanded(
            child: Semantics(
              selected: sel,
              button: true,
              label: tabs[i].$2,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel
                        ? (isDark ? const Color(0xFF2A3038) : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tabs[i].$1,
                        size: 16,
                        color: sel ? onCard : subtle,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tabs[i].$2,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? onCard : subtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ThisWeekCard extends StatelessWidget {
  const _ThisWeekCard({
    required this.card,
    required this.isDark,
    required this.onCard,
    required this.subtle,
    required this.journal,
    required this.mindfulness,
    required this.mood,
    required this.taskFraction,
    required this.sage,
    required this.skyBlue,
    required this.gold,
    required this.purple,
  });

  final Color card;
  final bool isDark;
  final Color onCard;
  final Color subtle;
  final int journal;
  final int mindfulness;
  final int mood;
  final String taskFraction;
  final Color sage;
  final Color skyBlue;
  final Color gold;
  final Color purple;

  @override
  Widget build(BuildContext context) {
    return _ShadowCard(
      isDark: isDark,
      card: card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS WEEK',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: subtle,
            ),
          ),
          const SizedBox(height: 14),
          _WeekRow(
            label: 'Journal entries',
            value: '$journal/7',
            frac: journal / 7,
            color: sage,
            onCard: onCard,
            subtle: subtle,
          ),
          const SizedBox(height: 12),
          _WeekRow(
            label: 'Mindfulness sessions',
            value: '$mindfulness/7',
            frac: mindfulness / 7,
            color: skyBlue,
            onCard: onCard,
            subtle: subtle,
          ),
          const SizedBox(height: 12),
          _WeekRow(
            label: 'Tasks completed',
            value: taskFraction,
            frac: _parseFraction(taskFraction),
            color: gold,
            onCard: onCard,
            subtle: subtle,
          ),
          const SizedBox(height: 12),
          _WeekRow(
            label: 'Mood check-ins',
            value: '$mood/7',
            frac: mood / 7,
            color: purple,
            onCard: onCard,
            subtle: subtle,
          ),
        ],
      ),
    );
  }

  static double _parseFraction(String s) {
    final parts = s.split('/');
    if (parts.length != 2) return 0;
    final a = int.tryParse(parts[0].trim()) ?? 0;
    final b = int.tryParse(parts[1].trim()) ?? 1;
    if (b <= 0) return 0;
    return (a / b).clamp(0.0, 1.0);
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.label,
    required this.value,
    required this.frac,
    required this.color,
    required this.onCard,
    required this.subtle,
  });

  final String label;
  final String value;
  final double frac;
  final Color color;
  final Color onCard;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: onCard,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: subtle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: frac.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: subtle.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _JourneyNumbersCard extends StatelessWidget {
  const _JourneyNumbersCard({
    required this.card,
    required this.isDark,
    required this.onCard,
    required this.subtle,
    required this.user,
    required this.streak,
    required this.roadmapPct,
    required this.taskDone,
    required this.taskTotal,
    required this.journalEntryCount,
    required this.teal,
  });

  final Color card;
  final bool isDark;
  final Color onCard;
  final Color subtle;
  final UserModel user;
  final StreakState streak;
  final int roadmapPct;
  final int taskDone;
  final int taskTotal;
  final int journalEntryCount;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    final xpFmt = NumberFormat.decimalPattern();
    final items = [
      (LucideIcons.bookOpen, '$journalEntryCount', 'Journal entries'),
      (LucideIcons.sparkles, '${user.totalSessions}', 'Sessions logged'),
      (LucideIcons.zap, xpFmt.format(user.xp), 'Total XP'),
      (LucideIcons.target, '$taskDone / $taskTotal', 'Roadmap tasks'),
      (LucideIcons.percent, '$roadmapPct%', 'Roadmap progress'),
      (LucideIcons.timer, '${user.totalFocusMinutes}', 'Focus minutes'),
      (LucideIcons.flame, '${streak.longestStreak}', 'Longest streak'),
    ];

    return _ShadowCard(
      isDark: isDark,
      card: card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [

              Icon(LucideIcons.trophy, size: 18, color: AppColors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your journey by the numbers',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: onCard,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: items
                .map(
                  (e) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: teal.withValues(alpha: 0.18),
                              ),
                              alignment: Alignment.center,
                              child: Icon(e.$1, size: 16, color: teal),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.$3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: onCard,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          e.$2,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: onCard,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RecentMilestonesCard extends StatelessWidget {
  const _RecentMilestonesCard({
    required this.card,
    required this.isDark,
    required this.onCard,
    required this.subtle,
    required this.achievements,
    required this.streak,
    required this.sage,
  });

  final Color card;
  final bool isDark;
  final Color onCard;
  final Color subtle;
  final List<Achievement> achievements;
  final StreakState streak;
  final Color sage;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.MMMd();
    final events = <_MilestoneEvent>[];

    for (final m in streak.milestones.where((m) => m.isUnlocked)) {
      if (m.unlockedAt != null) {
        events.add(
          _MilestoneEvent(
            icon: LucideIcons.award,
            title: m.title,
            subtitle: m.description,
            time: m.unlockedAt!,
          ),
        );
      }
    }
    for (final a in achievements.where((a) => a.isUnlocked)) {
      if (a.unlockedAt != null) {
        events.add(
          _MilestoneEvent(
            icon: LucideIcons.star,
            title: a.title,
            subtitle: a.description,
            time: a.unlockedAt!,
          ),
        );
      }
    }

    events.sort((a, b) => b.time.compareTo(a.time));
    final top = events.take(6).toList();

    return _ShadowCard(
      isDark: isDark,
      card: card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent milestones',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: onCard,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Newest first — every step counts on this journey.',
            style: GoogleFonts.inter(fontSize: 13, color: subtle),
          ),
          const SizedBox(height: 14),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(LucideIcons.mountainSnow, color: sage, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your journey is just beginning! Complete a task, journal, or join the community to see milestones here.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.35,
                        color: onCard,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...top.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MilestoneTile(
                  isDark: isDark,
                  onCard: onCard,
                  subtle: subtle,
                  icon: e.icon,
                  title: e.title,
                  subtitle: e.subtitle,
                  timeLabel: fmt.format(e.time),
                  sage: sage,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MilestoneEvent {
  _MilestoneEvent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime time;
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({
    required this.isDark,
    required this.onCard,
    required this.subtle,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.sage,
  });

  final bool isDark;
  final Color onCard;
  final Color subtle;
  final IconData icon;
  final String title;
  final String subtitle;
  final String timeLabel;
  final Color sage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF7F7F4),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: sage.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: sage, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: onCard,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.3,
                    color: subtle,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subtle.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgesGrid extends StatelessWidget {
  const _BadgesGrid({
    required this.card,
    required this.isDark,
    required this.onCard,
    required this.subtle,
    required this.earned,
    required this.total,
    required this.achievements,
    required this.gold,
  });

  final Color card;
  final bool isDark;
  final Color onCard;
  final Color subtle;
  final int earned;
  final int total;
  final List<Achievement> achievements;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your badges · $earned / $total earned',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: onCard,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: achievements.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, i) {
            final a = achievements[i];
            final locked = !a.isUnlocked;
            return Semantics(
              label: '${a.title}. ${locked ? "Locked" : "Earned"}',
              button: true,
              child: Material(
                color: card,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _showBadgeSheet(context, a, locked, isDark),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        if (!locked)
                          BoxShadow(
                            color: gold.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                      ],
                    ),
                    child: Opacity(
                      opacity: locked ? 0.45 : 1,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: a.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    a.icon,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  locked ? LucideIcons.lock : LucideIcons.check,
                                  size: 18,
                                  color: locked
                                      ? subtle
                                      : const Color(0xFF22C55E),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              a.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: onCard,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: subtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  static void _showBadgeSheet(
    BuildContext context,
    Achievement a,
    bool locked,
    bool isDark,
  ) {
    final secondary = isDark ? Colors.white70 : Colors.black54;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(ctx).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: secondary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(a.icon, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      a.title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                locked
                    ? 'Unlock: reach ${a.requirement} (${a.currentProgress ?? 0} so far).'
                    : 'You earned this badge. ${a.unlockedAt != null ? "Unlocked ${DateFormat.yMMMd().format(a.unlockedAt!)}" : ""}',
                style: GoogleFonts.inter(fontSize: 14, height: 1.35),
              ),
              const SizedBox(height: 12),
              Text(
                a.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: secondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({
    required this.card,
    required this.isDark,
    required this.onCard,
    required this.subtle,
    required this.displayName,
    required this.user,
    required this.earned,
    required this.gold,
    required this.skyBlue,
  });

  final Color card;
  final bool isDark;
  final Color onCard;
  final Color subtle;
  final String displayName;
  final UserModel user;
  final int earned;
  final Color gold;
  final Color skyBlue;

  @override
  Widget build(BuildContext context) {
    const totalTravelers = 1203;
    final podium = [
      ('River', 8120, 1),
      ('Maya', 7980, 2),
      ('Jordan', 7650, 3),
    ];

    return _ShadowCard(
      isDark: isDark,
      card: card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community ranking',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: onCard,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '#${user.rank} of $totalTravelers travelers',
            style: GoogleFonts.inter(fontSize: 14, color: subtle),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < podium.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _PodiumTile(
                    isDark: isDark,
                    name: podium[i].$1,
                    xp: podium[i].$2,
                    place: podium[i].$3,
                    gold: gold,
                    onCard: onCard,
                    subtle: subtle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: skyBlue.withValues(alpha: isDark ? 0.12 : 0.14),
              border: Border.all(
                color: skyBlue.withValues(alpha: 0.35),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Text(
                  '#${user.rank}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: onCard,
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: skyBlue.withValues(alpha: 0.35),
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      color: onCard,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: onCard,
                        ),
                      ),
                      Text(
                        'Lvl ${user.level} · $earned badges · ${NumberFormat.decimalPattern().format(user.xp)} XP',
                        style: GoogleFonts.inter(fontSize: 11, color: subtle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Full leaderboard lives in Community soon.',
                      style: GoogleFonts.inter(),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(
                'View full leaderboard',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: skyBlue.withValues(alpha: isDark ? 1 : 0.95),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumTile extends StatelessWidget {
  const _PodiumTile({
    required this.isDark,
    required this.name,
    required this.xp,
    required this.place,
    required this.gold,
    required this.onCard,
    required this.subtle,
  });

  final bool isDark;
  final String name;
  final int xp;
  final int place;
  final Color gold;
  final Color onCard;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final medal = place == 1
        ? gold
        : place == 2
            ? const Color(0xFFC0C0C0)
            : const Color(0xFFCD7F32);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF7F7F4),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.crown, size: 16, color: medal),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: onCard,
            ),
          ),
          Text(
            '${NumberFormat.compact().format(xp)} XP',
            style: GoogleFonts.inter(fontSize: 10, color: subtle),
          ),
        ],
      ),
    );
  }
}

class _ShadowCard extends StatelessWidget {
  const _ShadowCard({
    required this.isDark,
    required this.card,
    required this.child,
  });

  final bool isDark;
  final Color card;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
