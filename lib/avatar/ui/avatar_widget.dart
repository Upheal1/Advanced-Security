import 'package:flutter/material.dart';

import '../models/avatar_config.dart';

class AvatarWidget extends StatefulWidget {
  final AvatarConfig config;
  final String mood;
  final double size;
  final VoidCallback? onTap;
  final String? avatarAssetPath;
  final String? bubbleText;
  final bool showBubble;
  final int? level;

  const AvatarWidget({
    super.key,
    required this.config,
    required this.mood,
    this.size = 220,
    this.onTap,
    this.avatarAssetPath,
    this.bubbleText,
    this.showBubble = false,
    this.level,
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  bool _levelPulse = false;

  @override
  void didUpdateWidget(covariant AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.level != null &&
        oldWidget.level != null &&
        widget.level! > oldWidget.level!) {
      _triggerLevelUp();
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateKey = ValueKey<String>(_stateSignature());

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: _levelPulse ? 1.2 : 1.0,
            end: 1.0,
          ),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          onEnd: () {
            if (_levelPulse) {
              setState(() => _levelPulse = false);
            }
          },
          builder: (context, levelScale, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                boxShadow: _levelPulse
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.28),
                          blurRadius: 34,
                          spreadRadius: 6,
                        ),
                      ]
                    : const [],
              ),
              child: Transform.scale(
                scale: levelScale,
                child: AnimatedBuilder(
                  animation: _breathController,
                  builder: (context, child) {
                    final t =
                        Curves.easeInOut.transform(_breathController.value);
                    final breathScale = 1.0 + (0.025 * t);
                    return Transform.scale(scale: breathScale, child: child);
                  },
                  child: RepaintBoundary(
                    child: Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: _AvatarArt(
                            key: stateKey,
                            config: widget.config,
                            mood: widget.mood,
                            avatarAssetPath: widget.avatarAssetPath,
                          ),
                        ),
                        if (widget.bubbleText != null)
                          Positioned(
                            top: -10,
                            child: _MessageBubble(
                              text: widget.bubbleText!,
                              visible: widget.showBubble,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _stateSignature() {
    return [
      widget.avatarAssetPath ?? '',
      widget.config.skin,
      widget.config.hair,
      widget.config.outfit,
      widget.mood,
    ].join('|');
  }

  void _triggerLevelUp() {
    setState(() => _levelPulse = true);
  }
}

class _AvatarArt extends StatelessWidget {
  final AvatarConfig config;
  final String mood;
  final String? avatarAssetPath;

  const _AvatarArt({
    super.key,
    required this.config,
    required this.mood,
    required this.avatarAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarAssetPath != null && avatarAssetPath!.isNotEmpty) {
      return Image.asset(
        avatarAssetPath!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.person),
      );
    }

    final eyesFile = _getEyesAsset(mood);
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 400,
        height: 400,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // TODO(TWEAK): adjust left/top/width/height to align
            // BODY - centered, full height, anchored at feet (bottom center)
            Positioned(
              left: 100,
              top: 60,
              width: 200,
              height: 320,
              child: _AvatarLayer(
                path: 'assets/avatar/body/${config.skin}.png',
                fallbackPath: 'assets/avatar/body/skin_1.png',
              ),
            ),
            // TODO(TWEAK): adjust left/top/width/height to align
            // OUTFIT - overlaid on body torso area
            Positioned(
              left: 108,
              top: 160,
              width: 184,
              height: 200,
              child: _AvatarLayer(
                path: 'assets/avatar/outfit/${config.outfit}.png',
                fallbackPath: 'assets/avatar/outfit/outfit_1.png',
              ),
            ),
            // TODO(TWEAK): adjust left/top/width/height to align
            // HAIR - sits above head, wider than body
            Positioned(
              left: 70,
              top: 30,
              width: 260,
              height: 180,
              child: _AvatarLayer(
                path: 'assets/avatar/hair/${config.hair}.png',
                fallbackPath: 'assets/avatar/hair/hair_1.png',
              ),
            ),
            // TODO(TWEAK): adjust left/top/width/height to align
            // EYES - centered on face area
            Positioned(
              left: 110,
              top: 140,
              width: 180,
              height: 80,
              child: _AvatarLayer(
                path: 'assets/avatar/eyes/$eyesFile',
                fallbackPath: 'assets/avatar/eyes/happy.png',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool visible;

  const _MessageBubble({required this.text, required this.visible});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface;
    final fg = theme.colorScheme.onSurface;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, 0.25),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        opacity: visible ? 1 : 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 240),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _AvatarLayer extends StatelessWidget {
  final String path;
  final String fallbackPath;

  const _AvatarLayer({required this.path, required this.fallbackPath});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          fallbackPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return Container(
              alignment: Alignment.center,
              color: Colors.transparent,
              child: const Icon(Icons.person, color: Colors.white70),
            );
          },
        );
      },
    );
  }
}

String _getEyesAsset(String mood) {
  switch (mood) {
    case 'happy':
      return 'happy.png';
    case 'stressed':
      return 'stressed.png';
    default:
      return 'happy.png';
  }
}
