import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BadgeUnlockOverlay {
  static Future<void> show(
    BuildContext context, {
    required String badgeId,
    required String badgeName,
    required String emoji,
    String description = 'You earned this by showing up for yourself.',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _BadgeUnlockDialog(
          badgeId: badgeId,
          badgeName: badgeName,
          emoji: emoji,
          description: description,
        );
      },
    );
  }
}

class _BadgeUnlockDialog extends StatefulWidget {
  final String badgeId;
  final String badgeName;
  final String emoji;
  final String description;

  const _BadgeUnlockDialog({
    required this.badgeId,
    required this.badgeName,
    required this.emoji,
    required this.description,
  });

  @override
  State<_BadgeUnlockDialog> createState() => _BadgeUnlockDialogState();
}

class _BadgeUnlockDialogState extends State<_BadgeUnlockDialog> {
  bool _showSparkles = false;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1200),
    )..play();
    Future.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      setState(() {
        _showSparkles = true;
      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 280,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    emissionFrequency: 0.04,
                    numberOfParticles: 18,
                    gravity: 0.28,
                    colors: const [
                      Color(0xFF7F77DD),
                      Color(0xFF22C55E),
                      Color(0xFFF97316),
                      Color(0xFFFFD700),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7F77DD).withOpacity(0.25),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'NEW BADGE UNLOCKED',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.6,
                        color: theme.colorScheme.onSurface.withOpacity(0.65),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        _BadgeIcon(emoji: widget.emoji),
                        if (_showSparkles) _SparkleBurst(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.badgeName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7F77DD),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Claim',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 240.ms,
          curve: Curves.easeOutBack),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final String emoji;

  const _BadgeIcon({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF7F77DD),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 32),
      ),
    ).animate().flipV(
          duration: 300.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _SparkleBurst extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const directions = [
      Offset(0, -1),
      Offset(0.7, -0.7),
      Offset(1, 0),
      Offset(0.7, 0.7),
      Offset(0, 1),
      Offset(-0.7, 0.7),
      Offset(-1, 0),
      Offset(-0.7, -0.7),
    ];

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(8, (i) {
          final dir = directions[i];
          final distance = 44.0;

          return _SparkleDot(
            delayMs: 20 * i,
            offset: Offset(dir.dx * distance, dir.dy * distance),
          );
        }),
      ),
    );
  }
}

class _SparkleDot extends StatelessWidget {
  final int delayMs;
  final Offset offset;

  const _SparkleDot({
    required this.delayMs,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    final base = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1D9E75).withOpacity(0.9),
      ),
    );

    return Transform.translate(
      offset: offset,
      child: base
          .animate(delay: Duration(milliseconds: delayMs))
          .scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
            duration: 140.ms,
            curve: Curves.easeOut,
          )
          .then()
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(0, 0),
            duration: 220.ms,
            curve: Curves.easeIn,
          ),
    );
  }
}
