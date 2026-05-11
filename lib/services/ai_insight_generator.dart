import 'dart:math';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/insight_model.dart';

/// AI-powered insight generator using rule-based pattern recognition
/// This provides local ML-like analysis without requiring external dependencies
class AIInsightGenerator {
  // Pattern detection thresholds
  static const double _habitThreshold = 0.7; // 70% consistency
  static const double _anomalyThreshold = 2.0; // 2 std deviations
  static const int _minDataPoints = 3; // Minimum days for pattern detection
  
  /// Generate intelligent insights using rule-based AI
  static Future<List<Insight>> generateIntelligentInsights({
    required List<Map<String, dynamic>> dailyUsage,
    required List<Map<String, dynamic>> weeklyTrend,
    Map<String, dynamic>? sleepData,
    Map<String, dynamic>? stepData,
    Map<String, dynamic>? historicalPatterns,
  }) async {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    // Run all AI analysis methods
    insights.addAll(_detectHabitPatterns(dailyUsage, weeklyTrend));
    insights.addAll(_detectAnomalies(dailyUsage, weeklyTrend));
    insights.addAll(_predictFutureUsage(weeklyTrend));
    insights.addAll(_clusterAppUsage(dailyUsage));
    insights.addAll(_detectBehavioralCycles(weeklyTrend));
    insights.addAll(_analyzeUsageVelocity(weeklyTrend));
    insights.addAll(_detectAppSwitchingPatterns(dailyUsage));
    insights.addAll(_generateSmartGoals(dailyUsage, weeklyTrend));
    insights.addAll(_detectDigitalFatigue(dailyUsage, weeklyTrend));
    insights.addAll(_analyzeProductivityRatio(dailyUsage));
    
    // Cross-metric correlations if data available
    if (sleepData != null) {
      insights.addAll(_deepSleepCorrelation(dailyUsage, sleepData, weeklyTrend));
    }
    
    if (stepData != null) {
      insights.addAll(_deepActivityCorrelation(dailyUsage, stepData, weeklyTrend));
    }
    
    return insights;
  }
  
  /// Detect habit patterns (consistent usage at same times/days)
  static List<Insight> _detectHabitPatterns(
    List<Map<String, dynamic>> dailyUsage,
    List<Map<String, dynamic>> weeklyTrend,
  ) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    if (weeklyTrend.length < _minDataPoints) return insights;
    
    // Analyze day-of-week patterns
    final weekdayUsage = <int, List<double>>{};
    for (final day in weeklyTrend) {
      final date = day['date'] as DateTime?;
      if (date != null) {
        final weekday = date.weekday;
        final hours = day['totalHours'] as double? ?? 0;
        weekdayUsage.putIfAbsent(weekday, () => []).add(hours);
      }
    }
    
    // Find consistent high-usage days
    for (final entry in weekdayUsage.entries) {
      if (entry.value.length >= 2) {
        final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        final allHigh = entry.value.every((h) => h > avg * 0.8);
        
        if (allHigh && avg > 3) {
          final dayName = _getDayName(entry.key);
          insights.add(Insight(
            id: 'habit_day_${entry.key}_${now.millisecondsSinceEpoch}',
            type: InsightType.habit,
            category: InsightCategory.neutral,
            title: '$dayName is a high-usage day',
            description: 'You consistently use your phone more on ${dayName}s (avg ${avg.toStringAsFixed(1)}h).',
            detailedExplanation: 'This pattern has been detected across multiple weeks. '
                'Consider if this aligns with your goals for ${dayName}s.',
            icon: LucideIcons.repeat,
            generatedAt: now,
            confidenceScore: 0.8,
            tags: ['habit', 'weekly-pattern', dayName.toLowerCase()],
          ));
        }
      }
    }
    
    // Detect weekend vs weekday habit
    final weekdayHours = <double>[];
    final weekendHours = <double>[];
    
    for (final day in weeklyTrend) {
      final date = day['date'] as DateTime?;
      if (date != null) {
        final hours = day['totalHours'] as double? ?? 0;
        if (date.weekday >= 6) {
          weekendHours.add(hours);
        } else {
          weekdayHours.add(hours);
        }
      }
    }
    
    if (weekdayHours.isNotEmpty && weekendHours.isNotEmpty) {
      final weekdayAvg = weekdayHours.reduce((a, b) => a + b) / weekdayHours.length;
      final weekendAvg = weekendHours.reduce((a, b) => a + b) / weekendHours.length;
      
      final diff = weekendAvg - weekdayAvg;
      if (diff.abs() > 1.5) {
        insights.add(Insight(
          id: 'habit_weekend_${now.millisecondsSinceEpoch}',
          type: InsightType.habit,
          category: diff > 0 ? InsightCategory.neutral : InsightCategory.positive,
          title: diff > 0 
              ? 'Weekend screen time is higher'
              : 'You use phone less on weekends',
          description: '${diff.abs().toStringAsFixed(1)}h ${diff > 0 ? 'more' : 'less'} screen time on weekends vs weekdays.',
          icon: LucideIcons.calendar,
          generatedAt: now,
          confidenceScore: 0.85,
          tags: ['habit', 'weekend', 'comparison'],
        ));
      }
    }
    
    return insights;
  }
  
  /// Detect anomalies (unusual usage patterns)
  static List<Insight> _detectAnomalies(
    List<Map<String, dynamic>> dailyUsage,
    List<Map<String, dynamic>> weeklyTrend,
  ) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    if (weeklyTrend.length < _minDataPoints) return insights;
    
    // Calculate statistics
    final hours = weeklyTrend.map((d) => d['totalHours'] as double? ?? 0).toList();
    final mean = hours.reduce((a, b) => a + b) / hours.length;
    final variance = hours.map((h) => pow(h - mean, 2)).reduce((a, b) => a + b) / hours.length;
    final stdDev = sqrt(variance);
    
    // Check today's usage
    if (hours.isNotEmpty && stdDev > 0) {
      final today = hours.first;
      final zScore = (today - mean) / stdDev;
      
      if (zScore.abs() > _anomalyThreshold) {
        final isHigh = zScore > 0;
        insights.add(Insight(
          id: 'anomaly_today_${now.millisecondsSinceEpoch}',
          type: InsightType.anomaly,
          category: isHigh ? InsightCategory.warning : InsightCategory.positive,
          severity: isHigh ? InsightSeverity.high : InsightSeverity.low,
          priority: InsightPriority.high,
          title: isHigh 
              ? 'Unusually high screen time today'
              : 'Unusually low screen time today',
          description: 'Today\'s ${today.toStringAsFixed(1)}h is ${zScore.abs().toStringAsFixed(1)} standard deviations ${isHigh ? 'above' : 'below'} your average.',
          detailedExplanation: isHigh
              ? 'This is significantly higher than your normal usage. Was there a specific reason?'
              : 'Great job! You\'re using your phone much less than usual today.',
          icon: LucideIcons.zap,
          generatedAt: now,
          confidenceScore: 0.9,
          metadata: {'zScore': zScore, 'mean': mean, 'stdDev': stdDev},
          tags: ['anomaly', isHigh ? 'high' : 'low'],
        ));
      }
    }
    
    // Detect anomalies in specific apps
    if (dailyUsage.isNotEmpty) {
      final totalMinutes = dailyUsage.fold<double>(
        0, (sum, app) => sum + (app['usageTime'] as int) / (1000 * 60));
      final appMean = totalMinutes / dailyUsage.length;
      
      for (final app in dailyUsage) {
        final appMinutes = (app['usageTime'] as int) / (1000 * 60);
        final appName = app['appName'] as String? ?? 'Unknown';
        
        if (appMinutes > appMean * 3 && appMinutes > 60) {
          insights.add(Insight(
            id: 'anomaly_app_${appName}_${now.millisecondsSinceEpoch}',
            type: InsightType.anomaly,
            category: InsightCategory.neutral,
            title: 'Unusual $appName usage',
            description: '${appMinutes.toInt()} minutes on $appName - more than typical.',
            icon: LucideIcons.alertCircle,
            generatedAt: now,
            relatedApps: [appName],
            tags: ['anomaly', 'app-specific'],
          ));
          break; // Only show one app anomaly
        }
      }
    }
    
    return insights;
  }
  
  /// Predict future usage based on trends
  static List<Insight> _predictFutureUsage(List<Map<String, dynamic>> weeklyTrend) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    if (weeklyTrend.length < 5) return insights;
    
    // Simple linear regression for prediction
    final hours = weeklyTrend.map((d) => d['totalHours'] as double? ?? 0).toList();
    
    // Calculate trend slope
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < hours.length; i++) {
      sumX += i;
      sumY += hours[i];
      sumXY += i * hours[i];
      sumX2 += i * i;
    }
    
    final n = hours.length.toDouble();
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;
    
    // Predict next week
    final predictedNextWeek = intercept + slope * (n + 7);
    final currentAvg = sumY / n;
    
    if (slope.abs() > 0.1) {
      final isIncreasing = slope > 0;
      final changePercent = ((predictedNextWeek - currentAvg) / currentAvg * 100).abs();
      
      insights.add(Insight(
        id: 'predict_trend_${now.millisecondsSinceEpoch}',
        type: InsightType.trend,
        category: isIncreasing ? InsightCategory.warning : InsightCategory.positive,
        title: isIncreasing 
            ? 'Usage trending upward'
            : 'Usage trending downward',
        description: 'At this rate, next week\'s average could be ${predictedNextWeek.toStringAsFixed(1)}h/day.',
        detailedExplanation: isIncreasing
            ? 'Your screen time is gradually increasing. Consider setting limits now.'
            : 'Great progress! You\'re on track to reduce your screen time.',
        icon: isIncreasing ? LucideIcons.trendingUp : LucideIcons.trendingDown,
        generatedAt: now,
        confidenceScore: min(0.7, 0.5 + (weeklyTrend.length * 0.05)),
        metadata: {'slope': slope, 'predicted': predictedNextWeek},
        tags: ['prediction', 'trend'],
      ));
    }
    
    return insights;
  }
  
  /// Cluster apps by usage patterns
  static List<Insight> _clusterAppUsage(List<Map<String, dynamic>> dailyUsage) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    if (dailyUsage.isEmpty) return insights;
    
    // Simple clustering: group apps by usage level
    final highUsage = <String>[]; // > 60 min
    final mediumUsage = <String>[]; // 15-60 min
    final lowUsage = <String>[]; // < 15 min
    
    for (final app in dailyUsage) {
      final minutes = (app['usageTime'] as int) / (1000 * 60);
      final name = app['appName'] as String? ?? '';
      
      if (minutes > 60) {
        highUsage.add(name);
      } else if (minutes > 15) {
        mediumUsage.add(name);
      } else {
        lowUsage.add(name);
      }
    }
    
    // Generate insight about app distribution
    if (highUsage.isNotEmpty) {
      final ratio = highUsage.length / dailyUsage.length;
      
      if (ratio > 0.3) {
        insights.add(Insight(
          id: 'cluster_concentration_${now.millisecondsSinceEpoch}',
          type: InsightType.pattern,
          category: InsightCategory.neutral,
          title: 'Usage concentrated in ${highUsage.length} apps',
          description: '${(ratio * 100).toStringAsFixed(0)}% of your apps account for most screen time.',
          detailedExplanation: 'High-usage apps: ${highUsage.take(3).join(", ")}. '
              'Consider setting limits for these specific apps.',
          icon: LucideIcons.pieChart,
          generatedAt: now,
          relatedApps: highUsage,
          tags: ['clustering', 'concentration'],
        ));
      }
    }
    
    // Diversity insight
    if (dailyUsage.length > 10 && lowUsage.length > dailyUsage.length * 0.6) {
      insights.add(Insight(
        id: 'cluster_diverse_${now.millisecondsSinceEpoch}',
        type: InsightType.pattern,
        category: InsightCategory.positive,
        title: 'Diverse app usage pattern',
        description: 'You use many apps briefly rather than focusing on a few.',
        icon: LucideIcons.layout,
        generatedAt: now,
        tags: ['clustering', 'diversity'],
      ));
    }
    
    return insights;
  }
  
  /// Detect behavioral cycles (weekly/monthly patterns)
  static List<Insight> _detectBehavioralCycles(List<Map<String, dynamic>> weeklyTrend) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    if (weeklyTrend.length < 7) return insights;
    
    // Check for weekly cycle
    final hours = weeklyTrend.map((d) => d['totalHours'] as double? ?? 0).toList();
    
    // Find the most common pattern
    int peakDay = 0;
    double maxHours = 0;
    
    for (int i = 0; i < min(7, hours.length); i++) {
      if (hours[i] > maxHours) {
        maxHours = hours[i];
        peakDay = i;
      }
    }
    
    // Calculate variability
    final mean = hours.reduce((a, b) => a + b) / hours.length;
    final maxDeviation = hours.map((h) => (h - mean).abs()).reduce(max);
    final variabilityScore = maxDeviation / mean;
    
    if (variabilityScore > 0.3) {
      insights.add(Insight(
        id: 'cycle_variability_${now.millisecondsSinceEpoch}',
        type: InsightType.pattern,
        category: InsightCategory.neutral,
        title: 'High usage variability detected',
        description: 'Your screen time varies by ${(variabilityScore * 100).toStringAsFixed(0)}% across days.',
        detailedExplanation: 'This could indicate work/personal life patterns or '
            'inconsistent digital habits. Consider setting consistent daily goals.',
        icon: LucideIcons.activity,
        generatedAt: now,
        metadata: {'variabilityScore': variabilityScore},
        tags: ['cycle', 'variability'],
      ));
    } else {
      insights.add(Insight(
        id: 'cycle_consistent_${now.millisecondsSinceEpoch}',
        type: InsightType.achievement,
        category: InsightCategory.positive,
        title: 'Consistent daily usage',
        description: 'Your screen time is relatively stable across days.',
        icon: LucideIcons.checkCircle,
        generatedAt: now,
        tags: ['cycle', 'consistency'],
      ));
    }
    
    return insights;
  }
  
  /// Analyze usage velocity (how fast usage accumulates)
  static List<Insight> _analyzeUsageVelocity(List<Map<String, dynamic>> weeklyTrend) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    if (weeklyTrend.length < 2) return insights;
    
    // Calculate daily change rates
    final changes = <double>[];
    for (int i = 0; i < weeklyTrend.length - 1; i++) {
      final today = weeklyTrend[i]['totalHours'] as double? ?? 0;
      final yesterday = weeklyTrend[i + 1]['totalHours'] as double? ?? 0;
      if (yesterday > 0) {
        changes.add((today - yesterday) / yesterday);
      }
    }
    
    if (changes.isNotEmpty) {
      final avgChange = changes.reduce((a, b) => a + b) / changes.length;
      
      if (avgChange.abs() > 0.15) {
        final isAccelerating = avgChange > 0;
        insights.add(Insight(
          id: 'velocity_${now.millisecondsSinceEpoch}',
          type: InsightType.trend,
          category: isAccelerating ? InsightCategory.warning : InsightCategory.positive,
          title: isAccelerating 
              ? 'Screen time accelerating'
              : 'Screen time decelerating',
          description: '${(avgChange.abs() * 100).toStringAsFixed(0)}% average daily ${isAccelerating ? 'increase' : 'decrease'}.',
          icon: isAccelerating ? LucideIcons.chevronsUp : LucideIcons.chevronsDown,
          generatedAt: now,
          tags: ['velocity', isAccelerating ? 'accelerating' : 'decelerating'],
        ));
      }
    }
    
    return insights;
  }
  
  /// Detect app switching patterns (potential distraction)
  static List<Insight> _detectAppSwitchingPatterns(List<Map<String, dynamic>> dailyUsage) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    if (dailyUsage.isEmpty) return insights;
    
    // Count apps with small usage times (indicates frequent switching)
    final quickSwitches = dailyUsage.where((app) {
      final minutes = (app['usageTime'] as int) / (1000 * 60);
      return minutes > 1 && minutes < 5;
    }).length;
    
    final switchRatio = quickSwitches / dailyUsage.length;
    
    if (quickSwitches > 5 && switchRatio > 0.4) {
      insights.add(Insight(
        id: 'switching_high_${now.millisecondsSinceEpoch}',
        type: InsightType.warning,
        category: InsightCategory.warning,
        title: 'High app-switching detected',
        description: '$quickSwitches apps used for less than 5 minutes each.',
        detailedExplanation: 'Frequent app-switching can indicate distraction and reduce productivity. '
            'Try focusing on one task at a time.',
        icon: LucideIcons.shuffle,
        generatedAt: now,
        isActionable: true,
        actionLabel: 'Start focus mode',
        tags: ['switching', 'distraction'],
      ));
    }
    
    return insights;
  }
  
  /// Generate smart personalized goals
  static List<Insight> _generateSmartGoals(
    List<Map<String, dynamic>> dailyUsage,
    List<Map<String, dynamic>> weeklyTrend,
  ) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    if (weeklyTrend.isEmpty) return insights;
    
    // Calculate current average
    final hours = weeklyTrend.map((d) => d['totalHours'] as double? ?? 0).toList();
    final currentAvg = hours.reduce((a, b) => a + b) / hours.length;
    
    // Generate realistic goal (10-20% reduction)
    if (currentAvg > 2) {
      final goalHours = currentAvg * 0.85; // 15% reduction
      
      insights.add(Insight(
        id: 'goal_smart_${now.millisecondsSinceEpoch}',
        type: InsightType.goal,
        category: InsightCategory.neutral,
        priority: InsightPriority.normal,
        title: 'Suggested daily goal: ${goalHours.toStringAsFixed(1)}h',
        description: 'Based on your average of ${currentAvg.toStringAsFixed(1)}h, a 15% reduction is achievable.',
        detailedExplanation: 'This goal is designed to be challenging but realistic. '
            'Small consistent improvements lead to lasting change.',
        icon: LucideIcons.target,
        generatedAt: now,
        isActionable: true,
        actionLabel: 'Set this goal',
        metadata: {'suggestedGoal': goalHours, 'currentAvg': currentAvg},
        tags: ['goal', 'personalized'],
      ));
    }
    
    // Social media specific goal
    final socialApps = dailyUsage.where((app) {
      final name = (app['appName'] as String? ?? '').toLowerCase();
      return name.contains('instagram') || 
             name.contains('tiktok') || 
             name.contains('facebook') ||
             name.contains('twitter') ||
             name.contains('snapchat');
    }).toList();
    
    if (socialApps.isNotEmpty) {
      final socialMinutes = socialApps.fold<double>(
        0, (sum, app) => sum + (app['usageTime'] as int) / (1000 * 60));
      
      if (socialMinutes > 60) {
        final goalMinutes = socialMinutes * 0.7; // 30% reduction
        
        insights.add(Insight(
          id: 'goal_social_${now.millisecondsSinceEpoch}',
          type: InsightType.goal,
          category: InsightCategory.neutral,
          title: 'Social media goal: ${goalMinutes.toInt()} min/day',
          description: 'Reduce from ${socialMinutes.toInt()} to ${goalMinutes.toInt()} minutes.',
          icon: LucideIcons.share2,
          generatedAt: now,
          isActionable: true,
          actionLabel: 'Set social limits',
          relatedApps: socialApps.map((a) => a['appName'] as String).toList(),
          tags: ['goal', 'social-media'],
        ));
      }
    }
    
    return insights;
  }
  
  /// Detect digital fatigue patterns
  static List<Insight> _detectDigitalFatigue(
    List<Map<String, dynamic>> dailyUsage,
    List<Map<String, dynamic>> weeklyTrend,
  ) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    if (weeklyTrend.isEmpty) return insights;
    
    // Check for consistently high usage (potential fatigue)
    final hours = weeklyTrend.map((d) => d['totalHours'] as double? ?? 0).toList();
    final highUsageDays = hours.where((h) => h > 6).length;
    
    if (highUsageDays >= 3) {
      insights.add(Insight(
        id: 'fatigue_high_${now.millisecondsSinceEpoch}',
        type: InsightType.warning,
        category: InsightCategory.warning,
        severity: InsightSeverity.high,
        priority: InsightPriority.high,
        title: 'Digital fatigue warning',
        description: '$highUsageDays days with 6+ hours of screen time this week.',
        detailedExplanation: 'Extended screen time can lead to eye strain, headaches, and reduced attention span. '
            'Consider taking regular breaks and setting daily limits.',
        icon: LucideIcons.alertTriangle,
        generatedAt: now,
        isActionable: true,
        actionLabel: 'Enable break reminders',
        tags: ['fatigue', 'health', 'warning'],
      ));
    }
    
    // Check for late night usage (sleep impact)
    final todayHours = hours.isNotEmpty ? hours.first : 0;
    if (todayHours > 4 && now.hour >= 22) {
      insights.add(Insight(
        id: 'fatigue_night_${now.millisecondsSinceEpoch}',
        type: InsightType.warning,
        category: InsightCategory.warning,
        title: 'Late night screen use',
        description: 'It\'s late and you\'ve had ${todayHours.toStringAsFixed(1)}h of screen time.',
        detailedExplanation: 'Blue light from screens can disrupt your sleep cycle. '
            'Consider winding down for better rest.',
        icon: LucideIcons.moon,
        generatedAt: now,
        isActionable: true,
        actionLabel: 'Enable bedtime mode',
        tags: ['fatigue', 'sleep', 'night'],
      ));
    }
    
    return insights;
  }
  
  /// Analyze productivity ratio
  static List<Insight> _analyzeProductivityRatio(List<Map<String, dynamic>> dailyUsage) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    if (dailyUsage.isEmpty) return insights;
    
    double productiveMinutes = 0;
    double unproductiveMinutes = 0;
    
    for (final app in dailyUsage) {
      final category = app['category'] as String? ?? 'Other';
      final minutes = (app['usageTime'] as int) / (1000 * 60);
      
      if (['Productivity', 'Education', 'Communication'].contains(category)) {
        productiveMinutes += minutes;
      } else if (['Social', 'Entertainment', 'Games'].contains(category)) {
        unproductiveMinutes += minutes;
      }
    }
    
    final total = productiveMinutes + unproductiveMinutes;
    if (total > 30) {
      final ratio = productiveMinutes / total;
      
      InsightCategory category;
      String title;
      String description;
      
      if (ratio >= 0.6) {
        category = InsightCategory.positive;
        title = 'Excellent productivity balance';
        description = '${(ratio * 100).toStringAsFixed(0)}% of your screen time is productive.';
      } else if (ratio >= 0.4) {
        category = InsightCategory.neutral;
        title = 'Balanced screen time';
        description = '${(ratio * 100).toStringAsFixed(0)}% productive, ${((1 - ratio) * 100).toStringAsFixed(0)}% leisure.';
      } else {
        category = InsightCategory.warning;
        title = 'Low productivity ratio';
        description = 'Only ${(ratio * 100).toStringAsFixed(0)}% of screen time is productive.';
      }
      
      insights.add(Insight(
        id: 'productivity_ratio_${now.millisecondsSinceEpoch}',
        type: InsightType.pattern,
        category: category,
        title: title,
        description: description,
        detailedExplanation: 'Productive time: ${productiveMinutes.toInt()} min\n'
            'Leisure time: ${unproductiveMinutes.toInt()} min',
        icon: LucideIcons.briefcase,
        generatedAt: now,
        metadata: {'ratio': ratio, 'productive': productiveMinutes, 'leisure': unproductiveMinutes},
        tags: ['productivity', 'ratio'],
      ));
    }
    
    return insights;
  }
  
  /// Deep sleep correlation analysis
  static List<Insight> _deepSleepCorrelation(
    List<Map<String, dynamic>> dailyUsage,
    Map<String, dynamic> sleepData,
    List<Map<String, dynamic>> weeklyTrend,
  ) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    final sleepHours = (sleepData['totalMinutes'] as double? ?? 0) / 60;
    final screenHours = weeklyTrend.isNotEmpty 
        ? (weeklyTrend.first['totalHours'] as double? ?? 0) 
        : 0;
    
    // Perfect balance detection
    if (sleepHours >= 7 && sleepHours <= 9 && screenHours < 4) {
      insights.add(Insight(
        id: 'sleep_perfect_${now.millisecondsSinceEpoch}',
        type: InsightType.achievement,
        category: InsightCategory.positive,
        title: 'Perfect sleep-screen balance!',
        description: '${sleepHours.toStringAsFixed(1)}h sleep with only ${screenHours.toStringAsFixed(1)}h screen time.',
        icon: LucideIcons.sparkles,
        generatedAt: now,
        tags: ['sleep', 'balance', 'achievement'],
      ));
    }
    
    // Concerning pattern
    if (sleepHours < 6 && screenHours > 5) {
      insights.add(Insight(
        id: 'sleep_concern_${now.millisecondsSinceEpoch}',
        type: InsightType.correlation,
        category: InsightCategory.critical,
        severity: InsightSeverity.critical,
        priority: InsightPriority.urgent,
        title: 'Critical: Screen time affecting sleep',
        description: 'Low sleep (${sleepHours.toStringAsFixed(1)}h) combined with high screen time (${screenHours.toStringAsFixed(1)}h).',
        detailedExplanation: 'This pattern strongly suggests screen time is impacting your sleep quality. '
            'Research shows reducing screen time before bed significantly improves sleep.',
        icon: LucideIcons.alertOctagon,
        generatedAt: now,
        isActionable: true,
        actionLabel: 'Set screen time limit',
        tags: ['sleep', 'critical', 'health'],
      ));
    }
    
    return insights;
  }
  
  /// Deep activity correlation analysis
  static List<Insight> _deepActivityCorrelation(
    List<Map<String, dynamic>> dailyUsage,
    Map<String, dynamic> stepData,
    List<Map<String, dynamic>> weeklyTrend,
  ) {
    final insights = <Insight>[];
    final now = DateTime.now();
    
    final steps = stepData['todaySteps'] as int? ?? 0;
    final goal = stepData['goalSteps'] as int? ?? 10000;
    final screenHours = weeklyTrend.isNotEmpty 
        ? (weeklyTrend.first['totalHours'] as double? ?? 0) 
        : 0;
    
    // Active despite high screen time
    if (steps >= goal && screenHours > 4) {
      insights.add(Insight(
        id: 'activity_balance_${now.millisecondsSinceEpoch}',
        type: InsightType.achievement,
        category: InsightCategory.positive,
        title: 'Great balance: Active & connected!',
        description: '${steps.toString()} steps reached despite ${screenHours.toStringAsFixed(1)}h screen time.',
        icon: LucideIcons.heart,
        generatedAt: now,
        tags: ['activity', 'balance', 'achievement'],
      ));
    }
    
    // Sedentary warning
    if (steps < 3000 && screenHours > 6) {
      insights.add(Insight(
        id: 'activity_sedentary_${now.millisecondsSinceEpoch}',
        type: InsightType.warning,
        category: InsightCategory.warning,
        severity: InsightSeverity.high,
        title: 'Sedentary behavior detected',
        description: 'Only $steps steps with ${screenHours.toStringAsFixed(1)}h screen time.',
        detailedExplanation: 'Extended sitting combined with screen use can impact health. '
            'Try setting hourly movement reminders.',
        icon: LucideIcons.personStanding,
        generatedAt: now,
        isActionable: true,
        actionLabel: 'Set movement reminder',
        tags: ['activity', 'sedentary', 'health'],
      ));
    }
    
    return insights;
  }
  
  // Helper methods
  
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
}
