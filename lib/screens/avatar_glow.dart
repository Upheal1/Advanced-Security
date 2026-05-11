import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AvatarGlow extends StatelessWidget {
  final String mood;
  final double size;
  final Widget child;

  const AvatarGlow({
    super.key,
    required this.mood,
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glowColor = _glowColorForMood(mood, theme);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            glowColor.withOpacity(0.45),
            glowColor.withOpacity(0.18),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.35),
            blurRadius: 36,
            spreadRadius: 6,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Color _glowColorForMood(String mood, ThemeData theme) {
    switch (mood) {
      case 'happy':
        return const Color(0xFF22C55E); // green
      case 'calm':
        return AppColors.purple;
      case 'stressed':
        return const Color(0xFFF97316); // orange
      default:
        return theme.colorScheme.primary;
    }
  }
}
