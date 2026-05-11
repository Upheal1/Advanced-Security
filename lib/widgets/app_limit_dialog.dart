import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Bottom sheet dialog for setting app daily limits
class AppLimitDialog {
  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required String packageName,
    required String appName,
    int? currentLimitMinutes,
    bool? currentEmergencyAllowed,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AppLimitDialogContent(
        packageName: packageName,
        appName: appName,
        currentLimitMinutes: currentLimitMinutes,
        currentEmergencyAllowed: currentEmergencyAllowed ?? false,
      ),
    );
  }
}

class _AppLimitDialogContent extends StatefulWidget {
  final String packageName;
  final String appName;
  final int? currentLimitMinutes;
  final bool currentEmergencyAllowed;

  const _AppLimitDialogContent({
    required this.packageName,
    required this.appName,
    required this.currentLimitMinutes,
    required this.currentEmergencyAllowed,
  });

  @override
  State<_AppLimitDialogContent> createState() => _AppLimitDialogContentState();
}

class _AppLimitDialogContentState extends State<_AppLimitDialogContent> {
  late int _selectedMinutes;
  late bool _emergencyAllowed;
  bool _isSaving = false;

  final List<int> _presetMinutes = [15, 30, 60, 90, 120, 180, 240];

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.currentLimitMinutes ?? 30;
    _emergencyAllowed = widget.currentEmergencyAllowed;

    // Ensure selected value is in presets
    if (!_presetMinutes.contains(_selectedMinutes)) {
      _selectedMinutes = 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1B1B1B) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: isDark ? AppColors.purple : AppColors.teal,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Daily Limit',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        widget.appName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Minutes selector
            Text(
              'Daily limit',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetMinutes.map((minutes) {
                final isSelected = minutes == _selectedMinutes;
                return ChoiceChip(
                  label: Text(_formatMinutes(minutes)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedMinutes = minutes;
                      });
                    }
                  },
                  selectedColor: isDark
                      ? AppColors.purple.withOpacity(0.3)
                      : AppColors.teal.withOpacity(0.3),
                  labelStyle: GoogleFonts.inter(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? (isDark ? AppColors.purple : AppColors.teal)
                        : textColor,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Emergency allow toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : AppColors.textPrimary.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emergency,
                    color: AppColors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency allow (5 min)',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Once per day override',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _emergencyAllowed,
                    onChanged: (value) {
                      setState(() {
                        _emergencyAllowed = value;
                      });
                    },
                    activeColor: isDark ? AppColors.purple : AppColors.teal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            // Remove limit
                            Navigator.of(context).pop({
                              'action': 'remove',
                              'packageName': widget.packageName,
                            });
                          },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? Colors.white30 : AppColors.textPrimary.withOpacity(0.3),
                      ),
                    ),
                    child: const Text('Remove Limit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            Navigator.of(context).pop({
                              'action': 'save',
                              'packageName': widget.packageName,
                              'appName': widget.appName,
                              'dailyLimitMinutes': _selectedMinutes,
                              'emergencyAllowed': _emergencyAllowed,
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.purple : AppColors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
  }
}
