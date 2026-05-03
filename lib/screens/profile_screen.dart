import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/auth_model.dart';
import '../models/achievement.dart';
import '../models/mission_model.dart';
import '../models/streak_model.dart';
import '../models/user_model.dart';
import '../constants/app_colors.dart';
import '../services/challenge_service.dart';
import '../widgets/drawer_menu_button.dart';
import '../avatar/services/avatar_provider.dart';
import 'avatar_display.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0D12) : theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Consumer6<AuthModel, UserModel, AvatarProvider, StreakState,
            MissionsModel, ChallengeService>(
          builder: (context, authModel, userModel, avatarProvider, streakState,
              missionsModel, challengeService, _) {
            final tasksCompleted = missionsModel.completedCount +
                challengeService.completedTotalCount;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const DrawerMenuButton(iconColor: Colors.white),
                      const Spacer(),
                      IconButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/avatar'),
                        icon:
                            const Icon(LucideIcons.pencil, color: Colors.white),
                        tooltip: 'Edit avatar',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AvatarDisplay(
                    mood: avatarProvider.mood,
                    avatarAssetPath: avatarProvider.selectedAvatarAsset,
                    size: 170,
                    onEditPressed: () =>
                        Navigator.of(context).pushNamed('/avatar'),
                  ),
                  const SizedBox(height: 18),
                  _ProfileInfoCard(
                    username: authModel.userName ?? userModel.username,
                    level: userModel.level,
                    xp: userModel.xp,
                  ),
                  const SizedBox(height: 14),
                  _QuickStatsRow(
                    level: userModel.level,
                    xp: userModel.xp,
                    badges: userModel.badges,
                    rank: userModel.rank,
                    onBadgesTap: () =>
                        Navigator.of(context).pushNamed('/badges'),
                  ),
                  const SizedBox(height: 14),
                  _StreakProgressCard(
                    streakDays: userModel.streakDays,
                    isAtRisk: streakState.isStreakAtRisk,
                    hoursLeft: streakState.hoursUntilStreakLoss,
                    nextMilestoneDays: streakState.nextMilestone?.daysRequired,
                    daysUntilNextMilestone: streakState.daysUntilNextMilestone,
                  ),
                  const SizedBox(height: 14),
                  _AchievementsPreviewCard(
                    achievements: _computeAchievementsPreview(
                      user: userModel,
                      tasksCompleted: tasksCompleted,
                    ),
                    onViewAll: () =>
                        Navigator.of(context).pushNamed('/achievements'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

List<Achievement> _computeAchievementsPreview({
  required UserModel user,
  required int tasksCompleted,
}) {
  // Lightweight "preview" progress mapping (no persistence yet).
  // If you later add an AchievementsProvider, this can be replaced by that.
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
        // Map special to "tasks completed" as a motivating proxy for now.
        return tasksCompleted;
    }
  }

  final all = Achievement.getDefaultAchievements().map((a) {
    final p = progressFor(a);
    final unlocked = p >= a.requirement;
    return a.copyWith(
      currentProgress: p,
      isUnlocked: unlocked,
      unlockedAt: unlocked ? (a.unlockedAt ?? DateTime.now()) : null,
    );
  }).toList(growable: false);

  // Show a premium mix: prioritize unlocked, then highest progress.
  all.sort((a, b) {
    final au = a.isUnlocked ? 1 : 0;
    final bu = b.isUnlocked ? 1 : 0;
    if (au != bu) return bu - au;
    final ap = a.currentProgress ?? 0;
    final bp = b.currentProgress ?? 0;
    return bp.compareTo(ap);
  });

  return all.take(4).toList(growable: false);
}

class _ProfileInfoCard extends StatelessWidget {
  final String username;
  final int level;
  final int xp;

  const _ProfileInfoCard({
    required this.username,
    required this.level,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            username,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _Pill(
                icon: LucideIcons.trophy,
                label: 'Level $level',
              ),
              const SizedBox(width: 10),
              _Pill(
                icon: LucideIcons.zap,
                label: '$xp XP',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final int level;
  final int xp;
  final int badges;
  final int rank;
  final VoidCallback onBadgesTap;

  const _QuickStatsRow({
    required this.level,
    required this.xp,
    required this.badges,
    required this.rank,
    required this.onBadgesTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Level',
            value: '$level',
            icon: LucideIcons.trophy,
            tint: AppColors.purple,
            surface: theme.colorScheme.surface,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'XP',
            value: '$xp',
            icon: LucideIcons.zap,
            tint: const Color(0xFF22C55E),
            surface: theme.colorScheme.surface,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: onBadgesTap,
            child: _StatCard(
              title: 'Badges',
              value: '$badges',
              icon: LucideIcons.award,
              tint: const Color(0xFFFFD700),
              surface: theme.colorScheme.surface,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Rank',
            value: '#$rank',
            icon: LucideIcons.barChart3,
            tint: const Color(0xFFF97316),
            surface: theme.colorScheme.surface,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.purple),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color tint;
  final Color surface;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.tint,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: tint),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StreakProgressCard extends StatelessWidget {
  final int streakDays;
  final bool isAtRisk;
  final int hoursLeft;
  final int? nextMilestoneDays;
  final int daysUntilNextMilestone;

  const _StreakProgressCard({
    required this.streakDays,
    required this.isAtRisk,
    required this.hoursLeft,
    required this.nextMilestoneDays,
    required this.daysUntilNextMilestone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = nextMilestoneDays ?? 7;
    final progress = next <= 0 ? 0.0 : (streakDays / next).clamp(0.0, 1.0);

    final headline = isAtRisk
        ? 'Streak at risk'
        : streakDays == 0
            ? 'Start your streak'
            : 'Streak active';

    final sub = isAtRisk
        ? '$hoursLeft hours left to save it'
        : streakDays == 0
            ? 'Complete one activity today'
            : '$daysUntilNextMilestone days to next milestone';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.flame,
                size: 18,
                color: isAtRisk ? const Color(0xFFF97316) : AppColors.purple,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headline,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Text(
                  '$streakDays days',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.10),
              valueColor: AlwaysStoppedAnimation<Color>(
                isAtRisk ? const Color(0xFFF97316) : AppColors.purple,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Next milestone: $next days',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsPreviewCard extends StatelessWidget {
  final List<Achievement> achievements;
  final VoidCallback onViewAll;

  const _AchievementsPreviewCard({
    required this.achievements,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.trophy,
                size: 18,
                color: AppColors.purple,
              ),
              const SizedBox(width: 8),
              Text(
                'Achievements',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'View all',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final a = achievements[index];
                final progress = a.progress;
                final locked = !a.isUnlocked;
                return Container(
                  width: 150,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.colorScheme.surface.withOpacity(0.55),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: a.isUnlocked
                        ? [
                            BoxShadow(
                              color: AppColors.purple.withOpacity(0.22),
                              blurRadius: 16,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 10),
                            ),
                          ],
                  ),
                  child: Opacity(
                    opacity: locked ? 0.6 : 1,
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
                                color: a.color.withOpacity(0.18),
                              ),
                              alignment: Alignment.center,
                              child: Text(a.icon,
                                  style: const TextStyle(fontSize: 16)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                a.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: locked ? progress : 1,
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.10),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              locked
                                  ? a.color.withOpacity(0.85)
                                  : AppColors.purple,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          locked
                              ? '${a.currentProgress ?? 0}/${a.requirement}'
                              : 'Unlocked',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: locked
                                ? theme.colorScheme.onSurface.withOpacity(0.65)
                                : AppColors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
