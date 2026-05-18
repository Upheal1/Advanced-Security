import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/onboarding_data.dart';
import '../widgets/onboarding_widgets.dart';
import 'onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  late ConfettiController _confettiController;
  int _currentPage = 0;
  bool _isAnimating = false;
  bool _showConfetti = false;

  final List<OnboardingPageData> _pages = OnboardingPageData.pages;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    if (!_isAnimating) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  void _animateToPage(int page, {bool instant = false}) {
    if (_isAnimating) return;

    _isAnimating = true;
    HapticFeedback.selectionClick();

    if (instant) {
      _pageController.jumpToPage(page);
    } else {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }

    Future.delayed(const Duration(milliseconds: 450), () {
      _isAnimating = false;
    });
  }

  void _onNextPressed() {
    if (_currentPage < _pages.length - 1) {
      _animateToPage(_currentPage + 1);
    } else {
      _completeOnboarding();
    }
  }

  void _onSkipPressed() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.heavyImpact();

    setState(() {
      _showConfetti = true;
    });
    _confettiController.play();

    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
    } catch (e) {
      debugPrint('Error saving onboarding state: $e');
    }

    if (mounted) {
      ElegantNotification.success(
        title: const Text('Welcome to UpHeal!'),
        description: const Text('Your journey to a better you starts now.'),
        toastDuration: const Duration(seconds: 4),
      ).show(context);

      await Future.delayed(const Duration(milliseconds: 2000));

      if (mounted) {
        context.go('/auth/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return OnboardingPage(
                data: _pages[index],
                pageIndex: index,
              );
            },
          ),
          if (_showConfetti)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: math.pi / 2,
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.1,
                shouldLoop: false,
                colors: const [
                  Color(0xFF8B5CF6),
                  Color(0xFF06B6D4),
                  Color(0xFF45D9A8),
                  Color(0xFFF97316),
                  Color(0xFFEC4899),
                  Color(0xFFFFD700),
                ],
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isLastPage)
                      OnboardingTextButton(
                        text: 'Skip',
                        onPressed: _onSkipPressed,
                        color: Colors.white.withValues(alpha: 0.6),
                      ).animate().fadeIn(duration: 300.ms)
                    else
                      const SizedBox(width: 80),
                    OnboardingPageIndicator(
                      pageCount: _pages.length,
                      currentPage: _currentPage,
                      activeColor: const Color(0xFF8B5CF6),
                      inactiveColor: Colors.white.withValues(alpha: 0.3),
                      activeSize: 10,
                      inactiveSize: 6,
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(width: 80),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLastPage) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildSecondaryButton(context),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _buildPrimaryButton(),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildNavigationButtons(),
                    ],
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return OnboardingGradientButton(
      text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
      onPressed: _onNextPressed,
      gradientColors: _currentPage == _pages.length - 1
          ? const [Color(0xFF8B5CF6), Color(0xFF6366F1)]
          : const [Color(0xFF8B5CF6), Color(0xFFA855F7)],
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        context.go('/auth/signup');
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      child: const Text(
        'Sign Up',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (index) {
              final isActive = index == _currentPage;
              return GestureDetector(
                onTap: () => _animateToPage(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive
                        ? const Color(0xFF8B5CF6)
                        : Colors.white.withValues(alpha: 0.3),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 140,
          child: OnboardingGradientButton(
            text: _currentPage == _pages.length - 1 ? 'Finish' : 'Next',
            onPressed: _onNextPressed,
            height: 52,
          ),
        ),
      ],
    );
  }
}