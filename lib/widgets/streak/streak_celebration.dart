import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/streak_model.dart';

/// A beautiful confetti celebration overlay for milestone achievements
class StreakCelebration extends StatefulWidget {
  final StreakMilestone milestone;
  final VoidCallback? onDismiss;
  final bool showConfetti;

  const StreakCelebration({
    super.key,
    required this.milestone,
    this.onDismiss,
    this.showConfetti = true,
  });

  @override
  State<StreakCelebration> createState() => _StreakCelebrationState();

  /// Show the celebration as a dialog
  static Future<void> show(BuildContext context, StreakMilestone milestone) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Celebration',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StreakCelebration(
          milestone: milestone,
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}

class _StreakCelebrationState extends State<StreakCelebration>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _glowController;
  final List<_Confetti> _confettiPieces = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    if (widget.showConfetti) {
      _generateConfetti();
      _confettiController.forward();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _generateConfetti() {
    for (int i = 0; i < 100; i++) {
      _confettiPieces.add(_Confetti(
        x: _random.nextDouble(),
        y: _random.nextDouble() * -1,
        size: _random.nextDouble() * 10 + 5,
        color: _getRandomColor(),
        rotation: _random.nextDouble() * 360,
        speed: _random.nextDouble() * 200 + 100,
        wobble: _random.nextDouble() * 30 - 15,
      ));
    }
  }

  Color _getRandomColor() {
    final colors = [
      const Color(0xFFFF6B35),
      const Color(0xFFFF8C42),
      const Color(0xFFFFD700),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      Colors.white,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Confetti layer
          if (widget.showConfetti)
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    confetti: _confettiPieces,
                    progress: _confettiController.value,
                  ),
                  size: MediaQuery.of(context).size,
                );
              },
            ),

          // Celebration card
          Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[900]!,
                    Colors.grey[850]!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated emoji
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withOpacity(
                                0.2 + _glowController.value * 0.3,
                              ),
                              blurRadius: 20 + _glowController.value * 20,
                              spreadRadius: 5 + _glowController.value * 10,
                            ),
                          ],
                        ),
                        child: Text(
                          widget.milestone.emoji,
                          style: const TextStyle(fontSize: 64),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      )
                      .then()
                      .shimmer(duration: 2000.ms),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'MILESTONE UNLOCKED!',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: const Color(0xFFFF6B35),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                  const SizedBox(height: 12),

                  // Milestone title
                  Text(
                    widget.milestone.title,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    widget.milestone.description,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 24),

                  // XP Reward
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF6B35),
                          Color(0xFFFF8C42),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          '+${widget.milestone.xpReward} XP',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms)
                      .scale(begin: const Offset(0.8, 0.8))
                      .then()
                      .shimmer(delay: 500.ms, duration: 1500.ms),

                  const SizedBox(height: 32),

                  // Dismiss button
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'AWESOME!',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Confetti {
  double x;
  double y;
  final double size;
  final Color color;
  double rotation;
  final double speed;
  final double wobble;

  _Confetti({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.rotation,
    required this.speed,
    required this.wobble,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confetti;
  final double progress;

  _ConfettiPainter({
    required this.confetti,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in confetti) {
      final currentY = piece.y + (progress * piece.speed / 100);
      if (currentY > 1.2) continue;

      final currentX = piece.x + sin(currentY * 10) * (piece.wobble / 100);
      final currentRotation = piece.rotation + progress * 360;

      final paint = Paint()
        ..color = piece.color.withOpacity(1 - progress * 0.5)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX * size.width, currentY * size.height);
      canvas.rotate(currentRotation * pi / 180);

      // Draw rectangle confetti
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: piece.size,
        height: piece.size * 0.6,
      );
      canvas.drawRect(rect, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
