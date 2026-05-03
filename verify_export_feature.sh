#!/bin/bash

# Export Feature Installation Verification Script
# This script checks if all export feature components are properly set up

echo "=================================================="
echo "Export Feature Verification Script"
echo "=================================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Function to check if file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} Found: $1"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Missing: $1"
        ((FAILED++))
    fi
}

# Function to check if text exists in file
check_content() {
    if grep -q "$2" "$1" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Found in $1: $2"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Missing in $1: $2"
        ((FAILED++))
    fi
}

echo "Checking files..."
echo ""

# Check new files
check_file "lib/models/csv_exporter.dart"
check_file "lib/services/export_service.dart"
check_file "lib/widgets/analytics/export_bottom_sheet.dart"

echo ""
echo "Checking dependencies..."
echo ""

# Check pubspec.yaml has share_plus
check_content "pubspec.yaml" "share_plus: ^7.2.1"
check_content "pubspec.yaml" "path_provider: ^2.1.1"

echo ""
echo "Checking imports..."
echo ""

# Check analytics_screen.dart imports
check_content "lib/screens/analytics_screen.dart" "import.*export_service"
check_content "lib/screens/analytics_screen.dart" "import.*export_bottom_sheet"

echo ""
echo "Checking integration..."
echo ""

# Check analytics screen has share button
check_content "lib/screens/analytics_screen.dart" "_showExportOptions"
check_content "lib/screens/analytics_screen.dart" "LucideIcons.share2"
check_content "lib/screens/analytics_screen.dart" "_pieChartKey"

echo ""
echo "Checking CSV exporter..."
echo ""

# Check CSV exporter methods
check_content "lib/models/csv_exporter.dart" "generateUsageCSV"
check_content "lib/models/csv_exporter.dart" "generateRangeCSV"
check_content "lib/models/csv_exporter.dart" "generateFilename"

echo ""
echo "Checking export service..."
echo ""

# Check export service methods
check_content "lib/services/export_service.dart" "exportChartAsImage"
check_content "lib/services/export_service.dart" "exportDataAsCSV"
check_content "lib/services/export_service.dart" "shareFile"
check_content "lib/services/export_service.dart" "cleanupTempFiles"

echo ""
echo "Checking export bottom sheet..."
echo ""

# Check export bottom sheet
check_content "lib/widgets/analytics/export_bottom_sheet.dart" "ExportBottomSheet"
check_content "lib/widgets/analytics/export_bottom_sheet.dart" "_ExportOption"

echo ""
echo "Checking documentation..."
echo ""

# Check documentation files
check_file "EXPORT_FEATURE_COMPLETE.md"
check_file "EXPORT_SETUP_GUIDE.md"
check_file "EXPORT_IMPLEMENTATION_SUMMARY.md"
check_file "EXPORT_QUICK_REFERENCE.md"

echo ""
echo "=================================================="
echo "Verification Summary"
echo "=================================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Export feature is ready.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run: flutter pub get"
    echo "2. Run: flutter run"
    echo "3. Navigate to Analytics screen"
    echo "4. Tap the Share button (📤)"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some checks failed. Please review the output above.${NC}"
    echo ""
    exit 1
fi
