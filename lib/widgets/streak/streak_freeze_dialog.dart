import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/streak_model.dart';
import '../../constants/app_colors.dart';

/// A dialog for managing streak freeze tokens
class StreakFreezeDialog extends StatefulWidget {
  final StreakState streakState;
  final VoidCallback? onUseFreeze;
  final VoidCallback? onDismiss;

  const StreakFreezeDialog({
    super.key,
    required this.streakState,
    this.onUseFreeze,
    this.onDismiss,
  });

  @override
  State<StreakFreezeDialog> createState() => _StreakFreezeDialogState();

  /// Show the freeze dialog
  static Future<bool?> show(
    BuildContext context,
    StreakState streakState, {
    VoidCallback? onUseFreeze,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => StreakFreezeDialog(
        streakState: streakState,
        onUseFreeze: onUseFreeze,
        onDismiss: () => Navigator.of(context).pop(false),
      ),
    );
  }
}

class _StreakFreezeDialogState extends State<StreakFreezeDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isUsing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTokens = widget.streakState.freezeTokens > 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2196F3).withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated freeze icon
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2196F3).withOpacity(0.2),
                        const Color(0xFF03A9F4).withOpacity(0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2196F3).withOpacity(
                          0.2 + _controller.value * 0.2,
                        ),
                        blurRadius: 15 + _controller.value * 10,
                        spreadRadius: 2 + _controller.value * 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.snowflake,
                    color: Color(0xFF2196F3),
                    size: 40,
                  ),
                );
              },
            )
                .animate()
                .scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                )
                .then()
                .rotate(
                  begin: -0.02,
                  end: 0.02,
                  duration: 1500.ms,
                  curve: Curves.easeInOut,
                ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Streak Freeze',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              hasTokens
                  ? 'Protect your streak for one day! Use a freeze token to keep your streak alive when you can\'t complete activities.'
                  : 'You don\'t have any freeze tokens. Earn more by reaching milestones or completing weekly challenges!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Token count
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.textPrimary.withOpacity(0.05),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.snowflake,
                    color: Color(0xFF2196F3),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.streakState.freezeTokens}',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'tokens available',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // How to earn more section
            if (!hasTokens) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2196F3).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to earn freeze tokens:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildEarnMethod(
                      context,
                      isDark,
                      '7-day streak',
                      '+1 token',
                    ),
                    _buildEarnMethod(
                      context,
                      isDark,
                      '30-day streak',
                      '+2 tokens',
                    ),
                    _buildEarnMethod(
                      context,
                      isDark,
                      'Weekly challenge',
                      '+1 token',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onDismiss ?? () => Navigator.of(context).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.2)
                              : AppColors.textPrimary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: hasTokens && !_isUsing
                        ? () async {
                            setState(() => _isUsing = true);
                            widget.onUseFreeze?.call();
                            await Future.delayed(
                                const Duration(milliseconds: 500));
                            if (mounted) {
                              Navigator.of(context).pop(true);
                            }
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: hasTokens
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF2196F3),
                                  Color(0xFF03A9F4),
                                ],
                              )
                            : null,
                        color: hasTokens
                            ? null
                            : (isDark
                                ? Colors.white.withOpacity(0.1)
                                : AppColors.textPrimary.withOpacity(0.1)),
                      ),
                      child: Center(
                        child: _isUsing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.shield,
                                    size: 16,
                                    color: hasTokens
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white38
                                            : AppColors.textSecondary
                                                .withOpacity(0.5)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Use Freeze',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: hasTokens
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white38
                                              : AppColors.textSecondary
                                                  .withOpacity(0.5)),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().scale(
            begin: const Offset(0.9, 0.9),
            duration: 300.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildEarnMethod(
    BuildContext context,
    bool isDark,
    String method,
    String reward,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.checkCircle,
                size: 14,
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 8),
              Text(
                method,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            reward,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small freeze indicator widget for the streak screen
class StreakFreezeIndicator extends StatelessWidget {
  final int freezeTokens;
  final VoidCallback? onTap;

  const StreakFreezeIndicator({
    super.key,
    required this.freezeTokens,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF2196F3).withOpacity(0.2),
          border: Border.all(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.snowflake,
              color: Color(0xFF2196F3),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '$freezeTokens',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
