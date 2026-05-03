import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/challenge_model.dart';
import '../services/challenge_service.dart';
import '../widgets/drawer_menu_button.dart';
import '../widgets/rewards/xp_burst_overlay.dart';
import 'challenges/avatar_header.dart';
import 'challenges/challenge_card.dart';
import 'challenges/progress_card.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  int _selectedTab = 0; // 0 = Daily, 1 = Weekly, 2 = Special
  final ScrollController _scrollController = ScrollController();
  late final ConfettiController _confettiController;
  String? _toastText;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeService>(
      builder: (context, service, _) {
        final daily = service.dailyChallenges;
        final weekly = service.weeklyChallenges;
        final special = service.specialChallenges;
        final active = service.activeChallenges;

        final completedToday = service.completedTodayCount;
        final totalXpAvailable = service.totalXpAvailable;

        final selectedList = _selectedTab == 0
            ? daily
            : _selectedTab == 1
                ? weekly
                : special;

        final todaysTotal = daily.length;
        final todaysCompleted = daily.where(_isCompletedToday).length;
        final completion =
            todaysTotal == 0 ? 0.0 : (todaysCompleted / todaysTotal);
        final xpEarnedToday = _xpEarnedToday([...daily, ...weekly, ...special]);

        final theme = Theme.of(context);
        final bg = theme.brightness == Brightness.dark
            ? const Color(0xFF0B0D12)
            : theme.scaffoldBackgroundColor;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Challenges',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            leading: DrawerMenuButton(
              iconColor: theme.brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.textPrimary,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(28),
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$completedToday completed today · $totalXpAvailable XP available',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AvatarHeader(
                      message: _motivationMessage(
                        completedToday: completedToday,
                        totalXpAvailable: totalXpAvailable,
                      ),
                      onAvatarTap: () =>
                          Navigator.of(context).pushNamed('/avatar'),
                    ),
                    const SizedBox(height: 12),
                    ProgressCard(
                      completion: completion,
                      xpEarnedToday: xpEarnedToday,
                      tasksCompleted: todaysCompleted,
                      tasksTotal: todaysTotal,
                    ),
                    const SizedBox(height: 14),
                    _PremiumTabBar(
                      selectedIndex: _selectedTab,
                      onSelected: _onTabSelected,
                      dailyCount: daily.length,
                      weeklyCount: weekly.length,
                      specialCount: special.length,
                    ),
                    const SizedBox(height: 14),
                    if (active.isNotEmpty) ...[
                      const _SectionTitle(
                        icon: LucideIcons.flame,
                        label: 'In progress',
                      ),
                      const SizedBox(height: 10),
                      for (final c in active)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ChallengeCard(
                            challenge: c,
                            confettiController: _confettiController,
                            showConfetti: false,
                            onPrimaryAction: () =>
                                _handlePrimaryAction(context, service, c),
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                    _SectionTitle(
                      icon: LucideIcons.swords,
                      label: _selectedTab == 0
                          ? 'Daily challenges'
                          : _selectedTab == 1
                              ? 'Weekly challenges'
                              : 'Special challenges',
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.02, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: selectedList.isEmpty
                          ? SizedBox(
                              key: const ValueKey('empty'),
                              height: 160,
                              child: Center(
                                child: Text(
                                  'No challenges available · Check back soon',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              key: ValueKey('list_$_selectedTab'),
                              children: [
                                for (final c in selectedList)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: ChallengeCard(
                                      challenge: c,
                                      confettiController: _confettiController,
                                      showConfetti: false,
                                      onPrimaryAction: () =>
                                          _handlePrimaryAction(
                                              context, service, c),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              if (_toastText != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 10,
                  child: Center(child: _XpToast(text: _toastText!)),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePrimaryAction(
    BuildContext context,
    ChallengeService service,
    ChallengeModel challenge,
  ) async {
    if (challenge.status == ChallengeStatus.available && !challenge.isExpired) {
      service.joinChallenge(challenge.id);
      _showToast('Started');
      return;
    }

    if (challenge.status == ChallengeStatus.active && !challenge.isExpired) {
      final willComplete =
          challenge.currentCount + 1 >= challenge.targetCount &&
              challenge.targetCount > 0;
      await service.incrementProgress(challenge.id, context);
      if (!mounted) return;

      if (willComplete) {
        _confettiController.play();
        _showToast('+${challenge.xpReward} XP');
        XpBurstOverlay.show(
          context,
          amount: challenge.xpReward,
          oldXp: 0,
          newXp: challenge.xpReward,
          xpNeeded: 0,
          level: 1,
        );
      } else {
        _showToast('+1 progress');
      }
    }
  }

  void _showToast(String text) {
    setState(() => _toastText = text);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _toastText = null);
    });
  }

  bool _isCompletedToday(ChallengeModel c) {
    final completedAt = c.completedAt;
    if (completedAt == null) return false;
    final now = DateTime.now();
    return completedAt.year == now.year &&
        completedAt.month == now.month &&
        completedAt.day == now.day;
  }

  int _xpEarnedToday(List<ChallengeModel> all) {
    return all
        .where(_isCompletedToday)
        .fold<int>(0, (sum, c) => sum + c.xpReward);
  }

  String _motivationMessage({
    required int completedToday,
    required int totalXpAvailable,
  }) {
    if (completedToday == 0) return 'Let’s win the first quest today.';
    if (totalXpAvailable == 0) return 'Perfect day. You cleared the board.';
    return 'Nice streak — $totalXpAvailable XP still waiting.';
  }
}

class _PremiumTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final int dailyCount;
  final int weeklyCount;
  final int specialCount;

  const _PremiumTabBar({
    required this.selectedIndex,
    required this.onSelected,
    required this.dailyCount,
    required this.weeklyCount,
    required this.specialCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <({String label, IconData icon})>[
      (label: 'Daily', icon: LucideIcons.calendarDays),
      (label: 'Weekly', icon: LucideIcons.calendarRange),
      (label: 'Special', icon: LucideIcons.sparkles),
    ];
    final counts = [dailyCount, weeklyCount, specialCount];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surface.withOpacity(0.35),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: selectedIndex == i
                        ? LinearGradient(
                            colors: [
                              AppColors.purple.withOpacity(0.95),
                              const Color(0xFFB4AFFF).withOpacity(0.65),
                            ],
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i].icon,
                        size: 16,
                        color: selectedIndex == i
                            ? Colors.white
                            : theme.colorScheme.onSurface.withOpacity(0.65),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${items[i].label} (${counts[i]})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selectedIndex == i
                              ? Colors.white
                              : theme.colorScheme.onSurface.withOpacity(0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (i != items.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon,
            size: 18, color: theme.colorScheme.onSurface.withOpacity(0.75)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _XpToast extends StatelessWidget {
  final String text;

  const _XpToast({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.purple.withOpacity(0.18),
        border: Border.all(color: AppColors.purple.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.purple,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 160.ms)
        .moveY(begin: 6, end: 0, duration: 240.ms)
        .then()
        .fadeOut(duration: 250.ms);
  }
}

/*

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/challenge_model.dart';
import '../services/challenge_service.dart';
import '../widgets/drawer_menu_button.dart';
import '../widgets/rewards/xp_burst_overlay.dart';
import 'challenges/avatar_header.dart';
import 'challenges/challenge_card.dart';
import 'challenges/progress_card.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  int _selectedTab = 0; // 0 = Daily, 1 = Weekly, 2 = Special
  final ScrollController _scrollController = ScrollController();
  late final ConfettiController _confettiController;
  String? _toastText;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeService>(
      builder: (context, service, _) {
        final daily = service.dailyChallenges;
        final weekly = service.weeklyChallenges;
        final special = service.specialChallenges;
        final active = service.activeChallenges;

        final completedToday = service.completedTodayCount;
        final totalXpAvailable = service.totalXpAvailable;

        final selectedList = _selectedTab == 0
            ? daily
            : _selectedTab == 1
                ? weekly
                : special;

        final todaysTotal = daily.length;
        final todaysCompleted = daily.where(_isCompletedToday).length;
        final completion =
            todaysTotal == 0 ? 0.0 : (todaysCompleted / todaysTotal);
        final xpEarnedToday = _xpEarnedToday([...daily, ...weekly, ...special]);

        final theme = Theme.of(context);
        final bg = theme.brightness == Brightness.dark
            ? const Color(0xFF0B0D12)
            : theme.scaffoldBackgroundColor;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Challenges',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            leading: DrawerMenuButton(
              iconColor: theme.brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.textPrimary,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(28),
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$completedToday completed today · $totalXpAvailable XP available',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AvatarHeader(
                      message: _motivationMessage(
                        completedToday: completedToday,
                        totalXpAvailable: totalXpAvailable,
                      ),
                      onAvatarTap: () =>
                          Navigator.of(context).pushNamed('/avatar'),
                    ),
                    const SizedBox(height: 12),
                    ProgressCard(
                      completion: completion,
                      xpEarnedToday: xpEarnedToday,
                      tasksCompleted: todaysCompleted,
                      tasksTotal: todaysTotal,
                    ),
                    const SizedBox(height: 14),
                    _PremiumTabBar(
                      selectedIndex: _selectedTab,
                      onSelected: _onTabSelected,
                      dailyCount: daily.length,
                      weeklyCount: weekly.length,
                      specialCount: special.length,
                    ),
                    const SizedBox(height: 14),
                    if (active.isNotEmpty) ...[
                      const _SectionTitle(
                        icon: LucideIcons.flame,
                        label: 'In progress',
                      ),
                      const SizedBox(height: 10),
                      for (final c in active)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ChallengeCard(
                            challenge: c,
                            confettiController: _confettiController,
                            showConfetti: false,
                            onPrimaryAction: () =>
                                _handlePrimaryAction(context, service, c),
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                    _SectionTitle(
                      icon: LucideIcons.swords,
                      label: _selectedTab == 0
                          ? 'Daily challenges'
                          : _selectedTab == 1
                              ? 'Weekly challenges'
                              : 'Special challenges',
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.02, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: selectedList.isEmpty
                          ? SizedBox(
                              key: const ValueKey('empty'),
                              height: 160,
                              child: Center(
                                child: Text(
                                  'No challenges available · Check back soon',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              key: ValueKey('list_$_selectedTab'),
                              children: [
                                for (final c in selectedList)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: ChallengeCard(
                                      challenge: c,
                                      confettiController: _confettiController,
                                      showConfetti: false,
                                      onPrimaryAction: () =>
                                          _handlePrimaryAction(
                                              context, service, c),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              if (_toastText != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 10,
                  child: Center(child: _XpToast(text: _toastText!)),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePrimaryAction(
    BuildContext context,
    ChallengeService service,
    ChallengeModel challenge,
  ) async {
    if (challenge.status == ChallengeStatus.available && !challenge.isExpired) {
      service.joinChallenge(challenge.id);
      _showToast('Started');
      return;
    }

    if (challenge.status == ChallengeStatus.active && !challenge.isExpired) {
      final willComplete =
          challenge.currentCount + 1 >= challenge.targetCount &&
              challenge.targetCount > 0;
      await service.incrementProgress(challenge.id, context);
      if (!mounted) return;

      if (willComplete) {
        _confettiController.play();
        _showToast('+${challenge.xpReward} XP');
        XpBurstOverlay.show(
          context,
          amount: challenge.xpReward,
          oldXp: 0,
          newXp: challenge.xpReward,
          xpNeeded: 0,
          level: 1,
        );
      } else {
        _showToast('+1 progress');
      }
    }
  }

  void _showToast(String text) {
    setState(() => _toastText = text);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _toastText = null);
    });
  }

  bool _isCompletedToday(ChallengeModel c) {
    final completedAt = c.completedAt;
    if (completedAt == null) return false;
    final now = DateTime.now();
    return completedAt.year == now.year &&
        completedAt.month == now.month &&
        completedAt.day == now.day;
  }

  int _xpEarnedToday(List<ChallengeModel> all) {
    return all
        .where(_isCompletedToday)
        .fold<int>(0, (sum, c) => sum + c.xpReward);
  }

  String _motivationMessage({
    required int completedToday,
    required int totalXpAvailable,
  }) {
    if (completedToday == 0) return 'Let’s win the first quest today.';
    if (totalXpAvailable == 0) return 'Perfect day. You cleared the board.';
    return 'Nice streak — $totalXpAvailable XP still waiting.';
  }
}

class _PremiumTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final int dailyCount;
  final int weeklyCount;
  final int specialCount;

  const _PremiumTabBar({
    required this.selectedIndex,
    required this.onSelected,
    required this.dailyCount,
    required this.weeklyCount,
    required this.specialCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <({String label, IconData icon})>[
      (label: 'Daily', icon: LucideIcons.calendarDays),
      (label: 'Weekly', icon: LucideIcons.calendarRange),
      (label: 'Special', icon: LucideIcons.sparkles),
    ];
    final counts = [dailyCount, weeklyCount, specialCount];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surface.withOpacity(0.35),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: selectedIndex == i
                        ? LinearGradient(
                            colors: [
                              AppColors.purple.withOpacity(0.95),
                              const Color(0xFFB4AFFF).withOpacity(0.65),
                            ],
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i].icon,
                        size: 16,
                        color: selectedIndex == i
                            ? Colors.white
                            : theme.colorScheme.onSurface.withOpacity(0.65),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${items[i].label} (${counts[i]})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selectedIndex == i
                              ? Colors.white
                              : theme.colorScheme.onSurface.withOpacity(0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (i != items.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon,
            size: 18, color: theme.colorScheme.onSurface.withOpacity(0.75)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _XpToast extends StatelessWidget {
  final String text;

  const _XpToast({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.purple.withOpacity(0.18),
        border: Border.all(color: AppColors.purple.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.purple,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 160.ms)
        .moveY(begin: 6, end: 0, duration: 240.ms)
        .then()
        .fadeOut(duration: 250.ms);
  }
}
*** End of File
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/challenge_model.dart';
import '../services/challenge_service.dart';
import '../widgets/drawer_menu_button.dart';
import '../widgets/rewards/xp_burst_overlay.dart';
import 'challenges/avatar_header.dart';
import 'challenges/challenge_card.dart';
import 'challenges/progress_card.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  int _selectedTab = 0; // 0 = Daily, 1 = Weekly, 2 = Special
  final ScrollController _scrollController = ScrollController();
  late final ConfettiController _confettiController;
  String? _toastText;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeService>(
      builder: (context, service, _) {
        final daily = service.dailyChallenges;
        final weekly = service.weeklyChallenges;
        final special = service.specialChallenges;
        final active = service.activeChallenges;

        final completedToday = service.completedTodayCount;
        final totalXpAvailable = service.totalXpAvailable;

        final selectedList = _selectedTab == 0
            ? daily
            : _selectedTab == 1
                ? weekly
                : special;

        final todaysTotal = daily.length;
        final todaysCompleted = daily.where(_isCompletedToday).length;
        final completion =
            todaysTotal == 0 ? 0.0 : (todaysCompleted / todaysTotal);
        final xpEarnedToday = _xpEarnedToday([...daily, ...weekly, ...special]);

        final theme = Theme.of(context);
        final bg = theme.brightness == Brightness.dark
            ? const Color(0xFF0B0D12)
            : theme.scaffoldBackgroundColor;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Challenges',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            leading: DrawerMenuButton(
              iconColor: theme.brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.textPrimary,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(28),
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$completedToday completed today · $totalXpAvailable XP available',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AvatarHeader(
                      message: _motivationMessage(
                        completedToday: completedToday,
                        totalXpAvailable: totalXpAvailable,
                      ),
                      onAvatarTap: () =>
                          Navigator.of(context).pushNamed('/avatar'),
                    ),
                    const SizedBox(height: 12),
                    ProgressCard(
                      completion: completion,
                      xpEarnedToday: xpEarnedToday,
                      tasksCompleted: todaysCompleted,
                      tasksTotal: todaysTotal,
                    ),
                    const SizedBox(height: 14),
                    _PremiumTabBar(
                      selectedIndex: _selectedTab,
                      onSelected: _onTabSelected,
                      dailyCount: daily.length,
                      weeklyCount: weekly.length,
                      specialCount: special.length,
                    ),
                    const SizedBox(height: 14),
                    if (active.isNotEmpty) ...[
                      const _SectionTitle(
                        icon: LucideIcons.flame,
                        label: 'In progress',
                      ),
                      const SizedBox(height: 10),
                      for (final c in active)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ChallengeCard(
                            challenge: c,
                            confettiController: _confettiController,
                            showConfetti: false,
                            onPrimaryAction: () =>
                                _handlePrimaryAction(context, service, c),
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                    _SectionTitle(
                      icon: LucideIcons.swords,
                      label: _selectedTab == 0
                          ? 'Daily challenges'
                          : _selectedTab == 1
                              ? 'Weekly challenges'
                              : 'Special challenges',
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.02, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: selectedList.isEmpty
                          ? SizedBox(
                              key: const ValueKey('empty'),
                              height: 160,
                              child: Center(
                                child: Text(
                                  'No challenges available · Check back soon',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              key: ValueKey('list_$_selectedTab'),
                              children: [
                                for (final c in selectedList)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: ChallengeCard(
                                      challenge: c,
                                      confettiController: _confettiController,
                                      showConfetti: false,
                                      onPrimaryAction: () =>
                                          _handlePrimaryAction(
                                              context, service, c),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              if (_toastText != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 10,
                  child: Center(child: _XpToast(text: _toastText!)),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePrimaryAction(
    BuildContext context,
    ChallengeService service,
    ChallengeModel challenge,
  ) async {
    if (challenge.status == ChallengeStatus.available && !challenge.isExpired) {
      service.joinChallenge(challenge.id);
      _showToast('Started');
      return;
    }

    if (challenge.status == ChallengeStatus.active && !challenge.isExpired) {
      final willComplete =
          challenge.currentCount + 1 >= challenge.targetCount &&
              challenge.targetCount > 0;
      await service.incrementProgress(challenge.id, context);
      if (!mounted) return;

      if (willComplete) {
        _confettiController.play();
        _showToast('+${challenge.xpReward} XP');
        // Lightweight XP feedback. (ChallengeService already queues rewards.)
        XpBurstOverlay.show(
          context,
          amount: challenge.xpReward,
          oldXp: 0,
          newXp: challenge.xpReward,
          xpNeeded: 0,
          level: 1,
        );
      } else {
        _showToast('+1 progress');
      }
    }
  }

  void _showToast(String text) {
    setState(() => _toastText = text);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _toastText = null);
    });
  }

  bool _isCompletedToday(ChallengeModel c) {
    final completedAt = c.completedAt;
    if (completedAt == null) return false;
    final now = DateTime.now();
    return completedAt.year == now.year &&
        completedAt.month == now.month &&
        completedAt.day == now.day;
  }

  int _xpEarnedToday(List<ChallengeModel> all) {
    return all
        .where(_isCompletedToday)
        .fold<int>(0, (sum, c) => sum + c.xpReward);
  }

  String _motivationMessage({
    required int completedToday,
    required int totalXpAvailable,
  }) {
    if (completedToday == 0) return 'Let’s win the first quest today.';
    if (totalXpAvailable == 0) return 'Perfect day. You cleared the board.';
    return 'Nice streak — $totalXpAvailable XP still waiting.';
  }
}

class _PremiumTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final int dailyCount;
  final int weeklyCount;
  final int specialCount;

  const _PremiumTabBar({
    required this.selectedIndex,
    required this.onSelected,
    required this.dailyCount,
    required this.weeklyCount,
    required this.specialCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <({String label, IconData icon})>[
      (label: 'Daily', icon: LucideIcons.calendarDays),
      (label: 'Weekly', icon: LucideIcons.calendarRange),
      (label: 'Special', icon: LucideIcons.sparkles),
    ];
    final counts = [dailyCount, weeklyCount, specialCount];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surface.withOpacity(0.35),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: selectedIndex == i
                        ? LinearGradient(
                            colors: [
                              AppColors.purple.withOpacity(0.95),
                              const Color(0xFFB4AFFF).withOpacity(0.65),
                            ],
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i].icon,
                        size: 16,
                        color: selectedIndex == i
                            ? Colors.white
                            : theme.colorScheme.onSurface.withOpacity(0.65),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${items[i].label} (${counts[i]})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selectedIndex == i
                              ? Colors.white
                              : theme.colorScheme.onSurface.withOpacity(0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (i != items.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon,
            size: 18, color: theme.colorScheme.onSurface.withOpacity(0.75)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _XpToast extends StatelessWidget {
  final String text;

  const _XpToast({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.purple.withOpacity(0.18),
        border: Border.all(color: AppColors.purple.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.purple,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 160.ms)
        .moveY(begin: 6, end: 0, duration: 240.ms)
        .then()
        .fadeOut(duration: 250.ms);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/challenge_model.dart';
import '../services/challenge_service.dart';
import '../widgets/drawer_menu_button.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  int _selectedTab = 0; // 0 = Daily, 1 = Weekly, 2 = Special
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedTab == index) return;
    setState(() {
      _selectedTab = index;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeService>(
      builder: (context, service, _) {
        final daily = service.dailyChallenges;
        final weekly = service.weeklyChallenges;
        final special = service.specialChallenges;
        final active = service.activeChallenges;

        final completedToday = service.completedTodayCount;
        final totalXpAvailable = service.totalXpAvailable;

        final selectedList = _selectedTab == 0
            ? daily
            : _selectedTab == 1
                ? weekly
                : special;

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Text(
              'Challenges',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: DrawerMenuButton(
              iconColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.textPrimary,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(28),
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$completedToday completed today · $totalXpAvailable XP available',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSummary(
                  context,
                  activeCount: active.length,
                  completedToday: completedToday,
                  totalXpAvailable: totalXpAvailable,
                ),
                const SizedBox(height: 16),
                _buildTabBar(
                  context,
                  dailyCount: daily.length,
                  weeklyCount: weekly.length,
                  specialCount: special.length,
                ),
                const SizedBox(height: 16),
                if (active.isNotEmpty) ...[
                  _buildActiveSection(context, active),
                  const SizedBox(height: 20),
                ],
                _buildSelectedSectionHeader(),
                const SizedBox(height: 8),
                if (selectedList.isEmpty)
                  SizedBox(
                    height: 160,
                    child: Center(
                      child: Text(
                        'No challenges available · Check back soon',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (int i = 0;
                          i < selectedList.length;
                          i++)
                        _ChallengeListTile(
                          challenge: selectedList[i],
                          index: i,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSummary(
    BuildContext context, {
    required int activeCount,
    required int completedToday,
    required int totalXpAvailable,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.purple.withOpacity(0.2),
          width: 1,
        ),
        color: AppColors.purple.withOpacity(0.06),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _summaryPill('🔥 $activeCount active'),
          _summaryPill('✅ $completedToday done'),
          _summaryPill('⚡ $totalXpAvailable XP left'),
        ],
      ),
    );
  }

  Widget _summaryPill(String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.purple,
        ),
      ),
    );
  }

  Widget _buildTabBar(
    BuildContext context, {
    required int dailyCount,
    required int weeklyCount,
    required int specialCount,
  }) {
    final labels = [
      'Daily ($dailyCount)',
      'Weekly ($weeklyCount)',
      'Special ($specialCount)',
    ];

    return Row(
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => _onTabSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTab == i
                      ? AppColors.purple
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _selectedTab == i
                        ? Colors.transparent
                        : Theme.of(context)
                            .dividerColor
                            .withOpacity(0.7),
                  ),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedTab == i
                          ? Colors.white
                          : Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (i != labels.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildActiveSection(
      BuildContext context, List<ChallengeModel> active) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.flame,
              size: 18,
              color: Color(0xFFFF6B35),
            ),
            const SizedBox(width: 6),
            Text(
              'In progress',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: active.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final challenge = active[index];
              return _ActiveChallengeCard(
                challenge: challenge,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedSectionHeader() {
    String label;
    switch (_selectedTab) {
      case 0:
        label = 'Daily challenges';
        break;
      case 1:
        label = 'Weekly challenges';
        break;
      case 2:
      default:
        label = 'Special challenges';
        break;
    }
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }
}

class _ActiveChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;

  const _ActiveChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final difficultyColor = challenge.difficultyColor;
    final theme = Theme.of(context);

    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.purple.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                challenge.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  challenge.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.color,
                  ),
                ),
              ),
              _DifficultyPill(challenge: challenge),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: challenge.progress,
              backgroundColor: Colors.grey[200],
              valueColor:
                  AlwaysStoppedAnimation<Color>(difficultyColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${challenge.currentCount} / ${challenge.targetCount} · ${challenge.timeLeftLabel}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withOpacity(0.7),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: difficultyColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                challenge.difficultyLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: difficultyColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Continue is just a semantic hint for now; actual
                  // progress updates happen via list tiles.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Open the challenge list to add progress.',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  'Continue →',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideX(begin: 0.2, curve: Curves.easeOut);
  }
}

class _ChallengeListTile extends StatelessWidget {
  final ChallengeModel challenge;
  final int index;

  const _ChallengeListTile({
    required this.challenge,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final service = context.read<ChallengeService>();
    final theme = Theme.of(context);
    final dividerColor = theme.dividerColor;

    final isExpired = challenge.isExpired ||
        challenge.status == ChallengeStatus.expired;
    final isCompleted = challenge.status == ChallengeStatus.completed;
    final isActive = challenge.status == ChallengeStatus.active;
    final isAvailable = challenge.status == ChallengeStatus.available;

    Color borderColor;
    Color? backgroundColor;

    if (isCompleted) {
      borderColor = const Color(0xFF1D9E75);
      backgroundColor = const Color(0xFF1D9E75).withOpacity(0.06);
    } else if (isActive) {
      borderColor = challenge.difficultyColor;
    } else {
      borderColor = dividerColor;
    }

    final circleBg = challenge.difficultyColor.withOpacity(0.12);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleBg,
            ),
            alignment: Alignment.center,
            child: Text(
              challenge.emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  challenge.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color
                        ?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _DifficultyPill(challenge: challenge),
                    const SizedBox(width: 8),
                    Icon(
                      LucideIcons.users,
                      size: 14,
                      color: theme.textTheme.bodySmall?.color
                          ?.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.participantCount} joined',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color
                            ?.withOpacity(0.7),
                      ),
                    ),
                    const Spacer(),
                    _XpPill(xpReward: challenge.xpReward),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildTrailing(
            context,
            service: service,
            isAvailable: isAvailable && !isExpired,
            isActive: isActive && !isExpired,
            isCompleted: isCompleted,
            isExpired: isExpired,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 60).ms)
        .slideY(begin: 0.05, curve: Curves.easeOut);
  }

  Widget _buildTrailing(
    BuildContext context, {
    required ChallengeService service,
    required bool isAvailable,
    required bool isActive,
    required bool isCompleted,
    required bool isExpired,
  }) {
    final theme = Theme.of(context);

    if (isExpired) {
      return Text(
        'Expired',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: theme.textTheme.bodySmall?.color
              ?.withOpacity(0.6),
        ),
      );
    }

    if (isCompleted) {
      return const Icon(
        LucideIcons.checkCircle,
        color: Color(0xFF1D9E75),
        size: 26,
      );
    }

    if (isAvailable) {
      return SizedBox(
        height: 36,
        child: OutlinedButton(
          onPressed: () {
            service.joinChallenge(challenge.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Challenge joined! Complete it before it expires.',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.purple,
            side: const BorderSide(color: AppColors.purple),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: Text(
            'Join',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (isActive) {
      return GestureDetector(
        onTap: () async {
          final willComplete =
              challenge.currentCount + 1 >= challenge.targetCount &&
                  challenge.targetCount > 0;
          await service.incrementProgress(challenge.id, context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                willComplete
                    ? 'Challenge completed! Great job.'
                    : '+1 progress · Keep going!',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            value: challenge.progress == 0 ? null : challenge.progress,
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              challenge.difficultyColor,
            ),
            backgroundColor: Colors.grey[200],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _DifficultyPill extends StatelessWidget {
  final ChallengeModel challenge;

  const _DifficultyPill({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final color = challenge.difficultyColor;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        challenge.difficultyLabel,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _XpPill extends StatelessWidget {
  final int xpReward;

  const _XpPill({required this.xpReward});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '+$xpReward XP',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.purple,
        ),
      ),
    );
  }
}



*/
