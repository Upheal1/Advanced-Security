import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/comparison_data.dart';
import '../services/comparison_service.dart';
import '../widgets/comparison/comparison_card.dart';
import '../widgets/common/loading_overlay.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  ComparisonType _selectedType = ComparisonType.weekVsWeek;
  ComparisonResult? _comparisonResult;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComparison();
  }

  Future<void> _loadComparison() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = _selectedType == ComparisonType.weekVsWeek
          ? await ComparisonService.getWeekComparison()
          : await ComparisonService.getMonthComparison();

      if (mounted) {
        setState(() {
          _comparisonResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load comparison data';
          _isLoading = false;
        });
      }
    }
  }

  void _onPeriodChanged(ComparisonType type) {
    if (type != _selectedType) {
      setState(() {
        _selectedType = type;
      });
      _loadComparison();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1B1B1B) : const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1B1B1B) : const Color(0xFFF8F5FF),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Usage Trends',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              LucideIcons.refreshCw,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: _loadComparison,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Loading trends...',
        child: _error != null
            ? _buildErrorState()
            : RefreshIndicator(
                onRefresh: _loadComparison,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(isDark),
                      const SizedBox(height: 20),
                      if (_comparisonResult != null) ...[
                        _buildInsightCard(),
                        const SizedBox(height: 20),
                        _buildOverviewCards(isDark),
                        const SizedBox(height: 24),
                        _buildTrendChart(isDark),
                        const SizedBox(height: 24),
                        _buildImprovedAppsSection(isDark),
                        const SizedBox(height: 24),
                        _buildRegressedAppsSection(isDark),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadComparison,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: PeriodSelectorButton(
              label: 'Week vs Week',
              isSelected: _selectedType == ComparisonType.weekVsWeek,
              onTap: () => _onPeriodChanged(ComparisonType.weekVsWeek),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PeriodSelectorButton(
              label: 'Month vs Month',
              isSelected: _selectedType == ComparisonType.monthVsMonth,
              onTap: () => _onPeriodChanged(ComparisonType.monthVsMonth),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildInsightCard() {
    if (_comparisonResult == null) return const SizedBox.shrink();

    return InsightCard(
      message: _comparisonResult!.insightMessage,
      trend: _comparisonResult!.overallTrend,
    );
  }

  Widget _buildOverviewCards(bool isDark) {
    if (_comparisonResult == null) return const SizedBox.shrink();

    final result = _comparisonResult!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ComparisonCard(
                title: 'Total Usage',
                currentValue: _formatDuration(result.current.totalUsageSeconds),
                previousValue: _formatDuration(result.previous.totalUsageSeconds),
                changePercent: result.totalChangePercent,
                trend: result.overallTrend,
                icon: LucideIcons.clock,
                onTap: () => _showDetailSheet(
                  'Total Usage Details',
                  'You spent ${_formatDuration(result.current.totalUsageSeconds)} ${_selectedType.currentLabel.toLowerCase()} compared to ${_formatDuration(result.previous.totalUsageSeconds)} ${_selectedType.previousLabel.toLowerCase()}.',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ComparisonCard(
                title: 'Daily Average',
                currentValue: _formatDuration(result.current.dailyAverageSeconds.round()),
                previousValue: _formatDuration(result.previous.dailyAverageSeconds.round()),
                changePercent: result.dailyAverageChangePercent,
                trend: ComparisonService.getTrendDirection(result.dailyAverageChangePercent),
                icon: LucideIcons.activity,
                onTap: () => _showDetailSheet(
                  'Daily Average Details',
                  'Your daily average is ${_formatDuration(result.current.dailyAverageSeconds.round())} ${_selectedType.currentLabel.toLowerCase()}, compared to ${_formatDuration(result.previous.dailyAverageSeconds.round())} ${_selectedType.previousLabel.toLowerCase()}.',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickStatCard(
                'Improved Apps',
                '${result.improvedApps.length}',
                LucideIcons.trendingDown,
                const Color(0xFF10B981),
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStatCard(
                'Increased Usage',
                '${result.regressedApps.length}',
                LucideIcons.trendingUp,
                const Color(0xFFEF4444),
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTrendChart(bool isDark) {
    if (_comparisonResult == null) return const SizedBox.shrink();

    final result = _comparisonResult!;
    final currentData = result.current.dailyUsage;
    final previousData = result.previous.dailyUsage;

    if (currentData.isEmpty && previousData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Prepare chart data
    final maxDays = currentData.length > previousData.length
        ? currentData.length
        : previousData.length;

    // Find max value for Y axis
    double maxY = 0;
    for (final point in currentData) {
      if (point.usageHours > maxY) maxY = point.usageHours;
    }
    for (final point in previousData) {
      if (point.usageHours > maxY) maxY = point.usageHours;
    }
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY < 1) maxY = 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.lineChart,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              const SizedBox(width: 8),
              Text(
                'Usage Trend',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            children: [
              _buildLegendItem(
                _selectedType.currentLabel,
                const Color(0xFF7C3AED),
                isDark,
              ),
              const SizedBox(width: 16),
              _buildLegendItem(
                _selectedType.previousLabel,
                const Color(0xFF9CA3AF),
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(1)}h',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < currentData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              currentData[index].dayLabel,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: isDark ? Colors.white38 : Colors.black38,
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
                maxX: (maxDays - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  // Current period line
                  LineChartBarData(
                    spots: List.generate(currentData.length, (i) {
                      return FlSpot(i.toDouble(), currentData[i].usageHours);
                    }),
                    isCurved: true,
                    color: const Color(0xFF7C3AED),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF7C3AED),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                    ),
                  ),
                  // Previous period line
                  LineChartBarData(
                    spots: List.generate(previousData.length, (i) {
                      return FlSpot(i.toDouble(), previousData[i].usageHours);
                    }),
                    isCurved: true,
                    color: const Color(0xFF9CA3AF),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dashArray: [5, 5],
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: const Color(0xFF9CA3AF),
                          strokeWidth: 0,
                        );
                      },
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        isDark ? const Color(0xFF3A3A3A) : Colors.white,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isCurrentPeriod = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)}h',
                          GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isCurrentPeriod
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF9CA3AF),
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 500.ms);
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildImprovedAppsSection(bool isDark) {
    if (_comparisonResult == null) return const SizedBox.shrink();

    final improvedApps = _comparisonResult!.topImproved(5);

    if (improvedApps.isEmpty) {
      return _buildEmptySection(
        'Most Improved Apps',
        'No improvements yet. Try setting some app limits!',
        LucideIcons.trendingDown,
        const Color(0xFF10B981),
        isDark,
      );
    }

    return _buildAppListSection(
      'Most Improved Apps 🎉',
      'Apps where you reduced usage',
      improvedApps,
      const Color(0xFF10B981),
      isDark,
    );
  }

  Widget _buildRegressedAppsSection(bool isDark) {
    if (_comparisonResult == null) return const SizedBox.shrink();

    final regressedApps = _comparisonResult!.topRegressed(5);

    if (regressedApps.isEmpty) {
      return _buildEmptySection(
        'Increased Usage Apps',
        'Great job! No apps with increased usage.',
        LucideIcons.trendingUp,
        const Color(0xFF10B981),
        isDark,
      );
    }

    return _buildAppListSection(
      'Needs Attention ⚠️',
      'Apps where usage increased',
      regressedApps,
      const Color(0xFFEF4444),
      isDark,
    );
  }

  Widget _buildAppListSection(
    String title,
    String subtitle,
    List<AppComparison> apps,
    Color color,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...apps.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppComparisonCard(
              comparison: entry.value,
              index: entry.key,
              onTap: () => _showAppDetailSheet(entry.value),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptySection(
    String title,
    String message,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 400.ms);
  }

  void _showDetailSheet(String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showAppDetailSheet(AppComparison app) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isImprovement = app.isImprovement;
    final color = isImprovement
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isImprovement ? LucideIcons.trendingDown : LucideIcons.trendingUp,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.appName,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          app.packageName,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildStatRow(
                '${_selectedType.currentLabel}:',
                app.currentUsageFormatted,
                isDark,
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                '${_selectedType.previousLabel}:',
                app.previousUsageFormatted,
                isDark,
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                'Change:',
                app.differenceFormatted,
                isDark,
                valueColor: color,
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                'Percentage:',
                '${app.changePercent >= 0 ? '+' : ''}${app.changePercent.toStringAsFixed(1)}%',
                isDark,
                valueColor: color,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isImprovement ? LucideIcons.partyPopper : LucideIcons.target,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isImprovement
                            ? 'Great progress! Keep it up!'
                            : 'Consider setting a daily limit for this app.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).round()}m';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }
}
