# Export Feature - Quick Setup Guide

## Installation Steps

### 1. Update Dependencies
The following packages have been added to `pubspec.yaml`:
```yaml
share_plus: ^7.2.1      # System sharing
path_provider: ^2.1.1   # Temp directory access
```

### 2. Get Dependencies
```bash
flutter pub get
```

### 3. Run Build Runner (if needed)
```bash
flutter pub run build_runner build
```

### 4. Test the Feature

**To access Export functionality**:
1. Open the app
2. Go to Analytics screen
3. Tap the Share button (📤) in the AppBar
4. Choose export option:
   - **Export Chart as Image**: Saves pie chart as PNG
   - **Export Data as CSV**: Saves usage data as spreadsheet
   - **Export & Share**: Both files with system share dialog

## Files Added/Modified

### New Files
- `lib/models/csv_exporter.dart` - CSV generation
- `lib/services/export_service.dart` - Export operations
- `lib/widgets/analytics/export_bottom_sheet.dart` - UI
- `EXPORT_FEATURE_COMPLETE.md` - Full documentation

### Modified Files
- `pubspec.yaml` - Added 2 dependencies
- `lib/screens/analytics_screen.dart` - Added export button and UI
- `lib/main.dart` - Uncommented Hive adapter
- `lib/models/hive/app_usage_cache.dart` - Uncommented part directive

## Features

✓ Export charts as PNG images
✓ Export data as formatted CSV files
✓ Share multiple files at once
✓ Automatic temporary file cleanup
✓ Loading states with progress
✓ Error handling and user feedback
✓ Dark/light theme support
✓ CSV summaries and statistics

## Usage Example

In Analytics Screen:

```dart
// Share button taps this
void _showExportOptions() {
  showModalBottomSheet(
    context: context,
    builder: (_) => ExportBottomSheet(
      usageData: usageData,
      chartKey: _pieChartKey,
      onSuccess: () => print('Export successful!'),
      onError: (msg) => print('Error: $msg'),
    ),
  );
}
```

## CSV Output Format

Example of generated CSV:
```
Date,App Name,Package Name,Duration (minutes),Duration (hours),Percentage
2026-01-04,YouTube,com.google.android.youtube,120,2.00,25.5%
2026-01-04,Instagram,com.instagram.android,90,1.50,19.1%

SUMMARY
Total Apps,2
Total Duration (minutes),210
Total Duration (hours),3.50
Export Date,2026-01-04 14:35:22
```

## Troubleshooting

### Share button not showing
- Ensure you're on the Analytics screen
- Make sure there's usage data available
- Try hot restart if button doesn't appear

### Export fails with "No data available"
- Check that the app has collected usage data
- Go back and return to Analytics screen to refresh

### Files not sharing
- Ensure your device has share apps installed (email, messaging, etc.)
- Check permissions for share_plus package

### CSV opens incorrectly
- Use UTF-8 encoding when opening in Excel
- Some Excel versions need manual column separator setup

## Performance Notes

- Chart export uses 2x pixel ratio for quality
- CSV generation is optimized for large datasets
- Temp files are automatically cleaned up
- No persistent storage overhead

## Next Steps

To enhance further:
1. Add more export formats (JSON, PDF)
2. Add email integration
3. Add cloud storage options
4. Add advanced filtering
5. Add export scheduling

## Support

For issues or feature requests, check:
- `EXPORT_FEATURE_COMPLETE.md` - Detailed documentation
- `lib/services/export_service.dart` - Implementation details
- `lib/models/csv_exporter.dart` - CSV formatting logic
