import 'package:intl/intl.dart';

/// Model for exporting app usage data to CSV format
class CSVExporter {
  /// Generate CSV content from app usage data
  /// Format: Date, App Name, Package, Duration (minutes), Percentage
  static String generateUsageCSV(
    List<Map<String, dynamic>> usageData, {
    DateTime? dateRange,
  }) {
    if (usageData.isEmpty) {
      return _generateEmptyCSV();
    }

    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // Add header
    buffer.writeln('Date,App Name,Package Name,Duration (minutes),Duration (hours),Percentage');

    // Calculate total duration for percentage calculation
    int totalMs = 0;
    for (final app in usageData) {
      totalMs += (app['usageTime'] as int?) ?? 0;
    }

    // Sort by usage time descending
    final sortedData = List<Map<String, dynamic>>.from(usageData);
    sortedData.sort((a, b) => (b['usageTime'] as int).compareTo(a['usageTime'] as int));

    // Add data rows
    for (final app in sortedData) {
      final appName = app['appName'] ?? 'Unknown';
      final packageName = app['packageName'] ?? 'unknown';
      final usageTimeMs = (app['usageTime'] as int?) ?? 0;
      final dateStr = dateRange != null 
          ? DateFormat('yyyy-MM-dd').format(dateRange)
          : 'N/A';

      final durationMinutes = usageTimeMs ~/ (1000 * 60);
      final durationHours = (usageTimeMs / (1000 * 60 * 60)).toStringAsFixed(2);
      final percentage = totalMs > 0
          ? ((usageTimeMs / totalMs) * 100).toStringAsFixed(1)
          : '0.0';

      // Escape commas and quotes in app names
      final safeName = _escapeCSVField(appName.toString());
      final safePackage = _escapeCSVField(packageName.toString());

      buffer.writeln('$dateStr,$safeName,$safePackage,$durationMinutes,$durationHours%,$percentage%');
    }

    // Add summary row
    buffer.writeln('');
    buffer.writeln('SUMMARY');
    buffer.writeln('Total Apps,${sortedData.length}');
    buffer.writeln('Total Duration (minutes),${totalMs ~/ (1000 * 60)}');
    buffer.writeln('Total Duration (hours),${(totalMs / (1000 * 60 * 60)).toStringAsFixed(2)}');
    buffer.writeln('Export Date,${dateFormat.format(DateTime.now())}');

    return buffer.toString();
  }

  /// Generate CSV for date range data
  static String generateRangeCSV(
    Map<String, List<Map<String, dynamic>>> dateRangeData,
  ) {
    if (dateRangeData.isEmpty) {
      return _generateEmptyCSV();
    }

    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // Add header
    buffer.writeln('Date,App Name,Package Name,Duration (minutes),Duration (hours),Percentage');

    // Calculate total duration across all dates
    int totalMs = 0;
    for (final dayData in dateRangeData.values) {
      for (final app in dayData) {
        totalMs += (app['usageTime'] as int?) ?? 0;
      }
    }

    // Process each date
    for (final entry in dateRangeData.entries) {
      final date = entry.key;
      final apps = entry.value;

      // Sort by usage time
      apps.sort((a, b) => (b['usageTime'] as int).compareTo(a['usageTime'] as int));

      for (final app in apps) {
        final appName = app['appName'] ?? 'Unknown';
        final packageName = app['packageName'] ?? 'unknown';
        final usageTimeMs = (app['usageTime'] as int?) ?? 0;

        final durationMinutes = usageTimeMs ~/ (1000 * 60);
        final durationHours = (usageTimeMs / (1000 * 60 * 60)).toStringAsFixed(2);
        final percentage = totalMs > 0
            ? ((usageTimeMs / totalMs) * 100).toStringAsFixed(1)
            : '0.0';

        final safeName = _escapeCSVField(appName.toString());
        final safePackage = _escapeCSVField(packageName.toString());

        buffer.writeln('$date,$safeName,$safePackage,$durationMinutes,$durationHours%,$percentage%');
      }
    }

    // Add summary
    buffer.writeln('');
    buffer.writeln('SUMMARY');
    buffer.writeln('Total Dates,${dateRangeData.length}');
    buffer.writeln('Total Duration (minutes),${totalMs ~/ (1000 * 60)}');
    buffer.writeln('Total Duration (hours),${(totalMs / (1000 * 60 * 60)).toStringAsFixed(2)}');
    buffer.writeln('Export Date,${dateFormat.format(DateTime.now())}');

    return buffer.toString();
  }

  /// Escape special characters in CSV fields
  static String _escapeCSVField(String field) {
    // If field contains comma, newline, or quote, wrap in quotes and escape quotes
    if (field.contains(',') || field.contains('\n') || field.contains('"')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Generate empty CSV with headers only
  static String _generateEmptyCSV() {
    final buffer = StringBuffer();
    buffer.writeln('Date,App Name,Package Name,Duration (minutes),Duration (hours),Percentage');
    buffer.writeln('');
    buffer.writeln('No data available');
    return buffer.toString();
  }

  /// Generate filename with timestamp
  static String generateFilename({String? prefix}) {
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final name = prefix ?? 'app-usage';
    return '$name-$timestamp.csv';
  }
}
