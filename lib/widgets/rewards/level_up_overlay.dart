import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Full-screen level up celebration overlay.
///
/// Usage:
///   LevelUpOverlay.show(
///     context,
///     newLevel: 4,
///     title: 'Focus Warrior',
///   );
class LevelUpOverlay extends StatefulWidget {
  final int newLevel;
  final String title;

  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.title,
  });

  static Future<void> show(
    BuildContext context, {
    required int newLevel,
    required String title,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Level up',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return LevelUpOverlay(
          newLevel: newLevel,
          title: title,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2))
      ..play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newLevel = widget.newLevel;
    final title = widget.title;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge + rings
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _ExpandingRing(delayMs: 0),
                        _ExpandingRing(delayMs: 150),
                        _ExpandingRing(delayMs: 300),
                        _LevelBadge(newLevel: newLevel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title text
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 300.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                  const SizedBox(height: 8),

                  Text(
                    'Level $newLevel unlocked',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 300.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                ],
              ),
            ),
          ),

          // Dismiss button at bottom
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: SafeArea(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7F77DD),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                child: const Text(
                  "Let's go →",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.04,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 5,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int newLevel;

  const _LevelBadge({required this.newLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        color: Color(0xFF7F77DD),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$newLevel',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w600,
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1.2, 1.2),
          duration: 300.ms,
          curve: Curves.easeOutBack,
        )
        .then()
        .scale(
          begin: const Offset(1.2, 1.2),
          end: const Offset(1.0, 1.0),
          duration: 200.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _ExpandingRing extends StatelessWidget {
  final int delayMs;

  const _ExpandingRing({required this.delayMs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 2,
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          delay: delayMs.ms,
          begin: const Offset(1, 1),
          end: const Offset(2.5, 2.5),
          duration: 1200.ms,
          curve: Curves.easeOut,
        )
        .fadeOut(
          delay: (delayMs + 200).ms,
          duration: 800.ms,
        );
  }
}

