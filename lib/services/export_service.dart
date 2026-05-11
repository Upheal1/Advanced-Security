import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/csv_exporter.dart';

/// Service for exporting analytics data and charts
class ExportService {
  static const String _logPrefix = '[ExportService]';

  /// Export a chart widget as PNG image
  /// Uses RepaintBoundary to capture the widget
  static Future<File?> exportChartAsImage(
    GlobalKey chartKey,
    String filename,
  ) async {
    try {
      debugPrintExport('Exporting chart as image: $filename');

      // Get the RenderRepaintBoundary
      final boundary = chartKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      
      if (boundary == null) {
        debugPrintExport('ERROR: Chart boundary not found');
        return null;
      }

      // Capture the widget as image
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrintExport('ERROR: Failed to convert image to bytes');
        return null;
      }

      // Get temp directory and save file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');

      await file.writeAsBytes(byteData.buffer.asUint8List());
      debugPrintExport('Chart exported successfully: ${file.path}');

      return file;
    } catch (e) {
      debugPrintExport('ERROR exporting chart: $e');
      rethrow;
    }
  }

  /// Export app usage data as CSV file
  static Future<File?> exportDataAsCSV(
    List<Map<String, dynamic>> usageData, {
    String? filename,
  }) async {
    try {
      debugPrintExport('Exporting data as CSV');

      // Generate CSV content
      final csvContent = CSVExporter.generateUsageCSV(usageData);

      // Create filename if not provided
      final csvFilename = filename ?? CSVExporter.generateFilename(prefix: 'screen-time-data');

      // Get temp directory and save file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$csvFilename');

      await file.writeAsString(csvContent, encoding: utf8);
      debugPrintExport('CSV exported successfully: ${file.path}');

      return file;
    } catch (e) {
      debugPrintExport('ERROR exporting CSV: $e');
      rethrow;
    }
  }

  /// Export date range data as CSV
  static Future<File?> exportRangeDataAsCSV(
    Map<String, List<Map<String, dynamic>>> dateRangeData, {
    String? filename,
  }) async {
    try {
      debugPrintExport('Exporting date range data as CSV');

      final csvContent = CSVExporter.generateRangeCSV(dateRangeData);

      final csvFilename = filename ?? CSVExporter.generateFilename(prefix: 'screen-time-range');

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$csvFilename');

      await file.writeAsString(csvContent, encoding: utf8);
      debugPrintExport('Range CSV exported successfully: ${file.path}');

      return file;
    } catch (e) {
      debugPrintExport('ERROR exporting range CSV: $e');
      rethrow;
    }
  }

  /// Share a single file
  static Future<bool> shareFile(
    File file, {
    String? subject,
    String? text,
  }) async {
    try {
      debugPrintExport('Sharing file: ${file.path}');

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
        text: text,
      );

      final shared = result.status == ShareResultStatus.success;
      debugPrintExport('File ${shared ? 'shared' : 'not shared'} successfully');

      return shared;
    } catch (e) {
      debugPrintExport('ERROR sharing file: $e');
      rethrow;
    }
  }

  /// Share multiple files
  static Future<bool> shareFiles(
    List<File> files, {
    String? subject,
    String? text,
  }) async {
    try {
      debugPrintExport('Sharing ${files.length} files');

      final xFiles = files.map((f) => XFile(f.path)).toList();
      
      final result = await Share.shareXFiles(
        xFiles,
        subject: subject,
        text: text,
      );

      final shared = result.status == ShareResultStatus.success;
      debugPrintExport('Files ${shared ? 'shared' : 'not shared'} successfully');

      return shared;
    } catch (e) {
      debugPrintExport('ERROR sharing files: $e');
      rethrow;
    }
  }

  /// Clean up temporary files
  static Future<void> cleanupTempFiles(List<File> files) async {
    try {
      for (final file in files) {
        if (await file.exists()) {
          await file.delete();
          debugPrintExport('Deleted temp file: ${file.path}');
        }
      }
    } catch (e) {
      debugPrintExport('ERROR cleaning up temp files: $e');
    }
  }

  /// Get file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double dbytes = bytes.toDouble();
    while (dbytes >= 1024 && i < suffixes.length - 1) {
      dbytes /= 1024;
      i++;
    }
    return '${dbytes.toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// Debug print with consistent prefix
  static void debugPrintExport(String message) {
    debugPrint('$_logPrefix $message');
  }
}
