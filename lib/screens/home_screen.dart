import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/mission_model.dart';
import '../models/user_model.dart';
import '../models/streak_model.dart';
import '../constants/app_colors.dart';
import '../gamification/xp_config.dart';
import '../widgets/rewards/urge_breathing_widget.dart';
import '../services/comeback_reward_service.dart';
import '../navigation/app_routes.dart';
import 'journal_screen.dart';
import 'notification_settings_screen.dart';
import 'roadmap_screen.dart';
import 'ai_chat_screen.dart';
import 'insights_screen.dart';
import '../widgets/drawer_menu_button.dart';
import '../widgets/traveler_viewer.dart';
import '../features/community/ui/community_hub_screen.dart';

// Helper class to hold selected data for minimal rebuilds
class _HomeScreenData {
  final List<Mission> missions;
  final UserModel user;

  _HomeScreenData({required this.missions, required this.user});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _HomeScreenData &&
          runtimeType == other.runtimeType &&
          missions == other.missions &&
          user == other.user;

  @override
  int get hashCode => missions.hashCode ^ user.hashCode;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Short-lived greeting at the top of Home (no avatar row — replaced old welcome card).
  bool _showWelcomeBanner = true;
  Timer? _welcomeBannerTimer;

  @override
  void initState() {
    super.initState();
    _welcomeBannerTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _showWelcomeBanner = false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final streakState = context.read<StreakState>();
      final user = context.read<UserModel>();

      final result = await ComebackRewardService.checkAndApply(
        streakState: streakState,
        user: user,
      );

      if (!mounted || !result.granted || result.message == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message!),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  void dispose() {
    _welcomeBannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Selector to minimize rebuilds - only rebuild when missions or user data actually changes
    return Selector2<MissionsModel, UserModel, _HomeScreenData>(
      selector: (_, missions, user) => _HomeScreenData(
        missions: missions.missions,
        user: user,
      ),
      builder: (context, data, child) {
        final missions = data.missions;
        final user = data.user;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => UrgeBreathingWidget.show(context),
            backgroundColor: AppColors.green,
            icon: const Icon(Icons.air, color: Colors.white),
            label: const Text(
              "I'm feeling an urge",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            leading: DrawerMenuButton(
              iconColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.textPrimary,
            ),
            title: Text(
              'UpHeal',
              style: GoogleFonts.inter(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ]
                        : [
                            AppColors.textPrimary.withOpacity(0.05),
                            AppColors.textPrimary.withOpacity(0.02),
                          ],
                  ),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.2)
                        : AppColors.textPrimary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    LucideIcons.bell,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.textPrimary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen(),
                    ),
                  ),
                  tooltip: 'Notifications',
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome sits above the companion card and reserves height so the
                  // companion block animates down / back up when this shows or hides.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.hardEdge,
                    child: _showWelcomeBanner
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildEphemeralWelcomeBanner(context, user),
                          )
                        : const SizedBox.shrink(),
                  ),
                  // 3D Traveler (GLB via o3d / model-viewer)
                  _buildTravelerSection(context, user),
                  const SizedBox(height: 20),

                  _buildHomeJourneyPanel(context, user, missions),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Hero 3D viewer — centered Traveler model with theme-matched backdrop.
  Widget _buildTravelerSection(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = Colors.white.withValues(alpha: isDark ? 0.08 : 0.12);
    final int currentJourneyDay = _journeyDay(user);
    final int nextLevelXp = XpConfig.totalXpForLevel(user.level + 1);
    final int xpToNextLevel = (nextLevelXp - user.xp).clamp(0, nextLevelXp);
    final String rankTitle = _travelerRankTitle(user.level);
    final double viewerHeight = MediaQuery.sizeOf(context).width >= 600 ? 340 : 248;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFF243047),
            const Color(0xFF2C4151),
          ],
        ),
        border: Border.all(color: borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Your Traveler',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.94),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDBA2D),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFFFDBA2D).withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      LucideIcons.star,
                      size: 14,
                      color: Color(0xFF7A4A00),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LVL ${user.level}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF7A4A00),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: viewerHeight,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.15),
                        radius: 0.9,
                        colors: <Color>[
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.015),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                TravelerViewer(
                  height: viewerHeight,
                  backgroundColor: Colors.transparent,
                ),
                Positioned(
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF536279).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          LucideIcons.rotateCcw,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Press & drag to rotate',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildTravelerMetric(
                  icon: LucideIcons.trophy,
                  iconColor: const Color(0xFFF3C64C),
                  value: rankTitle,
                  label: 'Rank',
                ),
              ),
              Expanded(
                child: _buildTravelerMetric(
                  value: 'Day $currentJourneyDay',
                  subvalue: 'of 90',
                  label: '',
                ),
              ),
              Expanded(
                child: _buildTravelerMetric(
                  icon: LucideIcons.zap,
                  iconColor: const Color(0xFF72F0A8),
                  value: _formatCompactNumber(user.xp),
                  label: 'XP',
                  valueColor: Colors.white,
                  alignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Level ${user.level} · $rankTitle',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE7EEFF),
                  ),
                ),
              ),
              Text(
                '$xpToNextLevel XP to next',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: user.levelProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF52DE97)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelerMetric({
    IconData? icon,
    Color? iconColor,
    required String value,
    required String label,
    String? subvalue,
    Color? valueColor,
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 13, color: iconColor ?? Colors.white),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? Colors.white,
                ),
              ),
            ),
          ],
        ),
        if (subvalue != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subvalue,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.62),
              ),
            ),
          )
        else
          const SizedBox(height: 2),
        if (label.isNotEmpty)
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
      ],
    );
  }

  int _journeyDay(UserModel user) {
    final int elapsedDays = DateTime.now().difference(user.joinDate).inDays + 1;
    return elapsedDays.clamp(1, 90);
  }

  String _travelerRankTitle(int level) {
    if (level >= 15) return 'Luminary';
    if (level >= 11) return 'Pathfinder';
    if (level >= 7) return 'Trailblazer';
    if (level >= 4) return 'Wanderer';
    return 'Explorer';
  }

  String _formatCompactNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    }
    return value.toString();
  }

  Widget _buildHomeJourneyPanel(
    BuildContext context,
    UserModel user,
    List<Mission> missions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildTodayQuestCard(context, missions),
        const SizedBox(height: 18),
        _buildQuickAccessSection(context),
        const SizedBox(height: 18),
        _buildFocusSessionCard(context),
        const SizedBox(height: 18),
        _buildContinueAscentCard(context, user),
        const SizedBox(height: 14),
        _buildUpcomingCard(context, missions),
      ],
    );
  }

  Widget _buildTodayQuestCard(BuildContext context, List<Mission> missions) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Mission> visibleMissions = missions.take(4).toList(growable: false);
    final int completedCount = visibleMissions.where((mission) => mission.completed).length;
    final double progress = visibleMissions.isEmpty
        ? 0
        : completedCount / visibleMissions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              LucideIcons.target,
              size: 14,
              color: const Color(0xFF6E9ED9),
            ),
            const SizedBox(width: 8),
            Text(
              "Today's Quest",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A2A44),
              ),
            ),
            const Spacer(),
            Text(
              '$completedCount/${visibleMissions.length} done',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.62)
                    : const Color(0xFF8D97A7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 5,
            value: progress,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE4E8EF),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF79A98A)),
          ),
        ),
        const SizedBox(height: 14),
        ...visibleMissions.map((mission) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildQuestTile(context, mission),
          );
        }),
      ],
    );
  }

  Widget _buildQuestTile(BuildContext context, Mission mission) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.read<MissionsModel>().toggleMission(mission.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : mission.completed
                  ? const Color(0xFFF1F7EE)
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE6EAF0),
          ),
          boxShadow: isDark
              ? const <BoxShadow>[]
              : <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: mission.completed
                    ? const Color(0xFF7BA886)
                    : (isDark ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFF0F3F7)),
                shape: BoxShape.circle,
              ),
              child: mission.completed
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    mission.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: mission.completed ? TextDecoration.lineThrough : null,
                      color: isDark ? Colors.white : const Color(0xFF24324A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _missionDurationText(mission),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.56)
                          : const Color(0xFF9AA3B2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '+${mission.xpReward} XP',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEDB448),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              LucideIcons.zap,
              size: 14,
              color: const Color(0xFFF0C15B),
            ),
            const SizedBox(width: 8),
            Text(
              'Quick Access',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A2A44),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildQuickAccessTile(
                context,
                icon: LucideIcons.bookOpen,
                label: 'Journal',
                background: const Color(0xFFE6F0E3),
                iconColor: const Color(0xFF7AA08B),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const JournalScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickAccessTile(
                context,
                icon: LucideIcons.messageCircle,
                label: 'AI Coach',
                background: const Color(0xFFE4F0FD),
                iconColor: const Color(0xFF75A3D9),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AiChatScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickAccessTile(
                context,
                icon: LucideIcons.barChart3,
                label: 'Insights',
                background: const Color(0xFFFBEFCF),
                iconColor: const Color(0xFFE4BA5A),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const InsightsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickAccessTile(
                context,
                icon: LucideIcons.users,
                label: 'Groups',
                background: const Color(0xFFECE4FF),
                iconColor: const Color(0xFF9A86E8),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CommunityHubScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFocusSessionCard(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        const FocusSessionRoute().push<void>(context);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF2D1B69),
                    const Color(0xFF1A1035),
                  ]
                : [
                    const Color(0xFFF5F3FF),
                    const Color(0xFFEDE9FE),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFDDD6FE),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: isDark ? 0.3 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.purple,
                    AppColors.purple.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.timer,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Focus Session',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1F1669),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deep work without distractions',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.arrowRight,
                size: 20,
                color: isDark ? Colors.white70 : AppColors.purple,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
    );
  }

  Widget _buildQuickAccessTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color background,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF304056),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueAscentCard(BuildContext context, UserModel user) {
    final int journeyDay = _journeyDay(user);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const RoadmapScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF253A4C),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.map,
                size: 20,
                color: Color(0xFF8CC5FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Continue Your Ascent',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Day $journeyDay · ${math.max(90 - journeyDay, 0)} days to summit',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingCard(BuildContext context, List<Mission> missions) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Mission? nextMission = missions.where((mission) => !mission.completed).isEmpty
        ? null
        : missions.firstWhere((mission) => !mission.completed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              LucideIcons.calendar,
              size: 14,
              color: const Color(0xFFA486FF),
            ),
            const SizedBox(width: 8),
            Text(
              'Upcoming',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A2A44),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE6EAF0),
            ),
            boxShadow: isDark
                ? const <BoxShadow>[]
                : <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1E9FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.users,
                  size: 17,
                  color: Color(0xFF7B58C9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      nextMission != null
                          ? 'Next Quest: ${nextMission.title}'
                          : 'Group Session: Anxiety Support',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF24324A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nextMission != null
                          ? nextMission.description
                          : 'Tomorrow',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.58)
                            : const Color(0xFF97A0AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _missionDurationText(Mission mission) {
    final RegExp durationPattern = RegExp(r'(\d+)\s*(min|minute|minutes|m)');
    final String source = '${mission.title} ${mission.description}'.toLowerCase();
    final RegExpMatch? match = durationPattern.firstMatch(source);
    if (match != null) {
      return '${match.group(1)} min';
    }
    return mission.completed ? 'Completed' : 'Tap to complete';
  }

  /// Shown once per visit for [Duration(seconds: 10)] — replaces the old welcome card + avatar row.
  Widget _buildEphemeralWelcomeBanner(BuildContext context, UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      color: isDark
          ? Colors.white.withOpacity(0.08)
          : Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(
              LucideIcons.sparkles,
              color: AppColors.green,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome back, ${user.username}!',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ready to focus and grow?',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
