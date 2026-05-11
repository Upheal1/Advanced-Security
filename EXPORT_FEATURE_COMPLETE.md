# Export & Share Analytics Feature - Complete Implementation

## Overview

Added comprehensive export and share functionality to the MindQuest Analytics screen. Users can now export their screen time data and charts in multiple formats and share them directly from the app.

## Features Implemented

### 1. **Export Formats**
- **PNG Chart Export**: Capture analytics charts as high-quality images
- **CSV Data Export**: Export detailed usage data with summaries
- **Combined Export & Share**: Generate all files and share via system share sheet

### 2. **Data Included in CSV**
- Date, App Name, Package Name, Duration (minutes/hours), Percentage
- Sorted by usage time (descending)
- Summary row with totals and metadata
- Proper CSV formatting with escaped special characters

### 3. **User Experience**
- Share button in AppBar (next to Refresh button)
- Modal bottom sheet with export options
- Loading states with progress messages
- Success/error notifications
- Automatic temporary file cleanup

## Files Created

### 1. `lib/models/csv_exporter.dart` (170 lines)

**Purpose**: Handle CSV generation and formatting

**Key Methods**:
- `generateUsageCSV()`: Generate CSV from single day data
- `generateRangeCSV()`: Generate CSV from date range data
- `generateFilename()`: Create timestamped filenames
- `_escapeCSVField()`: Properly format fields with special characters

**Features**:
- Calculates percentages based on total screen time
- Formats durations in minutes and hours
- Includes summary statistics
- Handles empty data gracefully

```dart
// Example usage
final csv = CSVExporter.generateUsageCSV(usageData);
final filename = CSVExporter.generateFilename(prefix: 'screen-time');
```

### 2. `lib/services/export_service.dart` (220 lines)

**Purpose**: Core export functionality and file operations

**Key Methods**:
- `exportChartAsImage()`: Capture RepaintBoundary widget as PNG
- `exportDataAsCSV()`: Generate and save CSV file
- `exportRangeDataAsCSV()`: Export date range data
- `shareFile()`: Share single file via system share sheet
- `shareFiles()`: Share multiple files
- `cleanupTempFiles()`: Delete temporary exports
- `formatFileSize()`: Human-readable file sizes

**Features**:
- Uses RepaintBoundary for high-quality chart capture (2x pixel ratio)
- Stores files in system temp directory
- Non-blocking async operations
- Comprehensive error handling
- Automatic file cleanup after sharing

**File Locations**:
- Uses `getTemporaryDirectory()` from path_provider
- Automatic deletion after share completion

```dart
// Example usage
final chartFile = await ExportService.exportChartAsImage(chartKey, 'chart.png');
final csvFile = await ExportService.exportDataAsCSV(usageData);
await ExportService.shareFiles([chartFile, csvFile]);
await ExportService.cleanupTempFiles([chartFile, csvFile]);
```

### 3. `lib/widgets/analytics/export_bottom_sheet.dart` (350 lines)

**Purpose**: UI for export options

**Key Components**:
- `ExportBottomSheet`: Main widget with export options
- `_ExportOption`: Individual option tile with icon and description

**Features**:
- Three export options:
  1. Export Chart as Image
  2. Export Data as CSV
  3. Export & Share (both files)
- Loading indicators with progress messages
- Error and success notifications
- Proper dark/light theme support
- Icon animations on tap

**Usage**:
```dart
showModalBottomSheet(
  context: context,
  builder: (_) => ExportBottomSheet(
    usageData: usageData,
    chartKey: _chartKey,
    onSuccess: () => print('Export successful'),
    onError: (msg) => print('Error: $msg'),
  ),
);
```

## Modified Files

### 1. `pubspec.yaml`
**Added Dependencies**:
```yaml
dependencies:
  share_plus: ^7.2.1      # System share functionality
  path_provider: ^2.1.1   # Access temp directory
```

### 2. `lib/screens/analytics_screen.dart`
**Additions**:
- Added imports for export service and widgets
- Added GlobalKey fields for charts:
  - `_pieChartKey`: For pie chart export
  - `_weeklyChartKey`: For weekly trend chart
- Added export button to AppBar actions
- Added `_showExportOptions()` method

**Changes**:
```dart
// In AppBar.actions
IconButton(
  onPressed: _showExportOptions,
  icon: const Icon(LucideIcons.share2, color: Colors.white),
  tooltip: 'Export & Share',
),

// New method
void _showExportOptions() {
  showModalBottomSheet(
    context: context,
    builder: (_) => ExportBottomSheet(
      usageData: usageData,
      chartKey: _pieChartKey,
      onSuccess: () => // Handle success
      onError: (msg) => // Handle error
    ),
  );
}
```

### 3. `lib/main.dart`
**Uncommented**:
- Added `import 'models/hive/app_usage_cache.g.dart';`
- Uncommented `Hive.registerAdapter(AppUsageCacheAdapter());`

### 4. `lib/models/hive/app_usage_cache.dart`
**Uncommented**:
- Uncommented `part 'app_usage_cache.g.dart';`

## Data Flow

### Export Chart
1. User taps share icon → Shows bottom sheet
2. User selects "Export Chart as Image"
3. Service captures RepaintBoundary with 2x pixel ratio
4. Converts to PNG and saves to temp directory
5. Shows success message
6. Returns to screen

### Export CSV
1. User selects "Export Data as CSV"
2. Service generates CSV with:
   - Header row with columns
   - Data rows (sorted by usage)
   - Summary section
3. Saves to temp directory
4. Shows success message

### Export & Share (Combined)
1. User selects "Export & Share"
2. Service captures chart → Saves as PNG
3. Service generates CSV → Saves to temp
4. Opens system share sheet with both files
5. User selects sharing method (email, messaging, cloud, etc.)
6. After sharing, temp files are automatically deleted

## CSV Format Example

```
Date,App Name,Package Name,Duration (minutes),Duration (hours),Percentage
2026-01-04,YouTube,com.google.android.youtube,120,2.00,25.5%
2026-01-04,Instagram,com.instagram.android,90,1.50,19.1%
2026-01-04,WhatsApp,com.whatsapp,60,1.00,12.8%

SUMMARY
Total Apps,3
Total Duration (minutes),270
Total Duration (hours),4.50
Export Date,2026-01-04 14:35:22
```

## Error Handling

### Chart Export Errors
- Invalid GlobalKey → Shows "Chart boundary not found"
- Image conversion fails → Shows "Failed to convert image"
- File write fails → Shows error message

### CSV Errors
- File system issues → Shows "Failed to generate CSV"
- Permission denied → Graceful error handling

### Share Errors
- No sharing apps available → System handles
- User cancels share → Silent cancellation
- File cleanup failures → Logged but doesn't block

## User Feedback

### Success States
- Green snackbar with checkmark icon
- Message: "Chart exported successfully"
- Auto-dismiss after 2-3 seconds

### Error States
- Red snackbar with alert icon
- Detailed error message
- Longer display time (4 seconds)

### Loading States
- Modal shows loading indicator
- Progress messages:
  - "Capturing chart..."
  - "Generating CSV..."
  - "Opening share menu..."

## Performance Considerations

1. **Image Export**:
   - 2x pixel ratio for quality
   - RepaintBoundary provides efficient capture
   - PNG compression handled by Flutter

2. **CSV Generation**:
   - String buffer (efficient for large data)
   - Sorting happens in memory
   - Linear time complexity O(n)

3. **File Operations**:
   - Async/await prevents UI blocking
   - Temp files automatically cleaned up
   - No persistent storage needed

4. **Memory Management**:
   - Large byte buffers released after save
   - Temp files cleaned up after share
   - No memory leaks in state management

## Testing Checklist

- [ ] Export chart as PNG
  - [ ] Image quality is good
  - [ ] File size is reasonable
  - [ ] Chart is properly captured

- [ ] Export data as CSV
  - [ ] CSV opens in Excel/Sheets
  - [ ] Data is properly formatted
  - [ ] Summary row shows correct totals
  - [ ] Percentages add up to ~100%

- [ ] Export & Share
  - [ ] Both files are shared
  - [ ] Temp files cleaned up after
  - [ ] No leftover files in temp directory

- [ ] Error Handling
  - [ ] Empty data shows warning
  - [ ] Network issues handled gracefully
  - [ ] Permissions handled properly

- [ ] UI/UX
  - [ ] Loading states show progress
  - [ ] Success/error messages clear
  - [ ] Dark/light theme both work
  - [ ] Bottom sheet dismisses properly

## Next Steps (Optional Enhancements)

1. **Cloud Storage Integration**
   - Save exports to Google Drive/OneDrive
   - Add cloud backup option

2. **Email Integration**
   - Direct email with attachments
   - Template formatting

3. **Advanced Filters**
   - Filter by app category
   - Custom date ranges
   - Threshold filtering

4. **Analytics Dashboard**
   - Trend analysis
   - Comparison charts
   - Historical data viewer

5. **Performance Monitoring**
   - Track export times
   - File size statistics
   - User analytics

## Dependencies

```yaml
# Added to pubspec.yaml
share_plus: ^7.2.1        # Cross-platform sharing
path_provider: ^2.1.1     # Temp directory access

# Already present, used here
google_fonts: ^6.3.3      # Typography
lucide_icons: ^0.257.0    # Icons
intl: ^0.20.2             # Date formatting
provider: ^6.1.1          # State management
fl_chart: ^1.1.1          # Chart export source
```

## Implementation Complete ✓

All export and share functionality has been successfully integrated:
- ✓ CSV exporter with proper formatting
- ✓ Export service with file operations
- ✓ Bottom sheet UI for options
- ✓ Analytics screen integration
- ✓ Error handling and user feedback
- ✓ Temporary file cleanup
- ✓ Dark/light theme support

Users can now easily export and share their analytics data!
