import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/insight_model.dart';

/// A card widget that displays a single insight with expandable details
class InsightCard extends StatefulWidget {
  final Insight insight;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final bool showTimestamp;
  final bool enableAnimation;
  final int animationDelay;
  
  const InsightCard({
    super.key,
    required this.insight,
    this.onAction,
    this.onDismiss,
    this.showTimestamp = true,
    this.enableAnimation = true,
    this.animationDelay = 0,
  });
  
  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  
  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }
  
  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }
  
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insight = widget.insight;
    
    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark 
            ? insight.backgroundColor.withOpacity(0.15)
            : insight.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: insight.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: insight.categoryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: insight.detailedExplanation != null ? _toggleExpanded : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: insight.categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        insight.icon,
                        color: insight.categoryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Title and description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  insight.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.grey[900],
                                  ),
                                ),
                              ),
                              if (insight.priority == InsightPriority.urgent)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'URGENT',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            insight.description,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Expand indicator
                    if (insight.detailedExplanation != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: RotationTransition(
                          turns: Tween(begin: 0.0, end: 0.5).animate(_expandAnimation),
                          child: Icon(
                            LucideIcons.chevronDown,
                            size: 20,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Expanded content
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (insight.detailedExplanation != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.black.withOpacity(0.2)
                                : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            insight.detailedExplanation!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                      
                      // Related apps
                      if (insight.relatedApps != null && insight.relatedApps!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: insight.relatedApps!.map((app) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.smartphone,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    app,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      
                      // Tags
                      if (insight.tags != null && insight.tags!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: insight.tags!.take(3).map((tag) {
                            return Text(
                              '#$tag',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: insight.categoryColor.withOpacity(0.7),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Footer row
                if (insight.isActionable || widget.showTimestamp) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Timestamp
                      if (widget.showTimestamp)
                        Text(
                          insight.timeSinceGenerated,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        )
                      else
                        const Spacer(),
                      
                      // Action button
                      if (insight.isActionable && insight.actionLabel != null)
                        TextButton.icon(
                          onPressed: widget.onAction,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            backgroundColor: insight.categoryColor.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: Icon(
                            LucideIcons.arrowRight,
                            size: 14,
                            color: insight.categoryColor,
                          ),
                          label: Text(
                            insight.actionLabel!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: insight.categoryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                
                // Confidence score indicator
                if (insight.confidenceScore != null && _isExpanded) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.sparkles,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Confidence: ${(insight.confidenceScore! * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    
    // Apply animation if enabled
    if (widget.enableAnimation) {
      card = card
          .animate(delay: Duration(milliseconds: widget.animationDelay))
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.05, end: 0, duration: 300.ms);
    }
    
    return card;
  }
}

/// Compact insight card for previews
class InsightCardCompact extends StatelessWidget {
  final Insight insight;
  final VoidCallback? onTap;
  
  const InsightCardCompact({
    super.key,
    required this.insight,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.grey[850]
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: insight.borderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: insight.categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    insight.icon,
                    color: insight.categoryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        insight.description,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Summary card showing overall insights health score
class InsightsSummaryCard extends StatelessWidget {
  final InsightsSummary summary;
  final VoidCallback? onViewAll;
  final bool showAnimation;
  
  const InsightsSummaryCard({
    super.key,
    required this.summary,
    this.onViewAll,
    this.showAnimation = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            summary.healthColor.withOpacity(0.15),
            summary.healthColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: summary.healthColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Health score circle
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[900] : Colors.white,
                  border: Border.all(
                    color: summary.healthColor,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: summary.healthColor.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        summary.overallHealthScore.toStringAsFixed(0),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: summary.healthColor,
                        ),
                      ),
                      Text(
                        'Score',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Summary text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Digital Wellness: ${summary.healthStatus}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.summaryText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats row
          Row(
            children: [
              _buildStatChip(
                icon: LucideIcons.checkCircle,
                label: '${summary.positiveCount} positive',
                color: const Color(0xFF4CAF50),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                icon: LucideIcons.alertTriangle,
                label: '${summary.warningCount} warnings',
                color: const Color(0xFFFF9800),
                isDark: isDark,
              ),
              if (summary.criticalCount > 0) ...[
                const SizedBox(width: 8),
                _buildStatChip(
                  icon: LucideIcons.alertOctagon,
                  label: '${summary.criticalCount} critical',
                  color: const Color(0xFFF44336),
                  isDark: isDark,
                ),
              ],
              const Spacer(),
              if (onViewAll != null)
                TextButton.icon(
                  onPressed: onViewAll,
                  icon: const Icon(LucideIcons.arrowRight, size: 14),
                  label: Text(
                    'View all',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
    
    if (showAnimation) {
      card = card
          .animate()
          .fadeIn(duration: 400.ms)
          .scale(begin: const Offset(0.95, 0.95), duration: 400.ms);
    }
    
    return card;
  }
  
  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Category filter chips for insights
class InsightCategoryFilter extends StatelessWidget {
  final InsightCategory? selectedCategory;
  final ValueChanged<InsightCategory?> onCategoryChanged;
  
  const InsightCategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            label: 'All',
            isSelected: selectedCategory == null,
            onTap: () => onCategoryChanged(null),
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Positive',
            isSelected: selectedCategory == InsightCategory.positive,
            onTap: () => onCategoryChanged(InsightCategory.positive),
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Neutral',
            isSelected: selectedCategory == InsightCategory.neutral,
            onTap: () => onCategoryChanged(InsightCategory.neutral),
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Warnings',
            isSelected: selectedCategory == InsightCategory.warning,
            onTap: () => onCategoryChanged(InsightCategory.warning),
            color: const Color(0xFFFF9800),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[400]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

/// Type filter chips for insights
class InsightTypeFilter extends StatelessWidget {
  final InsightType? selectedType;
  final ValueChanged<InsightType?> onTypeChanged;
  
  const InsightTypeFilter({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTypeChip(
            type: null,
            label: 'All',
            icon: LucideIcons.list,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildTypeChip(
            type: InsightType.pattern,
            label: 'Patterns',
            icon: LucideIcons.lineChart,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildTypeChip(
            type: InsightType.correlation,
            label: 'Correlations',
            icon: LucideIcons.link,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildTypeChip(
            type: InsightType.recommendation,
            label: 'Tips',
            icon: LucideIcons.lightbulb,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildTypeChip(
            type: InsightType.achievement,
            label: 'Achievements',
            icon: LucideIcons.trophy,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildTypeChip(
            type: InsightType.warning,
            label: 'Warnings',
            icon: LucideIcons.alertTriangle,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTypeChip({
    required InsightType? type,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = selectedType == type;
    
    return GestureDetector(
      onTap: () => onTypeChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? Colors.blue[700] : Colors.blue)
              : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
