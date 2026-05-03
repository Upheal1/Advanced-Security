import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/insight_model.dart';
import '../features/steps/state/step_tracker_state.dart';
import '../models/sleep_model.dart';
import '../services/insights_service.dart';
import '../services/ai_insight_generator.dart';
import '../services/screen_time_service.dart';
import '../widgets/insights/insight_card.dart';
import '../features/steps/state/step_tracker_state.dart';
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> 
    with SingleTickerProviderStateMixin {
  List<Insight> _insights = [];
  InsightsSummary? _summary;
  bool _isLoading = true;
  bool _isGenerating = false;
  InsightCategory? _selectedCategory;
  InsightType? _selectedType;
  late AnimationController _refreshController;
  
  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _loadInsights();
  }
  
  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }
  
  Future<void> _loadInsights({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    
    try {
      // Get usage data
      final usageData = await ScreenTimeService.getRealUsageStats();
      final weeklyTrend = await ScreenTimeService.getDailyUsageForTrend();
      
      // Get optional data from providers if available
      Map<String, dynamic>? sleepData;
      Map<String, dynamic>? stepData;
      
      if (mounted) {
        try {
          final sleepModel = Provider.of<SleepModel>(context, listen: false);
          sleepData = {
            'totalMinutes': sleepModel.totalSleepToday,
            'averageMinutes': sleepModel.averageSleepDuration,
          };
        } catch (_) {}
        
        try {
          final stepState = Provider.of<StepTrackerState>(context, listen: false);
          stepData = {
            'todaySteps': stepState.todayStepCount,
            'goalSteps': stepState.dailyGoal,
            'weeklySteps': stepState.stepHistory
                .where((data) => data.date.isAfter(DateTime.now().subtract(const Duration(days: 7))))
                .fold(0, (sum, data) => sum + data.steps),
          };
        } catch (_) {}
      }
      
      // Generate insights from both services
      final baseInsights = await InsightsService.generateAllInsights(
        usageData: usageData,
        sleepData: sleepData,
        stepData: stepData,
        weeklyTrend: weeklyTrend,
        forceRefresh: forceRefresh,
      );
      
      final aiInsights = await AIInsightGenerator.generateIntelligentInsights(
        dailyUsage: usageData,
        weeklyTrend: weeklyTrend,
        sleepData: sleepData,
        stepData: stepData,
      );
      
      // Combine and deduplicate
      final allInsights = [...baseInsights, ...aiInsights];
      
      // Remove duplicates based on type and similar titles
      final uniqueInsights = <Insight>[];
      final seenTitles = <String>{};
      
      for (final insight in allInsights) {
        final normalizedTitle = insight.title.toLowerCase();
        if (!seenTitles.contains(normalizedTitle)) {
          seenTitles.add(normalizedTitle);
          uniqueInsights.add(insight);
        }
      }
      
      // Sort by priority and severity
      uniqueInsights.sort((a, b) {
        final priorityCompare = b.priority.index.compareTo(a.priority.index);
        if (priorityCompare != 0) return priorityCompare;
        return b.severity.index.compareTo(a.severity.index);
      });
      
      if (mounted) {
        setState(() {
          _insights = uniqueInsights;
          _summary = InsightsService.createSummary(uniqueInsights);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading insights: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _generateNewInsights() async {
    setState(() => _isGenerating = true);
    _refreshController.repeat();
    
    await _loadInsights(forceRefresh: true);
    
    _refreshController.stop();
    _refreshController.reset();
    setState(() => _isGenerating = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(
                '${_insights.length} insights generated!',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
  
  Future<void> _shareInsights() async {
    if (_insights.isEmpty || _summary == null) return;
    
    final buffer = StringBuffer();
    buffer.writeln('📊 My Digital Wellness Report');
    buffer.writeln('Generated on ${DateTime.now().toString().split(' ')[0]}');
    buffer.writeln('');
    buffer.writeln('🎯 Wellness Score: ${_summary!.overallHealthScore.toStringAsFixed(0)}/100 (${_summary!.healthStatus})');
    buffer.writeln('');
    buffer.writeln('📈 Key Insights:');
    
    // Add top 5 insights
    for (final insight in _insights.take(5)) {
      final emoji = _getInsightEmoji(insight);
      buffer.writeln('$emoji ${insight.title}');
      buffer.writeln('   ${insight.description}');
    }
    
    buffer.writeln('');
    buffer.writeln('Generated by UpHeal App');
    
    await Share.share(buffer.toString());
  }
  
  String _getInsightEmoji(Insight insight) {
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
  
  List<Insight> get _filteredInsights {
    return _insights.where((insight) {
      if (_selectedCategory != null && insight.category != _selectedCategory) {
        return false;
      }
      if (_selectedType != null && insight.type != _selectedType) {
        return false;
      }
      return true;
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isDark),
            
            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _insights.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildInsightsList(isDark),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingButtons(),
    );
  }
  
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    color: isDark ? Colors.white : Colors.grey[800],
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Insights',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    Text(
                      'Powered by intelligent analysis',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Share button
              IconButton(
                onPressed: _insights.isEmpty ? null : _shareInsights,
                icon: Icon(
                  LucideIcons.share2,
                  color: _insights.isEmpty 
                      ? Colors.grey[400] 
                      : (isDark ? Colors.white : Colors.grey[800]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1500.ms),
          const SizedBox(height: 24),
          Text(
            'Analyzing your data...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Finding patterns and insights',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.brainCircuit,
              size: 48,
              color: Colors.blue[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Insights Yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Use your device for a few days to generate personalized insights about your digital habits.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _generateNewInsights,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(LucideIcons.sparkles, size: 18),
            label: Text(
              'Generate Insights',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsightsList(bool isDark) {
    final filteredInsights = _filteredInsights;
    
    return RefreshIndicator(
      onRefresh: () => _loadInsights(forceRefresh: true),
      child: CustomScrollView(
        slivers: [
          // Summary card
          if (_summary != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: InsightsSummaryCard(
                  summary: _summary!,
                  onViewAll: null,
                ),
              ),
            ),
          
          // Category filter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InsightCategoryFilter(
                selectedCategory: _selectedCategory,
                onCategoryChanged: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),
            ),
          ),
          
          // Type filter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: InsightTypeFilter(
                selectedType: _selectedType,
                onTypeChanged: (type) {
                  setState(() => _selectedType = type);
                },
              ),
            ),
          ),
          
          // Results count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${filteredInsights.length} insights',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (_selectedCategory != null || _selectedType != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = null;
                          _selectedType = null;
                        });
                      },
                      child: Text(
                        'Clear filters',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Insights list
          if (filteredInsights.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.filter,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No insights match this filter',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final insight = filteredInsights[index];
                    return InsightCard(
                      insight: insight,
                      animationDelay: index * 50,
                      onAction: insight.isActionable
                          ? () => _handleInsightAction(insight)
                          : null,
                    );
                  },
                  childCount: filteredInsights.length,
                ),
              ),
            ),
          
          // Bottom padding for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFloatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Generate new insights button
        FloatingActionButton.extended(
          heroTag: 'generate',
          onPressed: _isGenerating ? null : _generateNewInsights,
          backgroundColor: Colors.blue,
          icon: _isGenerating
              ? RotationTransition(
                  turns: _refreshController,
                  child: const Icon(LucideIcons.refreshCw, size: 20),
                )
              : const Icon(LucideIcons.sparkles, size: 20),
          label: Text(
            _isGenerating ? 'Generating...' : 'Generate New',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
  
  void _handleInsightAction(Insight insight) {
    // Handle different action types
    if (insight.actionRoute != null) {
      // Navigate to specific route
      switch (insight.actionRoute) {
        case '/focus':
          // Navigate to focus session
          Navigator.of(context).pushNamed('/focus');
          break;
        default:
          // Show snackbar for unimplemented actions
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Action: ${insight.actionLabel}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } else if (insight.actionLabel != null) {
      // Show action dialog
      _showActionDialog(insight);
    }
  }
  
  void _showActionDialog(Insight insight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: insight.categoryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                insight.icon,
                color: insight.categoryColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              insight.title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              insight.detailedExplanation ?? insight.description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Implement specific actions based on insight type
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${insight.actionLabel} - Feature coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: insight.categoryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      insight.actionLabel ?? 'Take Action',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
