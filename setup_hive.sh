#!/bin/bash
# Setup script for offline-first architecture with Hive

echo "=========================================="
echo "Setting up Offline-First Architecture"
echo "=========================================="
echo ""

# Step 1: Get dependencies
echo "[1/4] Getting Flutter dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
  echo "ERROR: flutter pub get failed"
  exit 1
fi
echo "✓ Dependencies fetched"
echo ""

# Step 2: Clean build_runner
echo "[2/4] Cleaning build_runner cache..."
flutter pub run build_runner clean
if [ $? -ne 0 ]; then
  echo "WARNING: build_runner clean failed (may be first run)"
fi
echo "✓ Cache cleaned"
echo ""

# Step 3: Generate Hive adapters
echo "[3/4] Generating Hive adapters..."
flutter pub run build_runner build
if [ $? -ne 0 ]; then
  echo "ERROR: build_runner build failed"
  exit 1
fi
echo "✓ Hive adapters generated"
echo ""

# Step 4: Verify generated files
echo "[4/4] Verifying generated files..."
if [ -f "lib/models/hive/app_usage_cache.g.dart" ]; then
  echo "✓ app_usage_cache.g.dart found"
  echo ""
  echo "=========================================="
  echo "Setup Complete!"
  echo "=========================================="
  echo ""
  echo "Generated file:"
  echo "  lib/models/hive/app_usage_cache.g.dart"
  echo ""
  echo "Next steps:"
  echo "  1. Run 'flutter pub get' again if needed"
  echo "  2. Run 'flutter run' to start the app"
  echo ""
  echo "To regenerate after model changes:"
  echo "  flutter pub run build_runner build --delete-conflicting-outputs"
  echo ""
else
  echo "ERROR: app_usage_cache.g.dart not found"
  echo "Try running: flutter pub run build_runner build --delete-conflicting-outputs"
  exit 1
fi
