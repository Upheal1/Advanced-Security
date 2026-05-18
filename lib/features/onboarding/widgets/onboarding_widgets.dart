import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/onboarding_data.dart';

class OnboardingPageIndicator extends StatefulWidget {
  final int pageCount;
  final int currentPage;
  final Color activeColor;
  final Color inactiveColor;
  final double activeSize;
  final double inactiveSize;

  const OnboardingPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    this.activeColor = const Color(0xFF8B5CF6),
    this.inactiveColor = const Color(0xFF4B5563),
    this.activeSize = 12.0,
    this.inactiveSize = 8.0,
  });

  @override
  State<OnboardingPageIndicator> createState() => _OnboardingPageIndicatorState();
}

class _OnboardingPageIndicatorState extends State<OnboardingPageIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.pageCount, (index) {
        final isActive = index == widget.currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: isActive ? widget.activeSize : widget.inactiveSize,
          height: isActive ? widget.activeSize : widget.inactiveSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? widget.activeColor : widget.inactiveColor,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: widget.activeColor.withValues(alpha: 0.5),
                      blurRadius: 8.0,
                      spreadRadius: 2.0,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class OnboardingGradientButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color> gradientColors;
  final double height;
  final double? width;
  final bool isLoading;

  const OnboardingGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradientColors = const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
    this.height = 56.0,
    this.width,
    this.isLoading = false,
  });

  @override
  State<OnboardingGradientButton> createState() => _OnboardingGradientButtonState();
}

class _OnboardingGradientButtonState extends State<OnboardingGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onPressed();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: widget.height,
              width: widget.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.gradientColors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradientColors[0].withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class OnboardingTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final double fontSize;

  const OnboardingTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = Colors.white70,
    this.fontSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class AnimatedGradientBackground extends StatefulWidget {
  final List<Color> colors;
  final Widget child;
  final Duration duration;

  const AnimatedGradientBackground({
    super.key,
    required this.colors,
    required this.child,
    this.duration = const Duration(seconds: 10),
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _topAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        weight: 1,
      ),
    ]).animate(_controller);

    _bottomAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.bottomRight,
          end: Alignment.bottomLeft,
        ),
        weight: 1,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _topAlignmentAnimation.value,
              end: _bottomAlignmentAnimation.value,
              colors: widget.colors,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class FloatingParticle extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final Offset startPosition;

  const FloatingParticle({
    super.key,
    required this.size,
    required this.color,
    required this.duration,
    required this.startPosition,
  });

  @override
  State<FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _xAnimation;
  late Animation<double> _yAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    final random = math.Random();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _xAnimation = Tween<double>(
      begin: widget.startPosition.dx,
      end: widget.startPosition.dx + random.nextDouble() * 100 - 50,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _yAnimation = Tween<double>(
      begin: widget.startPosition.dy,
      end: widget.startPosition.dy - random.nextDouble() * 150 - 50,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.6),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 0.3),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 0.0),
        weight: 30,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _xAnimation.value,
          top: _yAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: widget.size * 0.8,
                    spreadRadius: widget.size * 0.2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ParticlesBackground extends StatelessWidget {
  final List<Color> particleColors;
  final int particleCount;

  const ParticlesBackground({
    super.key,
    this.particleColors = const [
      Color(0xFF8B5CF6),
      Color(0xFF6366F1),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
    ],
    this.particleCount = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(particleCount, (index) {
        final random = math.Random(index);
        return FloatingParticle(
          size: random.nextDouble() * 6 + 2,
          color: particleColors[random.nextInt(particleColors.length)],
          duration: Duration(milliseconds: random.nextInt(3000) + 4000),
          startPosition: Offset(
            random.nextDouble() * MediaQuery.of(context).size.width,
            random.nextDouble() * MediaQuery.of(context).size.height,
          ),
        );
      }),
    );
  }
}

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 24.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class OnboardingVisual extends StatefulWidget {
  final OnboardingPageType type;
  final String heroTag;
  final List<Color> gradientColors;

  const OnboardingVisual({
    super.key,
    required this.type,
    required this.heroTag,
    required this.gradientColors,
  });

  @override
  State<OnboardingVisual> createState() => _OnboardingVisualState();
}

class _OnboardingVisualState extends State<OnboardingVisual>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _glowController;
  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.heroTag,
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatAnimation, _glowAnimation]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.gradientColors[0].withValues(alpha: _glowAnimation.value),
                    widget.gradientColors[1].withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradientColors[0].withValues(alpha: 0.3 * _glowAnimation.value),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Center(
                child: _buildVisualContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVisualContent() {
    switch (widget.type) {
      case OnboardingPageType.welcome:
        return _buildMountainVisual();
      case OnboardingPageType.focus:
        return _buildFocusVisual();
      case OnboardingPageType.gamification:
        return _buildGamificationVisual();
      case OnboardingPageType.aiAssistant:
        return _buildAIVisual();
    }
  }

  Widget _buildMountainVisual() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.terrain_rounded,
            size: 80,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          Positioned(
            bottom: 30,
            child: Container(
              width: 60,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    widget.gradientColors[0],
                    widget.gradientColors[2],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusVisual() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.center_focus_strong_rounded,
            size: 60,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          ...List.generate(3, (index) {
            final angle = (index * 120) * 3.14159 / 180;
            return Positioned(
              left: 50 + 35 * math.cos(angle),
              top: 50 + 35 * math.sin(angle),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.3 - index * 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGamificationVisual() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.3),
            const Color(0xFFFFA500).withValues(alpha: 0.15),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            size: 70,
            color: const Color(0xFFFFD700),
          ),
          Positioned(
            top: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: const Text(
                'LVL 5',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIVisual() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF06B6D4).withValues(alpha: 0.3),
            const Color(0xFF8B5CF6).withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF06B6D4).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.psychology_rounded,
            size: 60,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          Positioned(
            bottom: 25,
            left: 25,
            right: 25,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF06B6D4),
                    const Color(0xFF8B5CF6),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}