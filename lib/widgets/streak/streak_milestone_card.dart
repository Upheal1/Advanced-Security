import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/streak_model.dart';
import '../../constants/app_colors.dart';

/// A beautiful card widget for displaying streak milestones
class StreakMilestoneCard extends StatelessWidget {
  final StreakMilestone milestone;
  final int currentStreak;
  final VoidCallback? onTap;
  final bool animate;

  const StreakMilestoneCard({
    super.key,
    required this.milestone,
    required this.currentStreak,
    this.onTap,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnlocked = currentStreak >= milestone.daysRequired;
    final progress = (currentStreak / milestone.daysRequired).clamp(0.0, 1.0);

    Widget card = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUnlocked
                ? [
                    const Color(0xFFFF6B35).withOpacity(0.3),
                    const Color(0xFFFF8C42).withOpacity(0.15),
                  ]
                : isDark
                    ? [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.04),
                      ]
                    : [
                        AppColors.textPrimary.withOpacity(0.05),
                        AppColors.textPrimary.withOpacity(0.02),
                      ],
          ),
          border: Border.all(
            color: isUnlocked
                ? const Color(0xFFFF6B35).withOpacity(0.5)
                : isDark
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.textPrimary.withOpacity(0.1),
            width: isUnlocked ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Emoji/Icon container
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlocked
                        ? const Color(0xFFFF6B35).withOpacity(0.2)
                        : isDark
                            ? Colors.white.withOpacity(0.1)
                            : AppColors.textPrimary.withOpacity(0.1),
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      milestone.emoji,
                      style: TextStyle(
                        fontSize: 24,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Title and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              milestone.title,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked
                                    ? (isDark
                                        ? Colors.white
                                        : AppColors.textPrimary)
                                    : (isDark
                                        ? Colors.white54
                                        : AppColors.textSecondary),
                              ),
                            ),
                          ),
                          if (isUnlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFF4CAF50),
                              ),
                              child: Text(
                                '✓',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        milestone.description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Background
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : AppColors.textPrimary.withOpacity(0.1),
                        ),
                      ),
                      // Progress fill
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF6B35),
                                Color(0xFFFF8C42),
                              ],
                            ),
                            boxShadow: isUnlocked
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF6B35)
                                          .withOpacity(0.5),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Progress text
                Text(
                  isUnlocked
                      ? '${milestone.daysRequired}/${milestone.daysRequired}'
                      : '$currentStreak/${milestone.daysRequired}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // XP Reward
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '${milestone.xpReward} XP Reward',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                  ],
                ),
                if (!isUnlocked)
                  Text(
                    '${milestone.daysRequired - currentStreak} days left',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    if (animate) {
      card = card
          .animate()
          .fadeIn(duration: 400.ms)
          .slideX(begin: 0.1, end: 0, duration: 400.ms);
    }

    return card;
  }
}

/// A horizontal scrollable list of milestone cards
class StreakMilestonesList extends StatelessWidget {
  final List<StreakMilestone> milestones;
  final int currentStreak;
  final Function(StreakMilestone)? onMilestoneTap;

  const StreakMilestonesList({
    super.key,
    required this.milestones,
    required this.currentStreak,
    this.onMilestoneTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '🏆',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'Milestones',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: milestones.length,
            itemBuilder: (context, index) {
              final milestone = milestones[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < milestones.length - 1 ? 16 : 0,
                ),
                child: SizedBox(
                  width: 280,
                  child: StreakMilestoneCard(
                    milestone: milestone,
                    currentStreak: currentStreak,
                    onTap: () => onMilestoneTap?.call(milestone),
                    animate: false,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
