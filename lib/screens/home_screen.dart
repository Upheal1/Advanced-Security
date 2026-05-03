import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/mission_model.dart';
import '../models/user_model.dart';
import '../models/focus_session_model.dart';
import '../models/streak_model.dart';
import '../constants/app_colors.dart';
import '../services/streak_service.dart';
import '../services/reward_orchestrator.dart' as rewards;
import '../gamification/xp_config.dart';
import '../widgets/rewards/xp_burst_overlay.dart';
import '../widgets/rewards/level_up_overlay.dart';
import '../widgets/rewards/streak_milestone_overlay.dart';
import '../widgets/rewards/badge_unlock_overlay.dart';
import '../widgets/rewards/urge_breathing_widget.dart';
import '../services/comeback_reward_service.dart';
import '../avatar/services/avatar_provider.dart';
import '../avatar/ui/avatar_widget.dart';
import 'focus_blocking_screen.dart';
import 'focus_session_screen.dart';
import 'notification_settings_screen.dart';
import 'profile_screen.dart';
import 'streak_screen.dart';
import 'ai_chat_screen.dart';
import '../widgets/drawer_menu_button.dart';
import '../widgets/mission_card.dart';

// Helper class to hold selected data for minimal rebuilds
class _HomeScreenData {
  final List missions;
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
  @override
  void initState() {
    super.initState();
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

  void _navigateToProfile() {
    // Navigate to profile page directly
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
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
        final completedMissions = missions.where((m) => m.completed).length;
        final totalMissions = missions.length;

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
                      builder: (context) =>
                          const NotificationSettingsScreen(),
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
                  // Welcome Section
                  _buildWelcomeCard(user),
                  const SizedBox(height: 20),

                  // Stats Section
                  _buildStatsSection(user),
                  const SizedBox(height: 20),

                  // Level Progress
                  _buildSectionCard(
                    title: 'Level Progress',
                    icon: LucideIcons.sparkles,
                    child: _buildLevelProgressBody(user),
                  ),
                  const SizedBox(height: 20),

                  // Daily Missions Section
                  _buildSectionCard(
                    title: 'Daily Missions',
                    icon: LucideIcons.target,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completedMissions of $totalMissions completed',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (missions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'No missions yet. you\'re all caught up!',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color:
                                    Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white70
                                        : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          ...missions
                              .map(
                                (m) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 12),
                                  child: MissionCard(mission: m),
                                ),
                              )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Focus & Blocking Section
                  _buildSectionCard(
                    title: 'Focus & Blocking',
                    icon: LucideIcons.shield,
                    child: Column(
                      children: [
                        // Quick Focus Session Button with active indicator
                        Consumer<FocusSessionState>(
                          builder: (context, focusState, child) {
                            return _buildFocusSessionButton(focusState);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureButton(
                          icon: LucideIcons.shield,
                          title: 'Smart Blocking',
                          subtitle: 'Block apps & adult content automatically',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const FocusBlockingScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // AI Coach Section
                  _buildAICoachCard(),
                  const SizedBox(height: 20),

                  // Claim XP Button
                  _buildClaimXPButton(user),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(UserModel user) {
    final avatarProvider = context.watch<AvatarProvider>();
    final avatarConfig = avatarProvider.config;
    final avatarMood = avatarProvider.mood;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: RepaintBoundary(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: AvatarWidget(
                    size: 60,
                    config: avatarConfig,
                    mood: avatarMood,
                    avatarAssetPath: avatarProvider.selectedAvatarAsset,
                    onTap: () => Navigator.of(context).pushNamed('/avatar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${user.username}!',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready to focus and grow?',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.7)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(UserModel user) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Navigate to streak page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const StreakScreen(),
                ),
              );
            },
            child: Consumer<StreakState>(
              builder: (context, streakState, child) {
                return _buildStatCard(
                  icon: LucideIcons.flame,
                  label: 'Streak',
                  value: streakState.isLoading
                      ? '...'
                      : '${streakState.currentStreak}',
                  color: AppColors.orange,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Navigate to profile page (index 10) which shows badges and streak
              _navigateToProfile();
            },
            child: _buildStatCard(
              icon: LucideIcons.award,
              label: 'Badges',
              value: '${user.badges}',
              color: AppColors.warning,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: LucideIcons.trophy,
            label: 'Rank',
            value: '#${user.rank}',
            color: const Color(0xFF7C3AED),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelProgressBody(UserModel user) {
    final level = user.level;
    final currentLevelTotalXp = XpConfig.totalXpForLevel(level);
    final nextLevelTotalXp = XpConfig.totalXpForLevel(level + 1);
    final levelSpanXp =
        (nextLevelTotalXp - currentLevelTotalXp).clamp(1, 1 << 31);
    final withinLevelXp =
        (user.xp - currentLevelTotalXp).clamp(0, levelSpanXp);
    final progress = withinLevelXp / levelSpanXp;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 10,
          backgroundColor: isDark
              ? Colors.white.withOpacity(0.12)
              : AppColors.textPrimary.withOpacity(0.08),
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.green),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$withinLevelXp / $levelSpanXp XP',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            Text(
              '$pct%',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: color.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.7)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildAICoachCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
              ),
            ),
            child: const Icon(
              LucideIcons.bot,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Coach',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tip: Short sprints beat long grinds. Try a 10m focus now.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.7)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AiChatScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Try',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusSessionButton(FocusSessionState focusState) {
    final isActive = focusState.isActive || focusState.isPaused;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FocusSessionScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive
                ? [
                    const Color(0xFF7C3AED).withOpacity(0.2),
                    const Color(0xFF7C3AED).withOpacity(0.1),
                  ]
                : isDark
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
            color: isActive
                ? const Color(0xFF7C3AED)
                : isDark
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.textPrimary.withOpacity(0.1),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isActive
                      ? [const Color(0xFF7C3AED), const Color(0xFF9333EA)]
                      : [const Color(0xFF7C3AED), const Color(0xFFF97316)],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    isActive ? LucideIcons.timer : LucideIcons.focus,
                    color: Colors.white,
                    size: 24,
                  ),
                  if (isActive)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: focusState.isPaused
                              ? Colors.orange
                              : const Color(0xFF10B981),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Focus Session Active' : 'Start Focus Session',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive
                        ? focusState.currentSession?.formattedTime ?? 'Running'
                        : 'Pomodoro timer with app blocking',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isActive
                          ? const Color(0xFF7C3AED)
                          : (isDark ? Colors.white70 : AppColors.textSecondary),
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isActive ? LucideIcons.arrowRight : LucideIcons.play,
              color: isActive
                  ? const Color(0xFF7C3AED)
                  : (isDark ? Colors.white54 : AppColors.textSecondary),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.arrowRight,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimXPButton(UserModel user) {
    return Consumer<StreakState>(
      builder: (context, streakState, child) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () async {
              final completed = context.read<MissionsModel>().completedCount;
              if (completed > 0) {
                final xpEarned = completed * 10;
                final userModel = context.read<UserModel>();
                final rewardsOrchestrator =
                    context.read<rewards.RewardOrchestrator>();

                final previousLevel = userModel.level;

                // Add XP to user model
                userModel.addXp(xpEarned);

                final newXp = userModel.xp;
                final newLevel = userModel.level;

                // Queue XP gained reward
                final nextLevelTotalXp = XpConfig.totalXpForLevel(newLevel + 1);
                final xpNeeded =
                    (nextLevelTotalXp - newXp).clamp(0, nextLevelTotalXp);

                rewardsOrchestrator.queueReward(
                  rewards.XpGained(
                    amount: xpEarned,
                    newTotal: newXp,
                    xpNeeded: xpNeeded,
                    level: newLevel,
                  ),
                );

                // Queue level-up reward if level changed
                if (newLevel > previousLevel) {
                  rewardsOrchestrator.queueReward(
                    rewards.LevelUp(
                      newLevel: newLevel,
                      newTitle: 'Level $newLevel',
                    ),
                  );
                }

                // Record challenge activity in streak service
                // This will automatically update the streak count
                await StreakService.recordActivity(
                  StreakActivityType.challenge,
                  xpEarned: xpEarned,
                );

                // Sync UserModel streak with StreakState for consistency
                final newStreak = context.read<StreakState>().currentStreak;
                context.read<UserModel>().setStreak(newStreak);

                // Queue streak milestone reward for key thresholds
                const milestones = [7, 14, 30, 60, 90];
                if (milestones.contains(newStreak)) {
                  rewardsOrchestrator.queueReward(
                    rewards.StreakMilestone(
                      days: newStreak,
                      label: '$newStreak-day streak',
                    ),
                  );
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Great work! +$xpEarned XP • Streak: $newStreak 🔥'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }

                // Show any queued rewards via overlays/snackbars
                if (mounted) {
                  _checkAndShowRewards(context);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Complete at least one mission first!'),
                    backgroundColor: AppColors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(LucideIcons.sparkles),
            label: Text(
              streakState.isTodayCompleted
                  ? 'Streak Secured! 🔥'
                  : 'Claim Daily XP',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: streakState.isTodayCompleted
                  ? AppColors.success
                  : AppColors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  void _checkAndShowRewards(BuildContext context) {
    final orchestrator = context.read<rewards.RewardOrchestrator>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final streakState = context.read<StreakState>();

    while (orchestrator.hasPending) {
      final event = orchestrator.consumeNext();
      if (event == null) break;

      if (event is rewards.XpGained) {
        // Use the new overlay widget (non-blocking).
        XpBurstOverlay.show(
          context,
          amount: event.amount,
          oldXp: (event.newTotal - event.amount).clamp(0, event.newTotal),
          newXp: event.newTotal,
          xpNeeded: event.xpNeeded,
          level: event.level,
        );
      } else if (event is rewards.LevelUp) {
        LevelUpOverlay.show(
          context,
          newLevel: event.newLevel,
          title: event.newTitle,
        );
      } else if (event is rewards.StreakMilestone) {
        StreakMilestoneOverlay.show(
          context,
          days: event.days,
          label: event.label,
          freezeTokens: streakState.freezeTokens,
        );
      } else if (event is rewards.BadgeUnlocked) {
        BadgeUnlockOverlay.show(
          context,
          badgeId: event.badgeId,
          badgeName: event.badgeName,
          emoji: event.emoji,
        );
      } else if (event is rewards.UrgeResisted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'You held off for ${event.secondsHeld} seconds. That\'s strength.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
