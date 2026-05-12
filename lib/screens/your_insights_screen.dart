import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/streak_model.dart';
import '../models/insight_model.dart';
import '../services/ai_insight_generator.dart';
import '../services/insights_service.dart';
import '../services/screen_time_service.dart';
import '../widgets/drawer_menu_button.dart';

/// Wellness insights dashboard — layout aligned with product mockups (stats, charts, AI cards).
class YourInsightsScreen extends StatefulWidget {
  const YourInsightsScreen({super.key});

  @override
  State<YourInsightsScreen> createState() => _YourInsightsScreenState();
}

class _YourInsightsScreenState extends State<YourInsightsScreen> {
  static const _bgLight = Color(0xFFF8F9FB);
  static const _cardLight = Colors.white;
  static const _titleDark = Color(0xFF1A1C1E);
  static const _muted = Color(0xFF7C7C7C);
  static const _moodGreen = Color(0xFF22C55E);
  static const _chartBlue = Color(0xFF3B82F6);

  int _periodIndex = 0; // 0 Week, 1 Month, 2 Three months

  static const _daysShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  bool _loading = true;
  List<double> _moodY = const [2.2, 3.1, 2.8, 4.2, 3.6, 4.8, 4.4]; // fallback
  List<double> _screenHours = const [0, 0, 0, 0, 0, 0, 0];
  List<String> _dayLabels = _daysShort;
  double _todayScreenHours = 0;
  double _periodAvgScreenHours = 0;
  double _socialRatio = 0; // 0..1
  List<Insight> _aiCards = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  int get _periodDays {
    switch (_periodIndex) {
      case 1:
        return 30;
      case 2:
        return 90;
      default:
        return 7;
    }
  }

  String get _screenPeriodKey {
    switch (_periodIndex) {
      case 1:
        return 'monthly';
      case 2:
        return '3months';
      default:
        return 'weekly';
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Today usage + last-7-days trend (used for bars regardless of selected period).
      final usageToday = await ScreenTimeService.getRealUsageStats();
      final trend7 = await ScreenTimeService.getDailyUsageForTrend();

      final todayTotalMs = usageToday.fold<int>(
        0,
        (sum, a) => sum + ((a['usageTime'] as int?) ?? 0),
      );
      final todayHours = todayTotalMs / (1000 * 60 * 60);

      // Period totals (week/month/3mo) for the Screen Time tile.
      final periodApps = await ScreenTimeService.getAccurateUsageStats(
        period: _screenPeriodKey,
      );
      final periodTotalMs = periodApps.fold<int>(
        0,
        (sum, a) => sum + ((a['usageTime'] as int?) ?? 0),
      );
      final periodTotalHours = periodTotalMs / (1000 * 60 * 60);
      final periodAvg = _periodDays == 0 ? 0.0 : (periodTotalHours / _periodDays);

      // Approx social ratio for the radar (based on today's usage categories).
      final socialMs = usageToday
          .where((a) => (a['category'] as String?) == 'Social')
          .fold<int>(0, (sum, a) => sum + ((a['usageTime'] as int?) ?? 0));
      final socialRatio = todayTotalMs <= 0 ? 0.0 : (socialMs / todayTotalMs).clamp(0.0, 1.0);

      // Screen-time bars from 7-day trend.
      final bars = List<double>.generate(7, (i) {
        if (i >= trend7.length) return 0;
        return (trend7[i]['totalHours'] as double?) ?? 0.0;
      });
      final dayLabels = List<String>.generate(7, (i) {
        if (i >= trend7.length) return _daysShort[i];
        final dt = trend7[i]['date'] as DateTime?;
        if (dt == null) return _daysShort[i];
        final s = DateFormat('E').format(dt);
        return s.isEmpty ? _daysShort[i] : s.substring(0, 1).toUpperCase();
      });

      // Generate 3 AI cards (mix base + AI generators).
      final base = await InsightsService.generateAllInsights(
        usageData: usageToday,
        weeklyTrend: trend7,
        forceRefresh: false,
      );
      final ai = await AIInsightGenerator.generateIntelligentInsights(
        dailyUsage: usageToday,
        weeklyTrend: trend7,
      );
      final combined = [...base, ...ai];
      combined.sort((a, b) {
        final p = b.priority.index.compareTo(a.priority.index);
        if (p != 0) return p;
        return b.severity.index.compareTo(a.severity.index);
      });

      if (!mounted) return;
      setState(() {
        _todayScreenHours = todayHours;
        _periodAvgScreenHours = periodAvg;
        _socialRatio = socialRatio;
        _screenHours = bars;
        _dayLabels = dayLabels;
        _aiCards = combined.take(3).toList(growable: false);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String get _periodSubtitle {
    switch (_periodIndex) {
      case 1:
        return 'Month overview';
      case 2:
        return 'Quarter overview';
      default:
        return '7-day overview';
    }
  }

  String get _moodBadge {
    switch (_periodIndex) {
      case 1:
        return '↗ +8%';
      case 2:
        return '↗ +5%';
      default:
        return '↗ +12%';
    }
  }

  String get _screenBadge {
    // Keep badge deterministic; avoid fake % until we have previous-period data.
    if (_todayScreenHours <= 0) return '–';
    return _todayScreenHours <= 5 ? '✓ on track' : '⚠ above goal';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0D12) : _bgLight;
    final card = isDark ? const Color(0xFF16191F) : _cardLight;
    final onCard = isDark ? Colors.white : _titleDark;
    final subtle = isDark ? Colors.white54 : _muted;

    final xpFmt = NumberFormat.decimalPattern();
    final streakState = context.watch<StreakState>();
    final periodDays = _periodDays;
    final periodStreak = streakState.currentStreak.clamp(0, periodDays);
    final periodXp = streakState.getXpEarnedInLastDays(periodDays);
    final totalXp = streakState.totalXpEarned;

    final screenTileValue = _periodAvgScreenHours <= 0
        ? '0.0 hrs'
        : '${_periodAvgScreenHours.toStringAsFixed(1)} hrs';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: DrawerMenuButton(
          iconColor: isDark ? Colors.white : AppColors.textPrimary,
        ),
        title: const SizedBox.shrink(),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Insights',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: onCard,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Track your wellness journey',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: subtle,
              ),
            ),
            const SizedBox(height: 20),
            _PeriodToggle(
              selectedIndex: _periodIndex,
              onChanged: (i) {
                setState(() => _periodIndex = i);
                _load();
              },
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            if (_loading) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Updating insights…',
                  style: GoogleFonts.inter(fontSize: 13, color: subtle),
                ),
              ),
            ],
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                _SummaryTile(
                  cardColor: card,
                  icon: LucideIcons.flame,
                  iconBg: const Color(0xFFFFF4E6),
                  iconColor: const Color(0xFFF97316),
                  value: '$periodStreak days',
                  label: 'Current Streak',
                  footer: periodStreak == streakState.longestStreak && periodStreak > 0
                      ? 'Personal best!'
                      : 'All-time best: ${streakState.longestStreak}',
                  footerColor: const Color(0xFFF97316),
                  isDark: isDark,
                ),
                _SummaryTile(
                  cardColor: card,
                  icon: LucideIcons.zap,
                  iconBg: const Color(0xFFFFF9DB),
                  iconColor: const Color(0xFFEAB308),
                  value: xpFmt.format(periodXp),
                  label: 'XP Earned',
                  footer: 'All-time: ${xpFmt.format(totalXp)}',
                  footerColor: const Color(0xFFB45309),
                  isDark: isDark,
                ),
                _SummaryTile(
                  cardColor: card,
                  icon: LucideIcons.target,
                  iconBg: const Color(0xFFE8F8EF),
                  iconColor: const Color(0xFF22C55E),
                  value: '18/24',
                  label: 'Tasks Done',
                  footer: '75% completion',
                  footerColor: subtle,
                  isDark: isDark,
                ),
                _SummaryTile(
                  cardColor: card,
                  icon: LucideIcons.clock,
                  iconBg: const Color(0xFFE8F1FE),
                  iconColor: _chartBlue,
                  value: screenTileValue,
                  label: 'Screen Time',
                  footer: 'Today: ${_todayScreenHours.toStringAsFixed(1)}h · Goal: 5h',
                  footerColor: subtle,
                  footerAccent: _chartBlue,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ChartCard(
              cardColor: card,
              isDark: isDark,
              title: 'Mood Trend',
              subtitle: _periodSubtitle,
              badgeText: _moodBadge,
              badgeFg: const Color(0xFF166534),
              badgeBg: const Color(0xFFD1FAE5),
              child: SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: isDark ? Colors.white12 : const Color(0xFFE8EAED),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value == 1 || value == 3 || value == 5) {
                              return Text(
                                value.toInt().toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: subtle,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i >= 0 && i < _daysShort.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _dayLabels[i],
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: subtle,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: 6,
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          _moodY.length,
                          (i) => FlSpot(i.toDouble(), _moodY[i]),
                        ),
                        isCurved: true,
                        color: _moodGreen,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                            radius: 4,
                            color: _moodGreen,
                            strokeWidth: 2,
                            strokeColor:
                                isDark ? const Color(0xFF16191F) : Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _moodGreen.withValues(alpha: 0.28),
                              _moodGreen.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: const LineTouchData(enabled: false),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ChartCard(
              cardColor: card,
              isDark: isDark,
              title: 'Screen Time',
              subtitle: 'Daily hours',
              badgeText: _screenBadge,
              badgeFg: const Color(0xFF1E40AF),
              badgeBg: const Color(0xFFDBEAFE),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 10,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 5,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: isDark ? Colors.white12 : const Color(0xFFE8EAED),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final v = value.round();
                                if (v == 3 || v == 10) {
                                  return Text(
                                    '$v',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: subtle,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i >= 0 && i < _daysShort.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      _dayLabels[i],
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: subtle,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          _screenHours.length,
                          (i) => BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: _screenHours[i],
                                width: 14,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                                color: _chartBlue.withValues(alpha: 0.55),
                              ),
                            ],
                          ),
                        ),
                        barTouchData: BarTouchData(
                          enabled: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_todayScreenHours / 5.0).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor:
                          isDark ? Colors.white12 : const Color(0xFFE8EAED),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_chartBlue),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Goal: 5h/day · Today: ${_todayScreenHours.toStringAsFixed(1)}h',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: subtle,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle_rounded,
                          size: 18, color: _chartBlue.withValues(alpha: 0.85)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _WellnessRadarCard(
              cardColor: card,
              isDark: isDark,
              focus: (100 - (_todayScreenHours * 10)).clamp(0, 100).toDouble(),
              calm: (100 - (_socialRatio * 100)).clamp(0, 100).toDouble(),
              sleep: 70,
              social: (_socialRatio * 100).clamp(0, 100).toDouble(),
              habits: (streakState.getCompletionRate(periodDays) * 100).clamp(0, 100),
              energy: 65,
            ),
            const SizedBox(height: 24),
            Text(
              'AI INSIGHTS',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: subtle,
              ),
            ),
            const SizedBox(height: 12),
            if (_aiCards.isEmpty)
              _AiInsightRow(
                emoji: '✨',
                text: 'Use your device for a bit and come back for insights.',
                bg: isDark ? const Color(0xFF151E2E) : const Color(0xFFE8F1FE),
                border: _chartBlue,
                isDark: isDark,
              )
            else ...[
              for (int i = 0; i < _aiCards.length; i++) ...[
                _AiInsightRow(
                  emoji: _emojiForInsight(_aiCards[i]),
                  text: _aiCards[i].description,
                  bg: _bgForInsight(_aiCards[i], isDark),
                  border: _borderForInsight(_aiCards[i]),
                  isDark: isDark,
                ),
                if (i != _aiCards.length - 1) const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _emojiForInsight(Insight insight) {
    switch (insight.category) {
      case InsightCategory.positive:
        return '✅';
      case InsightCategory.neutral:
        return 'ℹ️';
      case InsightCategory.warning:
        return '⚠️';
      case InsightCategory.critical:
        return '🔴';
    }
  }

  Color _borderForInsight(Insight insight) {
    return insight.categoryColor;
  }

  Color _bgForInsight(Insight insight, bool isDark) {
    final base = insight.categoryColor;
    if (isDark) return base.withValues(alpha: 0.12);
    return base.withValues(alpha: 0.10);
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({
    required this.selectedIndex,
    required this.onChanged,
    required this.isDark,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final labels = ['Week', 'Month', '3 Months'];
    final track = isDark ? const Color(0xFF1E2329) : const Color(0xFFEEF1F4);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final sel = selectedIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel
                      ? (isDark ? const Color(0xFF2A3038) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                    color: sel
                        ? (isDark ? Colors.white : _YourInsightsScreenState._titleDark)
                        : _YourInsightsScreenState._muted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.cardColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.footer,
    required this.footerColor,
    required this.isDark,
    this.footerAccent,
  });

  final Color cardColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String footer;
  final Color footerColor;
  final bool isDark;
  final Color? footerAccent;

  @override
  Widget build(BuildContext context) {
    final title = isDark ? Colors.white : _YourInsightsScreenState._titleDark;
    final muted = isDark ? Colors.white54 : _YourInsightsScreenState._muted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? iconColor.withValues(alpha: 0.2) : iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: title,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            footer,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: footerAccent ?? footerColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.cardColor,
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeFg,
    required this.badgeBg,
    required this.child,
  });

  final Color cardColor;
  final bool isDark;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeFg;
  final Color badgeBg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleColor =
        isDark ? Colors.white : _YourInsightsScreenState._titleDark;
    final muted = isDark ? Colors.white54 : _YourInsightsScreenState._muted;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: badgeFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _WellnessRadarCard extends StatelessWidget {
  const _WellnessRadarCard({
    required this.cardColor,
    required this.isDark,
    required this.focus,
    required this.calm,
    required this.sleep,
    required this.social,
    required this.habits,
    required this.energy,
  });

  final Color cardColor;
  final bool isDark;
  final double focus;
  final double calm;
  final double sleep;
  final double social;
  final double habits;
  final double energy;

  static const _titles = [
    'Focus',
    'Calm',
    'Sleep',
    'Social',
    'Habits',
    'Energy',
  ];

  @override
  Widget build(BuildContext context) {
    final titleColor =
        isDark ? Colors.white : _YourInsightsScreenState._titleDark;
    final muted = isDark ? Colors.white54 : _YourInsightsScreenState._muted;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wellness Radar',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your skill map this month',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.brain,
                    color: AppColors.purple, size: 20),
              ),
            ],
          ),
          SizedBox(
            height: 260,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                dataSets: [
                  RadarDataSet(
                    dataEntries: [
                      RadarEntry(value: focus),
                      RadarEntry(value: calm),
                      RadarEntry(value: sleep),
                      RadarEntry(value: social),
                      RadarEntry(value: habits),
                      RadarEntry(value: energy),
                    ],
                    fillColor: _YourInsightsScreenState._chartBlue
                        .withValues(alpha: 0.22),
                    borderColor: _YourInsightsScreenState._chartBlue,
                    borderWidth: 2,
                    entryRadius: 3,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                radarBorderData: BorderSide(
                  color: isDark ? Colors.white24 : const Color(0xFFE0E3E8),
                  width: 1,
                ),
                gridBorderData: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFE8EAED),
                  width: 1,
                ),
                tickBorderData: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFE8EAED),
                  width: 1,
                ),
                tickCount: 3,
                ticksTextStyle: GoogleFonts.inter(
                  fontSize: 9,
                  color: muted,
                ),
                titleTextStyle: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
                titlePositionPercentageOffset: 0.12,
                getTitle: (index, angle) {
                  return RadarChartTitle(
                    text: _titles[index],
                    angle: angle,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiInsightRow extends StatelessWidget {
  const _AiInsightRow({
    required this.emoji,
    required this.text,
    required this.bg,
    required this.border,
    required this.isDark,
  });

  final String emoji;
  final String text;
  final Color bg;
  final Color border;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? Colors.white.withValues(alpha: 0.92) : _YourInsightsScreenState._titleDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
