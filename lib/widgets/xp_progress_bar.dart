import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_colors.dart';

class XPProgressBar extends StatelessWidget {
  final int currentXP;
  final int levelXP;
  final int level;
  final bool animateOnBuild;

  const XPProgressBar({
    Key? key,
    required this.currentXP,
    required this.levelXP,
    required this.level,
    this.animateOnBuild = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final safeLevelXp = levelXP <= 0 ? 1 : levelXP;
    final rawProgress = currentXP / safeLevelXp;
    final progress = rawProgress.clamp(0.0, 1.0);

    Widget barBuilder(double value) {
      final barValue = value.clamp(0.0, 1.0);
      final base = LinearProgressIndicator(
        value: barValue,
        backgroundColor: Colors.grey.withOpacity(0.2),
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
      );

      // When animation reaches its target, apply a subtle one-off shimmer.
      if (animateOnBuild && (barValue - progress).abs() < 0.01) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFF7F77DD),
          highlightColor: const Color(0xFFB4AFFF),
          period: const Duration(milliseconds: 800),
          child: base,
        );
      }
      return base;
    }

    Widget bar;
    if (!animateOnBuild) {
      bar = barBuilder(progress);
    } else {
      bar = Animate(
        effects: [
          CustomEffect(
            duration: 600.ms,
            curve: Curves.easeOut,
            begin: 0.0,
            end: progress,
            builder: (context, value, child) {
              final v = (value as double?) ?? 0.0;
              return barBuilder(v);
            },
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $level',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$currentXP / $levelXP XP',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          bar,
        ],
      ),
    );
  }
}
