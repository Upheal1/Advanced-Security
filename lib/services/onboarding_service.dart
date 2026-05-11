import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing onboarding flows across the app
class OnboardingService {
  static const String _keyPrefix = 'onboarding_';
  static const String _analyticsKey = '${_keyPrefix}analytics_completed';
  static const String _stepsKey = '${_keyPrefix}steps_completed';
  static const String _sleepKey = '${_keyPrefix}sleep_completed';
  static const String _journalKey = '${_keyPrefix}journal_completed';
  static const String _appKey = '${_keyPrefix}app_completed';

  static SharedPreferences? _prefs;

  /// Initialize the service (call once at app startup)
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==================== Analytics Onboarding ====================

  /// Check if user has completed analytics onboarding
  static Future<bool> hasCompletedAnalyticsOnboarding() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_analyticsKey) ?? false;
  }

  /// Mark analytics onboarding as complete
  static Future<void> markAnalyticsOnboardingComplete() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_analyticsKey, true);
    debugPrint('Analytics onboarding marked as complete');
  }

  // ==================== Steps Onboarding ====================

  /// Check if user has completed steps onboarding
  static Future<bool> hasCompletedStepsOnboarding() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_stepsKey) ?? false;
  }

  /// Mark steps onboarding as complete
  static Future<void> markStepsOnboardingComplete() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_stepsKey, true);
  }

  // ==================== Sleep Onboarding ====================

  /// Check if user has completed sleep onboarding
  static Future<bool> hasCompletedSleepOnboarding() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_sleepKey) ?? false;
  }

  /// Mark sleep onboarding as complete
  static Future<void> markSleepOnboardingComplete() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_sleepKey, true);
  }

  // ==================== Journal Onboarding ====================

  /// Check if user has completed journal onboarding
  static Future<bool> hasCompletedJournalOnboarding() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_journalKey) ?? false;
  }

  /// Mark journal onboarding as complete
  static Future<void> markJournalOnboardingComplete() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_journalKey, true);
  }

  // ==================== App Onboarding ====================

  /// Check if user has completed main app onboarding
  static Future<bool> hasCompletedAppOnboarding() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_appKey) ?? false;
  }

  /// Mark main app onboarding as complete
  static Future<void> markAppOnboardingComplete() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_appKey, true);
  }

  // ==================== Generic Methods ====================

  /// Check if onboarding should be shown for a specific feature
  static Future<bool> shouldShowOnboarding(String feature) async {
    final prefs = await _getPrefs();
    final key = '$_keyPrefix${feature}_completed';
    final completed = prefs.getBool(key) ?? false;
    return !completed;
  }

  /// Mark a specific feature onboarding as complete
  static Future<void> markOnboardingComplete(String feature) async {
    final prefs = await _getPrefs();
    final key = '$_keyPrefix${feature}_completed';
    await prefs.setBool(key, true);
    debugPrint('$feature onboarding marked as complete');
  }

  /// Reset onboarding for a specific feature (for testing)
  static Future<void> resetOnboarding(String feature) async {
    final prefs = await _getPrefs();
    final key = '$_keyPrefix${feature}_completed';
    await prefs.remove(key);
    debugPrint('$feature onboarding reset');
  }

  /// Reset all onboarding (for testing)
  static Future<void> resetAllOnboarding() async {
    final prefs = await _getPrefs();
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
    debugPrint('All onboarding reset');
  }

  /// Get all onboarding completion statuses
  static Future<Map<String, bool>> getOnboardingStatuses() async {
    final prefs = await _getPrefs();
    return {
      'analytics': prefs.getBool(_analyticsKey) ?? false,
      'steps': prefs.getBool(_stepsKey) ?? false,
      'sleep': prefs.getBool(_sleepKey) ?? false,
      'journal': prefs.getBool(_journalKey) ?? false,
      'app': prefs.getBool(_appKey) ?? false,
    };
  }
}
