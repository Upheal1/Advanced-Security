# Export Feature Verification Script (Windows PowerShell)
# This script verifies all export feature components are properly installed

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Export Feature Verification Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$PASSED = 0
$FAILED = 0

# Function to check file exists
function Check-File {
    param([string]$FilePath, [string]$Description)
    
    if (Test-Path $FilePath) {
        Write-Host "✓ Found: $Description" -ForegroundColor Green
        $script:PASSED++
    }
    else {
        Write-Host "✗ Missing: $Description" -ForegroundColor Red
        $script:FAILED++
    }
}

# Function to check content in file
function Check-Content {
    param([string]$FilePath, [string]$Pattern, [string]$Description)
    
    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Raw
        if ($content -match [regex]::Escape($Pattern)) {
            Write-Host "✓ $Description" -ForegroundColor Green
            $script:PASSED++
        }
        else {
            Write-Host "✗ $Description" -ForegroundColor Red
            $script:FAILED++
        }
    }
    else {
        Write-Host "✗ File not found: $FilePath" -ForegroundColor Red
        $script:FAILED++
    }
}

Write-Host "Checking files..." -ForegroundColor Yellow
Write-Host ""

# Check new files
Check-File "lib/models/csv_exporter.dart" "CSV Exporter"
Check-File "lib/services/export_service.dart" "Export Service"
Check-File "lib/widgets/analytics/export_bottom_sheet.dart" "Export Bottom Sheet"

Write-Host ""
Write-Host "Checking dependencies..." -ForegroundColor Yellow
Write-Host ""

# Check pubspec.yaml
Check-Content "pubspec.yaml" "share_plus: ^7.2.1" "share_plus dependency"
Check-Content "pubspec.yaml" "path_provider: ^2.1.1" "path_provider dependency"

Write-Host ""
Write-Host "Checking imports..." -ForegroundColor Yellow
Write-Host ""

# Check imports
Check-Content "lib/screens/analytics_screen.dart" "import.*export_service" "Export service import"
Check-Content "lib/screens/analytics_screen.dart" "import.*export_bottom_sheet" "Export bottom sheet import"

Write-Host ""
Write-Host "Checking integration..." -ForegroundColor Yellow
Write-Host ""

# Check integration
Check-Content "lib/screens/analytics_screen.dart" "_showExportOptions" "Export options method"
Check-Content "lib/screens/analytics_screen.dart" "LucideIcons.share2" "Share button icon"
Check-Content "lib/screens/analytics_screen.dart" "_pieChartKey" "Chart GlobalKey"

Write-Host ""
Write-Host "Checking CSV exporter methods..." -ForegroundColor Yellow
Write-Host ""

Check-Content "lib/models/csv_exporter.dart" "generateUsageCSV" "generateUsageCSV method"
Check-Content "lib/models/csv_exporter.dart" "generateRangeCSV" "generateRangeCSV method"
Check-Content "lib/models/csv_exporter.dart" "generateFilename" "generateFilename method"

Write-Host ""
Write-Host "Checking export service methods..." -ForegroundColor Yellow
Write-Host ""

Check-Content "lib/services/export_service.dart" "exportChartAsImage" "exportChartAsImage method"
Check-Content "lib/services/export_service.dart" "exportDataAsCSV" "exportDataAsCSV method"
Check-Content "lib/services/export_service.dart" "shareFile" "shareFile method"
Check-Content "lib/services/export_service.dart" "cleanupTempFiles" "cleanupTempFiles method"

Write-Host ""
Write-Host "Checking export bottom sheet..." -ForegroundColor Yellow
Write-Host ""

Check-Content "lib/widgets/analytics/export_bottom_sheet.dart" "ExportBottomSheet" "ExportBottomSheet class"
Check-Content "lib/widgets/analytics/export_bottom_sheet.dart" "_ExportOption" "_ExportOption class"

Write-Host ""
Write-Host "Checking documentation..." -ForegroundColor Yellow
Write-Host ""

Check-File "EXPORT_FEATURE_COMPLETE.md" "Complete documentation"
Check-File "EXPORT_SETUP_GUIDE.md" "Setup guide"
Check-File "EXPORT_IMPLEMENTATION_SUMMARY.md" "Implementation summary"
Check-File "EXPORT_QUICK_REFERENCE.md" "Quick reference"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Verification Summary" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Passed: $PASSED" -ForegroundColor Green
Write-Host "Failed: $FAILED" -ForegroundColor $(if ($FAILED -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($FAILED -eq 0) {
    Write-Host "✓ All checks passed! Export feature is ready." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Run: flutter pub get" -ForegroundColor Gray
    Write-Host "  2. Run: flutter run" -ForegroundColor Gray
    Write-Host "  3. Navigate to Analytics screen" -ForegroundColor Gray
    Write-Host "  4. Tap the Share button (📤)" -ForegroundColor Gray
    Write-Host ""
    exit 0
}
else {
    Write-Host "✗ Some checks failed. Please review the output above." -ForegroundColor Red
    Write-Host ""
    exit 1
}
