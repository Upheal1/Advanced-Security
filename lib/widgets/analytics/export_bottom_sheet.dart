import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/export_service.dart';
import '../../constants/app_colors.dart';

/// Bottom sheet for export options
class ExportBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> usageData;
  final Map<String, List<Map<String, dynamic>>>? dateRangeData;
  final GlobalKey? chartKey;
  final String? chartFilename;
  final VoidCallback? onSuccess;
  final Function(String)? onError;

  const ExportBottomSheet({
    super.key,
    required this.usageData,
    this.dateRangeData,
    this.chartKey,
    this.chartFilename,
    this.onSuccess,
    this.onError,
  });

  @override
  State<ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends State<ExportBottomSheet> {
  bool _isLoading = false;
  String? _loadingMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B1B) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                'Export Analytics',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Choose how you want to export your data',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : AppColors.textPrimary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Loading indicator
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? AppColors.purple : AppColors.teal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _loadingMessage ?? 'Processing...',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    // Export Chart option
                    if (widget.chartKey != null)
                      _ExportOption(
                        icon: LucideIcons.image,
                        title: 'Export Chart as Image',
                        subtitle: 'Save the chart as PNG file',
                        isDark: isDark,
                        onTap: _isLoading ? null : _exportChartAsImage,
                      ),

                    if (widget.chartKey != null)
                      const SizedBox(height: 12),

                    // Export CSV option
                    _ExportOption(
                      icon: LucideIcons.fileText,
                      title: 'Export Data as CSV',
                      subtitle: 'Save usage data as spreadsheet',
                      isDark: isDark,
                      onTap: _isLoading ? null : _exportDataAsCSV,
                    ),

                    const SizedBox(height: 12),

                    // Export and Share option
                    _ExportOption(
                      icon: LucideIcons.share2,
                      title: 'Export & Share',
                      subtitle: 'Generate and share all exports',
                      isDark: isDark,
                      onTap: _isLoading ? null : _exportAndShare,
                      highlight: true,
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // Cancel button
              if (!_isLoading)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : AppColors.textPrimary.withOpacity(0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportChartAsImage() async {
    if (widget.chartKey == null) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Capturing chart...';
    });

    try {
      final filename = widget.chartFilename ?? 'analytics-chart.png';
      final file = await ExportService.exportChartAsImage(
        widget.chartKey!,
        filename,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });

        if (file != null) {
          _showSuccess('Chart exported successfully');
          widget.onSuccess?.call();
          
          // Close bottom sheet
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
        _showError('Failed to export chart: $e');
        widget.onError?.call('Failed to export chart: $e');
      }
    }
  }

  Future<void> _exportDataAsCSV() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Generating CSV...';
    });

    try {
      final file = widget.dateRangeData != null
          ? await ExportService.exportRangeDataAsCSV(widget.dateRangeData!)
          : await ExportService.exportDataAsCSV(widget.usageData);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });

        if (file != null) {
          _showSuccess('CSV exported successfully');
          widget.onSuccess?.call();
          
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
        _showError('Failed to export CSV: $e');
        widget.onError?.call('Failed to export CSV: $e');
      }
    }
  }

  Future<void> _exportAndShare() async {
    final files = <File>[];

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Preparing files...';
    });

    try {
      // Export chart if available
      if (widget.chartKey != null) {
        setState(() => _loadingMessage = 'Capturing chart...');
        final chartFile = await ExportService.exportChartAsImage(
          widget.chartKey!,
          widget.chartFilename ?? 'analytics-chart.png',
        );
        if (chartFile != null) files.add(chartFile);
      }

      // Export CSV
      setState(() => _loadingMessage = 'Generating CSV...');
      final csvFile = widget.dateRangeData != null
          ? await ExportService.exportRangeDataAsCSV(widget.dateRangeData!)
          : await ExportService.exportDataAsCSV(widget.usageData);
      if (csvFile != null) files.add(csvFile);

      if (files.isEmpty) {
        throw Exception('Failed to generate export files');
      }

      // Share files
      setState(() => _loadingMessage = 'Opening share menu...');
      
      final now = DateTime.now();
      final subject = 'UpHeal Analytics Export - ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      await ExportService.shareFiles(
        files,
        subject: subject,
        text: 'Here is my app usage analytics data from UpHeal',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showSuccess('Files shared successfully');
            widget.onSuccess?.call();
            Navigator.pop(context);
          }
        });
      }

      // Clean up temp files after sharing
      await ExportService.cleanupTempFiles(files);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
        _showError('Failed to export and share: $e');
        widget.onError?.call('Failed to export and share: $e');
      }
      
      // Clean up files on error
      await ExportService.cleanupTempFiles(files);
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.check, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Individual export option tile
class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback? onTap;
  final bool highlight;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight
          ? (isDark ? AppColors.purple.withOpacity(0.2) : AppColors.teal.withOpacity(0.1))
          : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: highlight
                      ? (isDark ? AppColors.purple.withOpacity(0.3) : AppColors.teal.withOpacity(0.15))
                      : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: highlight
                      ? (isDark ? AppColors.purple : AppColors.teal)
                      : (isDark ? Colors.white70 : AppColors.textPrimary),
                  size: 24,
                ),
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
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : AppColors.textPrimary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: isDark ? Colors.white30 : AppColors.textPrimary.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
