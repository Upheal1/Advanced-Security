import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/streak_model.dart';
import '../../constants/app_colors.dart';

/// A beautiful stats card widget for displaying streak statistics
class StreakStatsCard extends StatelessWidget {
  final StreakState streakState;
  final bool showMultiplier;
  final bool animate;

  const StreakStatsCard({
    super.key,
    required this.streakState,
    this.showMultiplier = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ]
              : [
                  AppColors.textPrimary.withOpacity(0.05),
                  AppColors.textPrimary.withOpacity(0.02),
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : AppColors.textPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.barChart3,
                color: isDark ? Colors.white : AppColors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Streak Statistics',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Current',
                  '${streakState.currentStreak}',
                  LucideIcons.flame,
                  const Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Best',
                  '${streakState.longestStreak}',
                  LucideIcons.trophy,
                  const Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Active Days',
                  '${streakState.totalDaysActive}',
                  LucideIcons.calendar,
                  const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Freezes',
                  '${streakState.freezeTokens}',
                  LucideIcons.snowflake,
                  const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          if (showMultiplier) ...[
            const SizedBox(height: 20),
            _buildMultiplierSection(context, isDark),
          ],
        ],
      ),
    );

    if (animate) {
      card = card
          .animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.1, end: 0, duration: 400.ms);
    }

    return card;
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : AppColors.surface,
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : AppColors.textPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplierSection(BuildContext context, bool isDark) {
    final multiplier = streakState.streakMultiplier;
    final nextMultiplierStreak = _getNextMultiplierStreak(streakState.currentStreak);
    final progress = nextMultiplierStreak > 0
        ? (streakState.currentStreak % nextMultiplierStreak) / nextMultiplierStreak
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35).withOpacity(0.2),
            const Color(0xFFFF8C42).withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFF6B35).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'XP Multiplier',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF6B35),
                      Color(0xFFFF8C42),
                    ],
                  ),
                ),
                child: Text(
                  '${multiplier.toStringAsFixed(1)}x',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (multiplier < 5.0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : AppColors.textPrimary.withOpacity(0.1),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF6B35),
                                Color(0xFFFF8C42),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Next: ${_getNextMultiplier(multiplier).toStringAsFixed(1)}x',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              '🎉 Maximum multiplier achieved!',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFFFD700),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _getNextMultiplierStreak(int currentStreak) {
    if (currentStreak < 7) return 7;
    if (currentStreak < 14) return 14;
    if (currentStreak < 30) return 30;
    if (currentStreak < 90) return 90;
    return 0;
  }

  double _getNextMultiplier(double current) {
    if (current < 1.5) return 1.5;
    if (current < 2.0) return 2.0;
    if (current < 3.0) return 3.0;
    if (current < 5.0) return 5.0;
    return 5.0;
  }
}

/// A compact version of the streak stats for dashboard use
class StreakStatsCompact extends StatelessWidget {
  final StreakState streakState;
  final VoidCallback? onTap;

  const StreakStatsCompact({
    super.key,
    required this.streakState,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF6B35).withOpacity(0.2),
              const Color(0xFFFF8C42).withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.flame,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${streakState.currentStreak} Day Streak',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${streakState.streakMultiplier.toStringAsFixed(1)}x XP Multiplier',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFFF6B35),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
