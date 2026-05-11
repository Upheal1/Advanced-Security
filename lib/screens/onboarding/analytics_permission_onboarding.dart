import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/onboarding/permission_step_widget.dart';

/// Onboarding flow for analytics/screen time permissions
class AnalyticsPermissionOnboarding extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  const AnalyticsPermissionOnboarding({
    super.key,
    required this.onComplete,
    this.onSkip,
  });

  @override
  State<AnalyticsPermissionOnboarding> createState() =>
      _AnalyticsPermissionOnboardingState();
}

class _AnalyticsPermissionOnboardingState
    extends State<AnalyticsPermissionOnboarding> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 3;

  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSkip() {
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      widget.onComplete();
    }
  }

  Future<void> _onGrantPermission() async {
    // Mark onboarding as complete
    await OnboardingService.markAnalyticsOnboardingComplete();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1B1B1B),
                        Color.lerp(
                          const Color(0xFF1B1B1B),
                          const Color(0xFF2D1B4E),
                          _backgroundAnimation.value * 0.3,
                        )!,
                      ]
                    : [
                        const Color(0xFFF8F5FF),
                        Color.lerp(
                          const Color(0xFFF8F5FF),
                          const Color(0xFFE8E0FF),
                          _backgroundAnimation.value * 0.5,
                        )!,
                      ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              // Header with skip button
              _buildHeader(isDark),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  children: [
                    _buildPage1(),
                    _buildPage2(),
                    _buildPage3(),
                  ],
                ),
              ),

              // Page indicator and buttons
              _buildBottomSection(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo or app name
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.brain,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'UpHeal',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          // Skip button
          TextButton(
            onPressed: _onSkip,
            child: Text(
              'Skip',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPage1() {
    return PermissionStepWidget(
      title: 'Track Your Digital Wellbeing',
      description:
          'Understand how you spend time on your device and build healthier digital habits.',
      icon: LucideIcons.smartphone,
      iconColor: const Color(0xFF7C3AED),
      benefits: const [
        'See your daily and weekly screen time',
        'Track which apps you use most',
        'Understand your usage patterns',
        'Identify areas for improvement',
      ],
    );
  }

  Widget _buildPage2() {
    return PermissionStepWidget(
      title: 'Understand Your Usage',
      description:
          'Visualize your app usage with beautiful charts and detailed insights.',
      icon: LucideIcons.barChart2,
      iconColor: const Color(0xFF10B981),
      customContent: const ChartPreviewWidget(),
    );
  }

  Widget _buildPage3() {
    return PermissionStepWidget(
      title: 'Set Healthy Limits',
      description:
          'Create app time limits and get notified when you\'re approaching them.',
      icon: LucideIcons.timer,
      iconColor: const Color(0xFFF59E0B),
      customContent: const LimitPreviewWidget(),
    );
  }

  Widget _buildBottomSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Page indicator dots
          _buildPageIndicator(isDark),
          const SizedBox(height: 32),
          // Action buttons
          _buildActionButtons(isDark),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildPageIndicator(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF7C3AED)
                : (isDark ? Colors.white24 : Colors.black12),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    final isLastPage = _currentPage == _totalPages - 1;

    return Column(
      children: [
        // Primary button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLastPage ? _onGrantPermission : _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLastPage ? 'Grant Permission' : 'Next',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isLastPage) ...[
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.arrowRight, size: 20),
                ],
                if (isLastPage) ...[
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.shield, size: 20),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary info text
        if (isLastPage)
          Text(
            Platform.isAndroid
                ? 'This will open Android settings to grant usage access permission'
                : 'This will request Screen Time permission',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
      ],
    );
  }
}

/// Full-screen onboarding dialog wrapper
class AnalyticsOnboardingDialog extends StatelessWidget {
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  const AnalyticsOnboardingDialog({
    super.key,
    required this.onComplete,
    this.onSkip,
  });

  /// Show the onboarding as a full-screen dialog
  static Future<bool?> show(BuildContext context) {
    return Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return AnalyticsOnboardingDialog(
            onComplete: () {
              Navigator.of(context).pop(true);
            },
            onSkip: () {
              Navigator.of(context).pop(false);
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnalyticsPermissionOnboarding(
      onComplete: onComplete,
      onSkip: onSkip,
    );
  }
}
