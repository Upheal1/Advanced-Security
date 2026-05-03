import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../constants/app_colors.dart';
import '../../models/challenge_model.dart';

class ChallengeCard extends StatefulWidget {
  final ChallengeModel challenge;
  final VoidCallback onPrimaryAction;
  final bool showConfetti;
  final ConfettiController? confettiController;

  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.onPrimaryAction,
    this.showConfetti = false,
    this.confettiController,
  });

  @override
  State<ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<ChallengeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.challenge;
    final onSurface = theme.colorScheme.onSurface;

    final isCompleted = c.status == ChallengeStatus.completed;
    final isActive = c.status == ChallengeStatus.active && !c.isExpired;
    final isExpired = c.isExpired || c.status == ChallengeStatus.expired;

    final accent = isCompleted
        ? const Color(0xFF1D9E75)
        : isExpired
            ? theme.colorScheme.onSurface.withOpacity(0.35)
            : c.difficultyColor;

    final ctaLabel = isCompleted
        ? 'Completed'
        : isExpired
            ? 'Expired'
            : isActive
                ? 'Continue'
                : 'Start';

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.98 : 1,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          if (isExpired || isCompleted) return;
          widget.onPrimaryAction();
        },
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surface.withOpacity(0.55),
                    theme.colorScheme.surface.withOpacity(0.25),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(isActive ? 0.14 : 0.08),
                  width: isActive ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withOpacity(0.16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          c.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: onSurface.withOpacity(0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RewardPill(xp: c.xpReward),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: c.targetCount == 0 ? 0 : c.progress,
                      minHeight: 9,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MetaPill(
                        icon: LucideIcons.users,
                        label: '${c.participantCount} joined',
                      ),
                      const SizedBox(width: 8),
                      _MetaPill(
                        icon: LucideIcons.timer,
                        label: c.timeLeftLabel,
                      ),
                      const Spacer(),
                      _CtaButton(
                        label: ctaLabel,
                        enabled: !isExpired && !isCompleted,
                        accent: accent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.showConfetti && widget.confettiController != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: ConfettiWidget(
                    confettiController: widget.confettiController!,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    emissionFrequency: 0.0,
                    numberOfParticles: 24,
                    gravity: 0.35,
                    colors: const [
                      Color(0xFF7F77DD),
                      Color(0xFF22C55E),
                      Color(0xFFF97316),
                      Color(0xFFFFD700),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.04, end: 0);
  }
}

class _RewardPill extends StatelessWidget {
  final int xp;

  const _RewardPill({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            AppColors.purple.withOpacity(0.95),
            const Color(0xFFB4AFFF).withOpacity(0.75),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        '+$xp XP',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surface.withOpacity(0.35),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14, color: theme.colorScheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final Color accent;

  const _CtaButton({
    required this.label,
    required this.enabled,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = enabled
        ? LinearGradient(
            colors: [
              accent.withOpacity(0.95),
              AppColors.purple.withOpacity(0.90),
            ],
          )
        : LinearGradient(
            colors: [
              theme.colorScheme.onSurface.withOpacity(0.20),
              theme.colorScheme.onSurface.withOpacity(0.10),
            ],
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: bg,
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ]
            : const [],
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
