import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Type of insight detected
enum InsightType {
  pattern,       // Usage pattern detected (e.g., "You use apps most in evening")
  correlation,   // Correlation between behaviors (e.g., "Less sleep = more phone")
  recommendation,// Actionable recommendation
  achievement,   // Positive milestone reached
  warning,       // Concerning behavior detected
  trend,         // Trend analysis (increasing/decreasing usage)
  comparison,    // Week over week comparison
  anomaly,       // Unusual behavior detected
  habit,         // Habit pattern detected
  goal,          // Goal-related insight
}

/// Category of insight for color coding
enum InsightCategory {
  positive,   // Good behavior, green color
  neutral,    // Informational, blue color
  warning,    // Concerning, orange color
  critical,   // Very concerning, red color
}

/// Severity level of the insight
enum InsightSeverity {
  low,
  medium,
  high,
  critical,
}

/// Priority for display ordering
enum InsightPriority {
  low,
  normal,
  high,
  urgent,
}

/// Data class representing a single insight
class Insight {
  final String id;
  final InsightType type;
  final InsightCategory category;
  final InsightSeverity severity;
  final InsightPriority priority;
  final String title;
  final String description;
  final String? detailedExplanation;
  final bool isActionable;
  final String? actionLabel;
  final String? actionRoute;
  final Map<String, dynamic>? metadata;
  final DateTime generatedAt;
  final DateTime? validUntil;
  final IconData icon;
  final Color? customColor;
  final double? confidenceScore; // 0.0 to 1.0
  final List<String>? relatedApps;
  final List<String>? tags;
  
  const Insight({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    this.severity = InsightSeverity.medium,
    this.priority = InsightPriority.normal,
    this.detailedExplanation,
    this.isActionable = false,
    this.actionLabel,
    this.actionRoute,
    this.metadata,
    required this.generatedAt,
    this.validUntil,
    required this.icon,
    this.customColor,
    this.confidenceScore,
    this.relatedApps,
    this.tags,
  });
  
  /// Get color based on category
  Color get categoryColor {
    if (customColor != null) return customColor!;
    
    switch (category) {
      case InsightCategory.positive:
        return const Color(0xFF4CAF50);
      case InsightCategory.neutral:
        return const Color(0xFF2196F3);
      case InsightCategory.warning:
        return const Color(0xFFFF9800);
      case InsightCategory.critical:
        return const Color(0xFFF44336);
    }
  }
  
  /// Get background color (lighter version)
  Color get backgroundColor {
    return categoryColor.withOpacity(0.1);
  }
  
  /// Get border color
  Color get borderColor {
    return categoryColor.withOpacity(0.3);
  }
  
  /// Get icon based on insight type
  static IconData getDefaultIcon(InsightType type) {
    switch (type) {
      case InsightType.pattern:
        return LucideIcons.lineChart;
      case InsightType.correlation:
        return LucideIcons.link;
      case InsightType.recommendation:
        return LucideIcons.lightbulb;
      case InsightType.achievement:
        return LucideIcons.trophy;
      case InsightType.warning:
        return LucideIcons.alertTriangle;
      case InsightType.trend:
        return LucideIcons.trendingUp;
      case InsightType.comparison:
        return LucideIcons.arrowRightLeft;
      case InsightType.anomaly:
        return LucideIcons.zap;
      case InsightType.habit:
        return LucideIcons.repeat;
      case InsightType.goal:
        return LucideIcons.target;
    }
  }
  
  /// Check if insight is still valid
  bool get isValid {
    if (validUntil == null) return true;
    return DateTime.now().isBefore(validUntil!);
  }
  
  /// Get human-readable time since generation
  String get timeSinceGenerated {
    final diff = DateTime.now().difference(generatedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
  
  /// Create a copy with modifications
  Insight copyWith({
    String? id,
    InsightType? type,
    InsightCategory? category,
    InsightSeverity? severity,
    InsightPriority? priority,
    String? title,
    String? description,
    String? detailedExplanation,
    bool? isActionable,
    String? actionLabel,
    String? actionRoute,
    Map<String, dynamic>? metadata,
    DateTime? generatedAt,
    DateTime? validUntil,
    IconData? icon,
    Color? customColor,
    double? confidenceScore,
    List<String>? relatedApps,
    List<String>? tags,
  }) {
    return Insight(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      description: description ?? this.description,
      detailedExplanation: detailedExplanation ?? this.detailedExplanation,
      isActionable: isActionable ?? this.isActionable,
      actionLabel: actionLabel ?? this.actionLabel,
      actionRoute: actionRoute ?? this.actionRoute,
      metadata: metadata ?? this.metadata,
      generatedAt: generatedAt ?? this.generatedAt,
      validUntil: validUntil ?? this.validUntil,
      icon: icon ?? this.icon,
      customColor: customColor ?? this.customColor,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      relatedApps: relatedApps ?? this.relatedApps,
      tags: tags ?? this.tags,
    );
  }
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'category': category.index,
    'severity': severity.index,
    'priority': priority.index,
    'title': title,
    'description': description,
    'detailedExplanation': detailedExplanation,
    'isActionable': isActionable,
    'actionLabel': actionLabel,
    'actionRoute': actionRoute,
    'metadata': metadata,
    'generatedAt': generatedAt.toIso8601String(),
    'validUntil': validUntil?.toIso8601String(),
    'iconCodePoint': icon.codePoint,
    'customColor': customColor?.value,
    'confidenceScore': confidenceScore,
    'relatedApps': relatedApps,
    'tags': tags,
  };
  
  /// Create from JSON
  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      id: json['id'],
      type: InsightType.values[json['type']],
      category: InsightCategory.values[json['category']],
      severity: InsightSeverity.values[json['severity'] ?? 1],
      priority: InsightPriority.values[json['priority'] ?? 1],
      title: json['title'],
      description: json['description'],
      detailedExplanation: json['detailedExplanation'],
      isActionable: json['isActionable'] ?? false,
      actionLabel: json['actionLabel'],
      actionRoute: json['actionRoute'],
      metadata: json['metadata'],
      generatedAt: DateTime.parse(json['generatedAt']),
      validUntil: json['validUntil'] != null 
          ? DateTime.parse(json['validUntil']) 
          : null,
      icon: IconData(
        json['iconCodePoint'] ?? LucideIcons.info.codePoint,
        fontFamily: 'lucide',
        fontPackage: 'lucide_icons',
      ),
      customColor: json['customColor'] != null 
          ? Color(json['customColor']) 
          : null,
      confidenceScore: json['confidenceScore']?.toDouble(),
      relatedApps: json['relatedApps'] != null 
          ? List<String>.from(json['relatedApps']) 
          : null,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags']) 
          : null,
    );
  }
  
  @override
  String toString() => 'Insight(type: $type, title: $title)';
}

/// Summary of multiple insights
class InsightsSummary {
  final int totalInsights;
  final int positiveCount;
  final int warningCount;
  final int criticalCount;
  final DateTime generatedAt;
  final String summaryText;
  final double overallHealthScore; // 0-100
  
  const InsightsSummary({
    required this.totalInsights,
    required this.positiveCount,
    required this.warningCount,
    required this.criticalCount,
    required this.generatedAt,
    required this.summaryText,
    required this.overallHealthScore,
  });
  
  /// Get health status text
  String get healthStatus {
    if (overallHealthScore >= 80) return 'Excellent';
    if (overallHealthScore >= 60) return 'Good';
    if (overallHealthScore >= 40) return 'Fair';
    if (overallHealthScore >= 20) return 'Needs Attention';
    return 'Critical';
  }
  
  /// Get health status color
  Color get healthColor {
    if (overallHealthScore >= 80) return const Color(0xFF4CAF50);
    if (overallHealthScore >= 60) return const Color(0xFF8BC34A);
    if (overallHealthScore >= 40) return const Color(0xFFFFEB3B);
    if (overallHealthScore >= 20) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }
}

/// Grouped insights by category
class InsightGroup {
  final String title;
  final List<Insight> insights;
  final IconData icon;
  final Color color;
  
  const InsightGroup({
    required this.title,
    required this.insights,
    required this.icon,
    required this.color,
  });
}
