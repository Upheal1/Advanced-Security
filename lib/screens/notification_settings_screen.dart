import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../models/notification_types.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationSettings _settings = NotificationSettings();
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermission();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('notification_settings');
    
    if (settingsJson != null) {
      try {
        final json = jsonDecode(settingsJson);
        setState(() {
          _settings = NotificationSettings.fromJson(json);
        });
      } catch (e) {
        debugPrint('Error loading notification settings: $e');
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notification_settings',
      jsonEncode(_settings.toJson()),
    );
    
    // Schedule daily summary if enabled
    if (_settings.enabled && _settings.summaryEnabled) {
      await NotificationService.scheduleDailySummary(
        scheduledTime: _settings.summaryTime,
        usageData: {}, // Will be populated with real data when scheduled
      );
    }
  }

  Future<void> _checkPermission() async {
    final hasPermission = await NotificationService.areNotificationsEnabled();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _requestPermission() async {
    final granted = await NotificationService.requestPermissions();
    setState(() {
      _hasPermission = granted;
    });
    
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enable notifications in system settings',
            style: GoogleFonts.inter(),
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              // Open app settings - platform specific
            },
          ),
        ),
      );
    }
  }

  void _updateSettings(NotificationSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    _saveSettings();
  }

  Future<void> _showTimePicker() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _settings.summaryTime.hour,
        minute: _settings.summaryTime.minute,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).brightness == Brightness.dark
                ? const ColorScheme.dark(
                    primary: Color(0xFF7C3AED),
                    onPrimary: Colors.white,
                    surface: Color(0xFF2A2A2A),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF7C3AED),
                    onPrimary: Colors.white,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      final now = DateTime.now();
      _updateSettings(_settings.copyWith(
        summaryTime: DateTime(now.year, now.month, now.day, time.hour, time.minute),
      ));
    }
  }

  Future<void> _testNotification() async {
    // Show a test notification
    await NotificationService.showAchievementNotification(
      achievement: 'Test Notification',
      xpGained: 10,
      description: 'This is a test notification to verify your settings are working correctly.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Test notification sent!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1B1B1B) : const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1B1B1B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notification Settings',
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Permission warning
                  if (!_hasPermission) _buildPermissionCard(isDark),
                  
                  // Master toggle
                  _buildMasterToggle(isDark),
                  const SizedBox(height: 16),

                  // Notification types
                  _buildSectionTitle('Notification Types', isDark),
                  const SizedBox(height: 12),
                  _buildNotificationTypesCard(isDark),
                  const SizedBox(height: 24),

                  // Warning thresholds
                  _buildSectionTitle('Warning Threshold', isDark),
                  const SizedBox(height: 12),
                  _buildThresholdCard(isDark),
                  const SizedBox(height: 24),

                  // Daily summary time
                  _buildSectionTitle('Daily Summary', isDark),
                  const SizedBox(height: 12),
                  _buildSummaryTimeCard(isDark),
                  const SizedBox(height: 24),

                  // Sound & Vibration
                  _buildSectionTitle('Sound & Vibration', isDark),
                  const SizedBox(height: 12),
                  _buildSoundVibrationCard(isDark),
                  const SizedBox(height: 24),

                  // Test notification button
                  _buildTestButton(isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications Disabled',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'Enable notifications to receive alerts',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _requestPermission,
            child: Text(
              'Enable',
              style: GoogleFonts.inter(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterToggle(bool isDark) {
    return _buildCard(
      isDark: isDark,
      child: SwitchListTile(
        title: Text(
          'Enable Notifications',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          'Receive all app notifications',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        value: _settings.enabled,
        onChanged: (value) {
          _updateSettings(_settings.copyWith(enabled: value));
        },
        activeColor: const Color(0xFF7C3AED),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildNotificationTypesCard(bool isDark) {
    return _buildCard(
      isDark: isDark,
      child: Column(
        children: [
          _buildToggleTile(
            title: 'Usage Warnings',
            subtitle: 'Alert when approaching app limits',
            icon: LucideIcons.alertTriangle,
            iconColor: Colors.orange,
            value: _settings.warningsEnabled,
            enabled: _settings.enabled,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(warningsEnabled: value));
            },
            isDark: isDark,
          ),
          const Divider(height: 1),
          _buildToggleTile(
            title: 'Limit Reached',
            subtitle: 'Notify when time limit is reached',
            icon: LucideIcons.ban,
            iconColor: Colors.red,
            value: _settings.limitsEnabled,
            enabled: _settings.enabled,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(limitsEnabled: value));
            },
            isDark: isDark,
          ),
          const Divider(height: 1),
          _buildToggleTile(
            title: 'Daily Summary',
            subtitle: 'Evening recap of screen time',
            icon: LucideIcons.barChart2,
            iconColor: Colors.blue,
            value: _settings.summaryEnabled,
            enabled: _settings.enabled,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(summaryEnabled: value));
            },
            isDark: isDark,
          ),
          const Divider(height: 1),
          _buildToggleTile(
            title: 'Achievements',
            subtitle: 'Celebrate your accomplishments',
            icon: LucideIcons.trophy,
            iconColor: Colors.amber,
            value: _settings.achievementsEnabled,
            enabled: _settings.enabled,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(achievementsEnabled: value));
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required bool enabled,
    required Function(bool) onChanged,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: enabled
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? Colors.white38 : Colors.black38),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
      trailing: Switch(
        value: value && enabled,
        onChanged: enabled ? onChanged : null,
        activeColor: const Color(0xFF7C3AED),
      ),
    );
  }

  Widget _buildThresholdCard(bool isDark) {
    return _buildCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Warn at ${_settings.warningThreshold}% of limit',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get notified when you reach this percentage of your app limit',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildThresholdChip(80, isDark),
                _buildThresholdChip(90, isDark),
                _buildThresholdChip(95, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdChip(int threshold, bool isDark) {
    final isSelected = _settings.warningThreshold == threshold;
    return GestureDetector(
      onTap: _settings.enabled
          ? () => _updateSettings(_settings.copyWith(warningThreshold: threshold))
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C3AED)
              : (isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
        ),
        child: Text(
          '$threshold%',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTimeCard(bool isDark) {
    final timeString = TimeOfDay(
      hour: _settings.summaryTime.hour,
      minute: _settings.summaryTime.minute,
    ).format(context);

    return _buildCard(
      isDark: isDark,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(LucideIcons.clock, color: Colors.blue, size: 20),
        ),
        title: Text(
          'Summary Time',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: _settings.enabled && _settings.summaryEnabled
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white38 : Colors.black38),
          ),
        ),
        subtitle: Text(
          'Receive daily summary at $timeString',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
        trailing: TextButton(
          onPressed: _settings.enabled && _settings.summaryEnabled
              ? _showTimePicker
              : null,
          child: Text(
            timeString,
            style: GoogleFonts.inter(
              color: _settings.enabled && _settings.summaryEnabled
                  ? const Color(0xFF7C3AED)
                  : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSoundVibrationCard(bool isDark) {
    return _buildCard(
      isDark: isDark,
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'Sound',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            secondary: Icon(
              LucideIcons.volume2,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            value: _settings.soundEnabled && _settings.enabled,
            onChanged: _settings.enabled
                ? (value) => _updateSettings(_settings.copyWith(soundEnabled: value))
                : null,
            activeColor: const Color(0xFF7C3AED),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: Text(
              'Vibration',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            secondary: Icon(
              LucideIcons.vibrate,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            value: _settings.vibrationEnabled && _settings.enabled,
            onChanged: _settings.enabled
                ? (value) => _updateSettings(_settings.copyWith(vibrationEnabled: value))
                : null,
            activeColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _settings.enabled ? _testNotification : null,
        icon: const Icon(LucideIcons.bellRing),
        label: Text(
          'Send Test Notification',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildCard({required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200,
        ),
      ),
      child: child,
    );
  }
}

