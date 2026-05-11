import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

/// Overlay that shows a brief, non-blocking XP burst animation.
///
/// Usage:
///   XpBurstOverlay.show(
///     context,
///     amount: 30,
///     oldXp: 120,
///     newXp: 150,
///     xpNeeded: 40,
///     level: 3,
///   );
class XpBurstOverlay extends StatefulWidget {
  final int amount;
  final int oldXp;
  final int newXp;
  final int xpNeeded;
  final int level;

  const XpBurstOverlay({
    super.key,
    required this.amount,
    required this.oldXp,
    required this.newXp,
    required this.xpNeeded,
    required this.level,
  });

  static void show(
    BuildContext context, {
    required int amount,
    required int oldXp,
    required int newXp,
    required int xpNeeded,
    required int level,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      // Called from a context without an Overlay (e.g. above MaterialApp.builder).
      return;
    }
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => XpBurstOverlay(
        amount: amount,
        oldXp: oldXp,
        newXp: newXp,
        xpNeeded: xpNeeded,
        level: level,
      ),
    );

    overlay.insert(entry);

    // Auto-remove after animation completes.
    Timer(const Duration(milliseconds: 1800), () {
      entry.remove();
    });
  }

  @override
  State<XpBurstOverlay> createState() => _XpBurstOverlayState();
}

class _XpBurstOverlayState extends State<XpBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Offset> _tagPositions;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    // Three semi-random positions across the screen.
    _tagPositions = List.generate(3, (index) {
      final dx = 0.2 + _random.nextDouble() * 0.6;
      final dy = 0.2 + index * 0.15 + _random.nextDouble() * 0.05;
      return Offset(dx, dy);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _oldProgress {
    final totalForNext = widget.newXp + widget.xpNeeded;
    if (totalForNext <= 0) return 0;
    return widget.oldXp / totalForNext;
  }

  double get _newProgress {
    final totalForNext = widget.newXp + widget.xpNeeded;
    if (totalForNext <= 0) return 0;
    return widget.newXp / totalForNext;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return IgnorePointer(
      child: Stack(
        children: [
          // Floating XP tags
          ...List.generate(_tagPositions.length, (index) {
            final pos = _tagPositions[index];
            return Positioned(
              left: pos.dx * size.width,
              top: pos.dy * size.height,
              child: _XpTag(amount: widget.amount),
            );
          }),
          // XP bar near bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: _AnimatedXpBar(
              controller: _controller,
              oldProgress: _oldProgress.clamp(0.0, 1.0),
              newProgress: _newProgress.clamp(0.0, 1.0),
              level: widget.level,
              currentXp: widget.newXp,
              xpNeeded: widget.xpNeeded,
            ),
          ),
        ],
      ),
    );
  }
}

class _XpTag extends StatelessWidget {
  final int amount;

  const _XpTag({required this.amount});

  @override
  Widget build(BuildContext context) {
    final text = '+$amount XP';

    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: Colors.black54,
            blurRadius: 8,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .then()
        .slideY(begin: 0, end: -0.8, duration: 800.ms, curve: Curves.easeOut)
        .fadeOut(duration: 400.ms);
  }
}

class _AnimatedXpBar extends StatelessWidget {
  final AnimationController controller;
  final double oldProgress;
  final double newProgress;
  final int level;
  final int currentXp;
  final int xpNeeded;

  const _AnimatedXpBar({
    required this.controller,
    required this.oldProgress,
    required this.newProgress,
    required this.level,
    required this.currentXp,
    required this.xpNeeded,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Level $level',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Animate(
          controller: controller,
          effects: const [],
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: oldProgress, end: newProgress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return _buildBar(context, value);
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$currentXp XP • ${xpNeeded.clamp(0, 1 << 31)} XP to next level',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBar(BuildContext context, double progress) {
    final clamped = progress.clamp(0.0, 1.0);

    final bar = Container(
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.15),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clamped,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFF7F77DD),
            ),
          ),
        ),
      ),
    );

    // Once the bar is filled, apply a subtle shimmer sweep.
    return clamped >= 1.0
        ? Shimmer.fromColors(
            baseColor: const Color(0xFF7F77DD),
            highlightColor: const Color(0xFFB4AFFF),
            child: bar,
          )
        : bar;
  }
}
