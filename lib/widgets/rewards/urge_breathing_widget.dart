import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../services/reward_orchestrator.dart';

/// Full-screen in-page urge resistance tool.
///
/// This is intentionally not an overlay entry: it's a full widget screen that
/// you can push like a normal page.
class UrgeBreathingWidget extends StatefulWidget {
  const UrgeBreathingWidget({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const UrgeBreathingWidget(),
      ),
    );
  }

  @override
  State<UrgeBreathingWidget> createState() => _UrgeBreathingWidgetState();
}

class _UrgeBreathingWidgetState extends State<UrgeBreathingWidget>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _onComplete();
        }
      });
    _ringController.forward();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  int get _secondsRemaining {
    final remaining = (60 * (1 - _ringController.value)).ceil();
    return remaining.clamp(0, 60);
  }

  Future<void> _onComplete() async {
    if (!mounted || _completed) return;
    setState(() => _completed = true);

    // Queue reward event (domain-side). No XP logic changes here.
    context.read<RewardOrchestrator>().queueReward(
          const UrgeResisted(secondsHeld: 60),
        );

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  void _skip() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 12,
              right: 12,
              child: TextButton(
                onPressed: _skip,
                child: const Text(
                  'Skip',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _ringController,
                builder: (context, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Progress ring
                          CustomPaint(
                            size: const Size(140, 140),
                            painter: _RingPainter(
                              progress: _ringController.value,
                              color: const Color(0xFF1D9E75),
                            ),
                          ),
                          // Pulsing circle
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE1F5EE),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Breathe',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat())
                              .scale(
                                duration: 4000.ms,
                                begin: const Offset(1.0, 1.0),
                                end: const Offset(1.2, 1.2),
                                curve: Curves.easeInOut,
                              )
                              .then()
                              .scale(
                                duration: 4000.ms,
                                begin: const Offset(1.2, 1.2),
                                end: const Offset(1.0, 1.0),
                                curve: Curves.easeInOut,
                              ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (!_completed) ...[
                        Text(
                          '$_secondsRemaining',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Urge resisted. +25 XP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 250.ms)
                            .scale(
                              begin: const Offset(0.96, 0.96),
                              end: const Offset(1.0, 1.0),
                              duration: 250.ms,
                              curve: Curves.easeOut,
                            ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;

  const _RingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const start = -pi / 2;
    final sweep = 2 * pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(rect, start, sweep, false, stroke);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

