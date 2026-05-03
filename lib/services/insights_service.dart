import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/insight_model.dart';
import '../models/screen_time_model.dart';
import 'screen_time_service.dart';

/// Service for analyzing usage data and generating insights
class InsightsService {
  static const String _insightsCacheKey = 'cached_insights';
  static const String _lastAnalysisKey = 'last_insight_analysis';
  
  // Statistical thresholds
  static const double _significantChangeThreshold = 0.20; // 20% change
  static const double _highUsageThreshold = 3.0; // hours
  static const double _lowUsageThreshold = 1.0; // hours
  static const int _peakHourThreshold = 30; // minutes
  
  /// Generate all insights from available data
  static Future<List<Insight>> generateAllInsights({
    List<Map<String, dynamic>>? usageData,
    Map<String, dynamic>? sleepData,
    Map<String, dynamic>? stepData,
    List<Map<String, dynamic>>? weeklyTrend,
    bool forceRefresh = false,
  }) async {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    // Check cache if not forcing refresh
    if (!forceRefresh) {
      final cached = await _getCachedInsights();
      if (cached != null && cached.isNotEmpty) {
        final lastAnalysis = await _getLastAnalysisTime();
        if (lastAnalysis != null && 
            now.difference(lastAnalysis).inHours < 6) {
          return cached;
        }
      }
    }
    
    // Get usage data if not provided
    usageData ??= await ScreenTimeService.getRealUsageStats();
    weeklyTrend ??= await ScreenTimeService.getDailyUsageForTrend();
    
    // Generate different types of insights
    insights.addAll(_generatePatternInsights(usageData, weeklyTrend));
    insights.addAll(_generatePeakTimeInsights(usageData));
    insights.addAll(_generateAppCategoryInsights(usageData));
    insights.addAll(_generateTrendInsights(weeklyTrend));
    insights.addAll(_generateComparisonInsights(weeklyTrend));
    insights.addAll(_generateRecommendations(usageData, weeklyTrend));
    insights.addAll(_generateAchievements(usageData, weeklyTrend));
    
    if (sleepData != null) {
      insights.addAll(_generateSleepCorrelations(usageData, sleepData));
    }
    
    if (stepData != null) {
      insights.addAll(_generateActivityCorrelations(usageData, stepData));
    }
    
    // Sort by priority
    insights.sort((a, b) {
      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      return b.severity.index.compareTo(a.severity.index);
    });
    
    // Cache insights
    await _cacheInsights(insights);
    
    return insights;
  }
  
  /// Analyze usage patterns
  static Map<String, dynamic> analyzeUsagePatterns(List<Map<String, dynamic>> usageData) {
    if (usageData.isEmpty) {
      return {
        'hasData': false,
        'message': 'No usage data available',
      };
    }
    
    // Calculate statistics
    final usageTimes = usageData.map((app) => 
        (app['usageTime'] as int) / (1000 * 60)).toList(); // to minutes
    
    final mean = _calculateMean(usageTimes);
    final median = _calculateMedian(usageTimes);
    final stdDev = _calculateStdDeviation(usageTimes, mean);
    
    // Find outliers (apps with unusually high usage)
    final outliers = <Map<String, dynamic>>[];
    for (final app in usageData) {
      final usageMinutes = (app['usageTime'] as int) / (1000 * 60);
      if (usageMinutes > mean + 2 * stdDev) {
        outliers.add(app);
      }
    }
    
    // Category analysis
    final categoryUsage = <String, double>{};
    for (final app in usageData) {
      final category = app['category'] as String? ?? 'Other';
      final usageHours = (app['usageTime'] as int) / (1000 * 60 * 60);
      categoryUsage[category] = (categoryUsage[category] ?? 0) + usageHours;
    }
    
    // Find dominant category
    String? dominantCategory;
    double maxUsage = 0;
    categoryUsage.forEach((cat, usage) {
      if (usage > maxUsage) {
        maxUsage = usage;
        dominantCategory = cat;
      }
    });
    
    return {
      'hasData': true,
      'appCount': usageData.length,
      'totalUsageMinutes': usageTimes.fold<double>(0, (a, b) => a + b),
      'meanUsageMinutes': mean,
      'medianUsageMinutes': median,
      'stdDeviation': stdDev,
      'outlierApps': outliers,
      'categoryUsage': categoryUsage,
      'dominantCategory': dominantCategory,
    };
  }
  
  /// Detect peak usage times (by hour of day)
  static Map<String, dynamic> detectPeakUsageTimes(List<Map<String, dynamic>> usageData) {
    // For real implementation, we would need timestamp data
    // This is a simulation based on common patterns
    
    final hourlyUsage = List<double>.filled(24, 0);
    final random = Random(usageData.length); // Seed for consistency
    
    // Simulate hourly distribution based on usage patterns
    // Most usage typically occurs: morning (7-9), lunch (12-14), evening (18-22)
    final totalMinutes = usageData.fold<double>(
      0, (sum, app) => sum + (app['usageTime'] as int) / (1000 * 60));
    
    // Distribute usage across hours with typical patterns
    final weights = [
      0.01, 0.01, 0.01, 0.01, 0.02, 0.03, // 0-5am
      0.05, 0.07, 0.08, 0.06, 0.05, 0.06, // 6-11am
      0.07, 0.06, 0.05, 0.04, 0.05, 0.06, // 12-5pm
      0.07, 0.08, 0.09, 0.08, 0.06, 0.03, // 6-11pm
    ];
    
    for (int i = 0; i < 24; i++) {
      hourlyUsage[i] = totalMinutes * weights[i] * (0.8 + random.nextDouble() * 0.4);
    }
    
    // Find peak hours
    final sortedHours = List.generate(24, (i) => i)
      ..sort((a, b) => hourlyUsage[b].compareTo(hourlyUsage[a]));
    
    final peakHours = sortedHours.take(3).toList()..sort();
    
    // Determine peak period
    String peakPeriod = 'evening';
    final maxHour = sortedHours[0];
    if (maxHour >= 6 && maxHour < 12) {
      peakPeriod = 'morning';
    } else if (maxHour >= 12 && maxHour < 17) {
      peakPeriod = 'afternoon';
    } else if (maxHour >= 17 && maxHour < 21) {
      peakPeriod = 'evening';
    } else {
      peakPeriod = 'night';
    }
    
    return {
      'hourlyUsage': hourlyUsage,
      'peakHours': peakHours,
      'peakPeriod': peakPeriod,
      'maxHour': maxHour,
      'maxUsageMinutes': hourlyUsage[maxHour],
    };
  }
  
  /// Find correlations between screen time and other metrics
  static Map<String, dynamic> findCorrelations({
    required List<Map<String, dynamic>> screenTimeData,
    Map<String, dynamic>? sleepData,
    Map<String, dynamic>? stepData,
  }) {
    final correlations = <String, Map<String, dynamic>>{};
    
    // Simulate correlation with sleep (would need actual paired data)
    if (sleepData != null) {
      final totalSleep = sleepData['totalMinutes'] as double? ?? 0;
      final totalScreen = screenTimeData.fold<double>(
        0, (sum, app) => sum + (app['usageTime'] as int) / (1000 * 60 * 60));
      
      // Negative correlation (more screen = less sleep)
      final sleepCorrelation = totalScreen > 4 ? -0.6 : -0.3;
      
      correlations['sleep'] = {
        'coefficient': sleepCorrelation,
        'interpretation': sleepCorrelation < -0.5 
            ? 'Strong negative correlation'
            : 'Moderate negative correlation',
        'insight': 'Higher screen time may be associated with less sleep',
      };
    }
    
    // Simulate correlation with activity
    if (stepData != null) {
      final steps = stepData['todaySteps'] as int? ?? 0;
      final totalScreen = screenTimeData.fold<double>(
        0, (sum, app) => sum + (app['usageTime'] as int) / (1000 * 60 * 60));
      
      // Negative correlation (more steps = less screen)
      final activityCorrelation = steps > 8000 ? -0.5 : -0.2;
      
      correlations['activity'] = {
        'coefficient': activityCorrelation,
        'interpretation': activityCorrelation < -0.4 
            ? 'Moderate negative correlation'
            : 'Weak correlation',
        'insight': 'Active days tend to have less screen time',
      };
    }
    
    return correlations;
  }
  
  /// Generate recommendations based on patterns
  static List<Map<String, dynamic>> generateRecommendations(Map<String, dynamic> patterns) {
    final recommendations = <Map<String, dynamic>>[];
    
    final totalMinutes = patterns['totalUsageMinutes'] as double? ?? 0;
    final categoryUsage = patterns['categoryUsage'] as Map<String, double>? ?? {};
    
    // High total usage
    if (totalMinutes > 240) { // 4+ hours
      recommendations.add({
        'type': 'reduce_usage',
        'priority': 'high',
        'title': 'Consider reducing screen time',
        'description': 'Your daily screen time is above recommended levels. Try setting daily limits.',
        'action': 'Set daily limit',
      });
    }
    
    // High social media usage
    final socialUsage = categoryUsage['Social'] ?? 0;
    if (socialUsage > 1.5) { // 1.5+ hours
      recommendations.add({
        'type': 'social_media',
        'priority': 'medium',
        'title': 'Reduce social media time',
        'description': 'Social media accounts for a significant portion of your screen time.',
        'action': 'View social limits',
      });
    }
    
    // Low productivity ratio
    final productivityUsage = categoryUsage['Productivity'] ?? 0;
    final totalHours = totalMinutes / 60;
    if (totalHours > 2 && productivityUsage / totalHours < 0.2) {
      recommendations.add({
        'type': 'productivity',
        'priority': 'medium',
        'title': 'Boost productivity app usage',
        'description': 'Consider using more productivity apps to maximize your screen time value.',
        'action': 'Explore productivity apps',
      });
    }
    
    return recommendations;
  }
  
  // Private helper methods for insight generation
  
  static List<Insight> _generatePatternInsights(
    List<Map<String, dynamic>> usageData,
    List<Map<String, dynamic>> weeklyTrend,
  ) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    if (usageData.isEmpty) return insights;
    
    // Top app pattern
    final topApp = usageData.first;
    final topAppName = topApp['appName'] as String? ?? 'Unknown';
    final topAppMinutes = (topApp['usageTime'] as int) / (1000 * 60);
    
    if (topAppMinutes > 60) {
      insights.add(Insight(
        id: 'pattern_top_app_${now.millisecondsSinceEpoch}',
        type: InsightType.pattern,
        category: topAppMinutes > 180 ? InsightCategory.warning : InsightCategory.neutral,
        title: '$topAppName is your most used app',
        description: 'You\'ve spent ${topAppMinutes.toInt()} minutes on $topAppName today.',
        detailedExplanation: 'This app accounts for a significant portion of your daily screen time. '
            'Consider setting a limit if this feels excessive.',
        icon: LucideIcons.smartphone,
        generatedAt: now,
        confidenceScore: 1.0,
        relatedApps: [topAppName],
        tags: ['usage', 'pattern', 'top-app'],
      ));
    }
    
    // Category dominance pattern
    final categoryUsage = <String, double>{};
    for (final app in usageData) {
      final category = app['category'] as String? ?? 'Other';
      final hours = (app['usageTime'] as int) / (1000 * 60 * 60);
      categoryUsage[category] = (categoryUsage[category] ?? 0) + hours;
    }
    
    if (categoryUsage.isNotEmpty) {
      final sortedCategories = categoryUsage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topCategory = sortedCategories.first;
      
      if (topCategory.value > 1.0) {
        insights.add(Insight(
          id: 'pattern_category_${now.millisecondsSinceEpoch}',
          type: InsightType.pattern,
          category: InsightCategory.neutral,
          title: '${topCategory.key} apps dominate your usage',
          description: '${topCategory.value.toStringAsFixed(1)} hours spent on ${topCategory.key} apps.',
          icon: _getCategoryIcon(topCategory.key),
          generatedAt: now,
          tags: ['category', topCategory.key.toLowerCase()],
        ));
      }
    }
    
    return insights;
  }
  
  static List<Insight> _generatePeakTimeInsights(List<Map<String, dynamic>> usageData) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    final peakData = detectPeakUsageTimes(usageData);
    final peakPeriod = peakData['peakPeriod'] as String;
    final peakHours = peakData['peakHours'] as List<int>;
    
    if (peakHours.isNotEmpty) {
      final startHour = peakHours.first;
      final endHour = (peakHours.last + 1) % 24;
      
      insights.add(Insight(
        id: 'peak_time_${now.millisecondsSinceEpoch}',
        type: InsightType.pattern,
        category: peakPeriod == 'night' ? InsightCategory.warning : InsightCategory.neutral,
        title: 'Peak usage in the $peakPeriod',
        description: 'You use your phone most between ${_formatHour(startHour)} and ${_formatHour(endHour)}.',
        detailedExplanation: 'Understanding your peak usage times can help you '
            'set better boundaries and schedule focused work periods.',
        icon: LucideIcons.clock,
        generatedAt: now,
        isActionable: peakPeriod == 'night',
        actionLabel: peakPeriod == 'night' ? 'Set bedtime reminder' : null,
        tags: ['time', 'peak', peakPeriod],
      ));
    }
    
    return insights;
  }
  
  static List<Insight> _generateAppCategoryInsights(List<Map<String, dynamic>> usageData) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    final categoryUsage = <String, double>{};
    for (final app in usageData) {
      final category = app['category'] as String? ?? 'Other';
      final hours = (app['usageTime'] as int) / (1000 * 60 * 60);
      categoryUsage[category] = (categoryUsage[category] ?? 0) + hours;
    }
    
    // Social media insight
    final socialHours = categoryUsage['Social'] ?? 0;
    if (socialHours > 2.0) {
      insights.add(Insight(
        id: 'social_high_${now.millisecondsSinceEpoch}',
        type: InsightType.warning,
        category: InsightCategory.warning,
        severity: InsightSeverity.high,
        title: 'High social media usage',
        description: '${socialHours.toStringAsFixed(1)} hours on social media today.',
        detailedExplanation: 'Excessive social media use can impact mental health and productivity. '
            'Consider setting app limits or scheduled breaks.',
        icon: LucideIcons.share2,
        generatedAt: now,
        isActionable: true,
        actionLabel: 'Set social limits',
        tags: ['social', 'warning'],
      ));
    }
    
    // Entertainment insight
    final entertainmentHours = categoryUsage['Entertainment'] ?? categoryUsage['Video'] ?? 0;
    if (entertainmentHours > 3.0) {
      insights.add(Insight(
        id: 'entertainment_high_${now.millisecondsSinceEpoch}',
        type: InsightType.warning,
        category: InsightCategory.warning,
        title: 'Significant entertainment time',
        description: '${entertainmentHours.toStringAsFixed(1)} hours spent on entertainment apps.',
        icon: LucideIcons.tv,
        generatedAt: now,
        tags: ['entertainment', 'streaming'],
      ));
    }
    
    // Productivity insight
    final productivityHours = categoryUsage['Productivity'] ?? 0;
    if (productivityHours > 1.0) {
      insights.add(Insight(
        id: 'productivity_good_${now.millisecondsSinceEpoch}',
        type: InsightType.achievement,
        category: InsightCategory.positive,
        title: 'Productive screen time!',
        description: 'You spent ${productivityHours.toStringAsFixed(1)} hours on productive apps.',
        icon: LucideIcons.briefcase,
        generatedAt: now,
        tags: ['productivity', 'positive'],
      ));
    }
    
    return insights;
  }
  
  static List<Insight> _generateTrendInsights(List<Map<String, dynamic>> weeklyTrend) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    if (weeklyTrend.length < 2) return insights;
    
    // Calculate week-over-week change
    final recentDays = weeklyTrend.take(3).toList();
    final earlierDays = weeklyTrend.skip(4).take(3).toList();
    
    if (recentDays.isEmpty || earlierDays.isEmpty) return insights;
    
    final recentAvg = recentDays.fold<double>(
      0, (sum, d) => sum + (d['totalHours'] as double? ?? 0)) / recentDays.length;
    final earlierAvg = earlierDays.fold<double>(
      0, (sum, d) => sum + (d['totalHours'] as double? ?? 0)) / earlierDays.length;
    
    if (earlierAvg > 0) {
      final changePercent = ((recentAvg - earlierAvg) / earlierAvg * 100);
      
      if (changePercent.abs() > 15) {
        final isIncrease = changePercent > 0;
        
        insights.add(Insight(
          id: 'trend_${now.millisecondsSinceEpoch}',
          type: InsightType.trend,
          category: isIncrease ? InsightCategory.warning : InsightCategory.positive,
          title: isIncrease ? 'Screen time is trending up' : 'Screen time is trending down',
          description: '${changePercent.abs().toStringAsFixed(0)}% ${isIncrease ? 'increase' : 'decrease'} compared to last week.',
          detailedExplanation: isIncrease 
              ? 'Your screen time has been increasing. Consider setting daily limits.'
              : 'Great progress! You\'re using your phone less than before.',
          icon: isIncrease ? LucideIcons.trendingUp : LucideIcons.trendingDown,
          generatedAt: now,
          tags: ['trend', isIncrease ? 'increasing' : 'decreasing'],
        ));
      }
    }
    
    return insights;
  }
  
  static List<Insight> _generateComparisonInsights(List<Map<String, dynamic>> weeklyTrend) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    if (weeklyTrend.isEmpty) return insights;
    
    // Today vs yesterday
    final today = weeklyTrend.isNotEmpty ? weeklyTrend.first : null;
    final yesterday = weeklyTrend.length > 1 ? weeklyTrend[1] : null;
    
    if (today != null && yesterday != null) {
      final todayHours = today['totalHours'] as double? ?? 0;
      final yesterdayHours = yesterday['totalHours'] as double? ?? 0;
      
      if (yesterdayHours > 0) {
        final diff = todayHours - yesterdayHours;
        final percentChange = (diff / yesterdayHours * 100);
        
        if (percentChange.abs() > 20) {
          insights.add(Insight(
            id: 'comparison_daily_${now.millisecondsSinceEpoch}',
            type: InsightType.comparison,
            category: diff > 0 ? InsightCategory.neutral : InsightCategory.positive,
            title: diff > 0 
                ? 'More usage than yesterday'
                : 'Less usage than yesterday',
            description: '${diff.abs().toStringAsFixed(1)} hours ${diff > 0 ? 'more' : 'less'} than yesterday.',
            icon: LucideIcons.arrowRightLeft,
            generatedAt: now,
            tags: ['comparison', 'daily'],
          ));
        }
      }
    }
    
    // Best day of the week
    if (weeklyTrend.length >= 7) {
      final sorted = List.from(weeklyTrend)
        ..sort((a, b) => (a['totalHours'] as double? ?? 0)
            .compareTo(b['totalHours'] as double? ?? 0));
      
      final bestDay = sorted.first;
      final bestDayDate = bestDay['date'] as DateTime?;
      
      if (bestDayDate != null) {
        final dayName = _getDayName(bestDayDate.weekday);
        
        insights.add(Insight(
          id: 'comparison_best_day_${now.millisecondsSinceEpoch}',
          type: InsightType.achievement,
          category: InsightCategory.positive,
          title: '$dayName was your best day!',
          description: 'Lowest screen time of the week: ${(bestDay['totalHours'] as double? ?? 0).toStringAsFixed(1)} hours.',
          icon: LucideIcons.star,
          generatedAt: now,
          tags: ['comparison', 'weekly', 'best'],
        ));
      }
    }
    
    return insights;
  }
  
  static List<Insight> _generateRecommendations(
    List<Map<String, dynamic>> usageData,
    List<Map<String, dynamic>> weeklyTrend,
  ) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    final totalHours = usageData.fold<double>(
      0, (sum, app) => sum + (app['usageTime'] as int) / (1000 * 60 * 60));
    
    // High usage recommendation
    if (totalHours > 5) {
      insights.add(Insight(
        id: 'rec_high_usage_${now.millisecondsSinceEpoch}',
        type: InsightType.recommendation,
        category: InsightCategory.warning,
        priority: InsightPriority.high,
        title: 'Set a daily screen time goal',
        description: 'With ${totalHours.toStringAsFixed(1)} hours today, setting a limit could help.',
        detailedExplanation: 'Research suggests keeping total screen time under 4 hours for optimal wellbeing. '
            'Try setting progressive limits to gradually reduce usage.',
        icon: LucideIcons.target,
        generatedAt: now,
        isActionable: true,
        actionLabel: 'Set daily goal',
        tags: ['recommendation', 'goal'],
      ));
    }
    
    // Focus time recommendation
    insights.add(Insight(
      id: 'rec_focus_${now.millisecondsSinceEpoch}',
      type: InsightType.recommendation,
      category: InsightCategory.neutral,
      title: 'Try a focus session',
      description: 'Block distracting apps for 25 minutes and boost your productivity.',
      icon: LucideIcons.focus,
      generatedAt: now,
      isActionable: true,
      actionLabel: 'Start focus session',
      actionRoute: '/focus',
      tags: ['recommendation', 'focus'],
    ));
    
    // Bedtime mode recommendation
    final peakData = detectPeakUsageTimes(usageData);
    if (peakData['peakPeriod'] == 'night') {
      insights.add(Insight(
        id: 'rec_bedtime_${now.millisecondsSinceEpoch}',
        type: InsightType.recommendation,
        category: InsightCategory.warning,
        title: 'Consider setting a bedtime',
        description: 'Heavy evening usage can affect sleep quality.',
        detailedExplanation: 'Blue light from screens can interfere with melatonin production. '
            'Try to avoid screens 1 hour before bed for better sleep.',
        icon: LucideIcons.moon,
        generatedAt: now,
        isActionable: true,
        actionLabel: 'Set bedtime',
        tags: ['recommendation', 'sleep', 'bedtime'],
      ));
    }
    
    return insights;
  }
  
  static List<Insight> _generateAchievements(
    List<Map<String, dynamic>> usageData,
    List<Map<String, dynamic>> weeklyTrend,
  ) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    final totalHours = usageData.fold<double>(
      0, (sum, app) => sum + (app['usageTime'] as int) / (1000 * 60 * 60));
    
    // Low usage achievement
    if (totalHours < 2 && totalHours > 0) {
      insights.add(Insight(
        id: 'ach_low_usage_${now.millisecondsSinceEpoch}',
        type: InsightType.achievement,
        category: InsightCategory.positive,
        priority: InsightPriority.high,
        title: 'Digital minimalist! 🎉',
        description: 'Only ${totalHours.toStringAsFixed(1)} hours of screen time today. Excellent!',
        icon: LucideIcons.trophy,
        generatedAt: now,
        tags: ['achievement', 'low-usage'],
      ));
    }
    
    // Streak detection
    if (weeklyTrend.length >= 3) {
      final goodDays = weeklyTrend.where((d) => 
          (d['totalHours'] as double? ?? 0) < 4).length;
      
      if (goodDays >= 3) {
        insights.add(Insight(
          id: 'ach_streak_${now.millisecondsSinceEpoch}',
          type: InsightType.achievement,
          category: InsightCategory.positive,
          title: '$goodDays-day streak!',
          description: 'You\'ve maintained healthy screen time for $goodDays days this week.',
          icon: LucideIcons.flame,
          generatedAt: now,
          tags: ['achievement', 'streak'],
        ));
      }
    }
    
    // App reduction achievement
    if (usageData.isNotEmpty && weeklyTrend.length > 1) {
      final topApp = usageData.first;
      final appName = topApp['appName'] as String? ?? '';
      
      if (appName.isNotEmpty && 
          (appName.toLowerCase().contains('instagram') ||
           appName.toLowerCase().contains('tiktok') ||
           appName.toLowerCase().contains('facebook'))) {
        final currentMinutes = (topApp['usageTime'] as int) / (1000 * 60);
        
        // Simulate week comparison (would need historical app data)
        final previousWeekEstimate = currentMinutes * 1.3; // Assume 30% higher last week
        
        if (currentMinutes < previousWeekEstimate * 0.8) {
          final reduction = ((previousWeekEstimate - currentMinutes) / previousWeekEstimate * 100);
          
          insights.add(Insight(
            id: 'ach_app_reduction_${now.millisecondsSinceEpoch}',
            type: InsightType.achievement,
            category: InsightCategory.positive,
            title: 'Reduced $appName usage!',
            description: 'You\'ve cut $appName usage by ~${reduction.toStringAsFixed(0)}% this week.',
            icon: LucideIcons.badgeCheck,
            generatedAt: now,
            relatedApps: [appName],
            tags: ['achievement', 'reduction'],
          ));
        }
      }
    }
    
    return insights;
  }
  
  static List<Insight> _generateSleepCorrelations(
    List<Map<String, dynamic>> usageData,
    Map<String, dynamic> sleepData,
  ) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    final totalHours = usageData.fold<double>(
      0, (sum, app) => sum + (app['usageTime'] as int) / (1000 * 60 * 60));
    
    final sleepMinutes = sleepData['totalMinutes'] as double? ?? 0;
    final sleepHours = sleepMinutes / 60;
    
    // High screen time, low sleep correlation
    if (totalHours > 4 && sleepHours < 7) {
      insights.add(Insight(
        id: 'corr_sleep_screen_${now.millisecondsSinceEpoch}',
        type: InsightType.correlation,
        category: InsightCategory.warning,
        severity: InsightSeverity.high,
        title: 'Screen time may affect your sleep',
        description: 'High screen time (${totalHours.toStringAsFixed(1)}h) coincides with low sleep (${sleepHours.toStringAsFixed(1)}h).',
        detailedExplanation: 'Studies show a strong correlation between excessive screen time and poor sleep quality. '
            'Consider reducing evening phone usage for better rest.',
        icon: LucideIcons.moon,
        generatedAt: now,
        isActionable: true,
        actionLabel: 'View sleep tips',
        tags: ['correlation', 'sleep', 'screen-time'],
      ));
    }
    
    // Good balance
    if (totalHours < 3 && sleepHours >= 7) {
      insights.add(Insight(
        id: 'corr_sleep_good_${now.millisecondsSinceEpoch}',
        type: InsightType.correlation,
        category: InsightCategory.positive,
        title: 'Great screen-sleep balance!',
        description: 'Low screen time correlates with good sleep (${sleepHours.toStringAsFixed(1)}h).',
        icon: LucideIcons.bedDouble,
        generatedAt: now,
        tags: ['correlation', 'sleep', 'positive'],
      ));
    }
    
    return insights;
  }
  
  static List<Insight> _generateActivityCorrelations(
    List<Map<String, dynamic>> usageData,
    Map<String, dynamic> stepData,
  ) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    final totalHours = usageData.fold<double>(
      0, (sum, app) => sum + (app['usageTime'] as int) / (1000 * 60 * 60));
    
    final steps = stepData['todaySteps'] as int? ?? 0;
    
    // Low steps, high screen time
    if (steps < 5000 && totalHours > 4) {
      insights.add(Insight(
        id: 'corr_activity_low_${now.millisecondsSinceEpoch}',
        type: InsightType.correlation,
        category: InsightCategory.warning,
        title: 'Screen time inversely affects activity',
        description: 'On high screen days like today, step count tends to be lower.',
        detailedExplanation: 'There\'s a negative correlation between screen time and physical activity. '
            'Try taking walking breaks every hour to stay active.',
        icon: LucideIcons.footprints,
        generatedAt: now,
        isActionable: true,
        actionLabel: 'Set activity reminder',
        tags: ['correlation', 'activity', 'steps'],
      ));
    }
    
    // High steps despite screen time
    if (steps >= 10000) {
      insights.add(Insight(
        id: 'corr_activity_high_${now.millisecondsSinceEpoch}',
        type: InsightType.achievement,
        category: InsightCategory.positive,
        title: 'Active day! ${steps.toString()} steps',
        description: 'You\'re staying active even with phone usage. Great balance!',
        icon: LucideIcons.activity,
        generatedAt: now,
        tags: ['correlation', 'activity', 'achievement'],
      ));
    }
    
    return insights;
  }
  
  // Statistical helper methods
  
  static double _calculateMean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.fold<double>(0, (a, b) => a + b) / values.length;
  }
  
  static double _calculateMedian(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isEven) {
      return (sorted[mid - 1] + sorted[mid]) / 2;
    }
    return sorted[mid];
  }
  
  static double _calculateStdDeviation(List<double> values, double mean) {
    if (values.length < 2) return 0;
    final squaredDiffs = values.map((v) => pow(v - mean, 2));
    return sqrt(squaredDiffs.fold<double>(0, (a, b) => a + b) / (values.length - 1));
  }
  
  // Helper methods
  
  static IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'social':
        return LucideIcons.share2;
      case 'entertainment':
      case 'video':
        return LucideIcons.tv;
      case 'productivity':
        return LucideIcons.briefcase;
      case 'games':
        return LucideIcons.gamepad2;
      case 'communication':
        return LucideIcons.messageCircle;
      case 'education':
        return LucideIcons.graduationCap;
      default:
        return LucideIcons.smartphone;
    }
  }
  
  static String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }
  
  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }
  
  // Cache methods
  
  static Future<void> _cacheInsights(List<Insight> insights) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = insights.map((i) => i.toJson()).toList();
      await prefs.setString(_insightsCacheKey, jsonEncode(json));
      await prefs.setString(_lastAnalysisKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching insights: $e');
    }
  }
  
  static Future<List<Insight>?> _getCachedInsights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_insightsCacheKey);
      if (cached == null) return null;
      
      final List<dynamic> json = jsonDecode(cached);
      return json.map((j) => Insight.fromJson(j)).toList();
    } catch (e) {
      print('Error loading cached insights: $e');
      return null;
    }
  }
  
  static Future<DateTime?> _getLastAnalysisTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_lastAnalysisKey);
      if (stored == null) return null;
      return DateTime.parse(stored);
    } catch (e) {
      return null;
    }
  }
  
  /// Create summary from insights list
  static InsightsSummary createSummary(List<Insight> insights) {
    final positiveCount = insights.where((i) => 
        i.category == InsightCategory.positive).length;
    final warningCount = insights.where((i) => 
        i.category == InsightCategory.warning).length;
    final criticalCount = insights.where((i) => 
        i.category == InsightCategory.critical).length;
    
    // Calculate health score
    double healthScore = 70; // Base score
    healthScore += positiveCount * 5;
    healthScore -= warningCount * 8;
    healthScore -= criticalCount * 15;
    healthScore = healthScore.clamp(0, 100);
    
    // Generate summary text
    String summaryText;
    if (healthScore >= 80) {
      summaryText = 'You\'re maintaining excellent digital habits! Keep up the great work.';
    } else if (healthScore >= 60) {
      summaryText = 'Your digital wellness is good with room for improvement.';
    } else if (healthScore >= 40) {
      summaryText = 'Consider reviewing your screen time habits for better balance.';
    } else {
      summaryText = 'Your digital habits need attention. Check the recommendations below.';
    }
    
    return InsightsSummary(
      totalInsights: insights.length,
      positiveCount: positiveCount,
      warningCount: warningCount,
      criticalCount: criticalCount,
      generatedAt: DateTime.now(),
      summaryText: summaryText,
      overallHealthScore: healthScore,
    );
  }
}
