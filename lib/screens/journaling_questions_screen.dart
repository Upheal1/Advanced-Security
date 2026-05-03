import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../constants/app_colors.dart';

class JournalingDetailsScreen extends StatefulWidget {
  final JournalEntry entry;

  const JournalingDetailsScreen({super.key, required this.entry});

  @override
  State<JournalingDetailsScreen> createState() =>
      _JournalingDetailsScreenState();
}

class _JournalingDetailsScreenState
    extends State<JournalingDetailsScreen> {
  bool _isAnalyzing = false;
  String? _analysisResult;

  Future<void> _analyzeEntry() async {
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      // Combine all answers for analysis
      // final combinedText = widget.entry.answers
      //     .map((qa) => '${qa.question}\n${qa.answer}')
      //     .join('\n\n');

      //final analysisService = AiAnalysisService();
      //final result = await analysisService.analyzeJournalEntry(combinedText);

      if (mounted) {
        setState(() {
          //_analysisResult = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Journal Entry',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1B1B1B) : null,
        actions: [
          if (widget.entry.xpAwarded != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark 
                          ? Colors.amber.withOpacity(0.4)
                          : Colors.amber.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.entry.xpAwarded} XP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: isDark
                    ? Border.all(color: Colors.white.withOpacity(0.1))
                    : null,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 32,
                    color: isDark
                        ? AppColors.purple
                        : Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(widget.entry.date),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : null,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.entry.answers.length} questions answered',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white70 : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Questions and Answers
            ...widget.entry.answers.asMap().entries.map((entry) {
              final index = entry.key;
              final qa = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark 
                                ? AppColors.purple
                                : Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            qa.question,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : null,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF1E1E1E)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Text(
                        qa.answer,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.white : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // AI Analysis Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.purple.withOpacity(0.3)
                      : Colors.blue.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: isDark ? AppColors.purple : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Insights',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.blue.shade700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isAnalyzing)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: isDark ? AppColors.purple : Colors.blue.shade700,
                        ),
                      ),
                    )
                  else if (_analysisResult != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: isDark
                            ? Border.all(color: Colors.white.withOpacity(0.1))
                            : null,
                      ),
                      child: Text(
                        _analysisResult!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white : null,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Get AI-powered insights about your journal entry',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : null,
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing ? null : _analyzeEntry,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(_isAnalyzing
                          ? 'Analyzing...'
                          : _analysisResult != null
                              ? 'Re-analyze'
                              : 'Analyze Entry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark 
                            ? AppColors.purple
                            : Colors.blue.shade700,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.purple.withOpacity(0.5)
                              : Colors.blue.shade300,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

