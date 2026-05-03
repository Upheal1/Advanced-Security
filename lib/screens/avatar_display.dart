import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../avatar/models/avatar_config.dart';
import '../avatar/ui/avatar_widget.dart';
import '../constants/app_colors.dart';
import 'avatar_glow.dart';

class AvatarDisplay extends StatefulWidget {
  final String mood;
  final String avatarAssetPath;
  final VoidCallback onEditPressed;
  final double size;

  const AvatarDisplay({
    super.key,
    required this.mood,
    required this.avatarAssetPath,
    required this.onEditPressed,
    this.size = 160,
  });

  @override
  State<AvatarDisplay> createState() => _AvatarDisplayState();
}

class _AvatarDisplayState extends State<AvatarDisplay>
    with SingleTickerProviderStateMixin {
  Timer? _bubbleTimer;
  bool _showBubble = false;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = widget.size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _onAvatarTap,
          onLongPress: _triggerPulse,
          child: AvatarGlow(
            mood: widget.mood,
            size: size + 38,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final t = Curves.easeOut.transform(_pulseController.value);
                  final scale =
                      1.0 + (0.06 * (1 - (t - 0.5).abs() * 2).clamp(0, 1));
                  return Transform.scale(scale: scale, child: child);
                },
                child: AvatarWidget(
                  config: AvatarConfig(
                    skin: 'skin_1',
                    hair: 'hair_1',
                    outfit: 'outfit_1',
                  ),
                  mood: widget.mood,
                  size: size * 0.92,
                  avatarAssetPath: widget.avatarAssetPath,
                  bubbleText: _bubbleText(widget.mood),
                  showBubble: _showBubble,
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                      begin: const Offset(0.995, 0.995),
                      end: const Offset(1.015, 1.015),
                      duration: 3.seconds,
                      curve: Curves.easeInOut,
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 42,
          child: OutlinedButton.icon(
            onPressed: widget.onEditPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(color: AppColors.purple.withOpacity(0.55)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.edit, size: 18, color: AppColors.purple),
            label: const Text(
              'Edit avatar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  void _showBubbleAnimated() {
    setState(() => _showBubble = true);
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showBubble = false);
    });
  }

  void _onAvatarTap() => _showBubbleAnimated();

  void _triggerPulse() {
    _pulseController.forward(from: 0);
  }

  String _bubbleText(String mood) {
    switch (mood) {
      case 'happy':
        return 'Feeling good today.';
      case 'calm':
        return 'Breathing. One step at a time.';
      case 'stressed':
        return 'I need a moment.';
      default:
        return 'Hi!';
    }
  }
}
