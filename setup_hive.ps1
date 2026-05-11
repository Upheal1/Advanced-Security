# PowerShell setup script for offline-first architecture with Hive
# Run from project root: .\setup_hive.ps1

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Setting up Offline-First Architecture" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Get dependencies
Write-Host "[1/4] Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
  Write-Host "ERROR: flutter pub get failed" -ForegroundColor Red
  exit 1
}
Write-Host "✓ Dependencies fetched" -ForegroundColor Green
Write-Host ""

# Step 2: Clean build_runner
Write-Host "[2/4] Cleaning build_runner cache..." -ForegroundColor Yellow
flutter pub run build_runner clean
if ($LASTEXITCODE -ne 0) {
  Write-Host "WARNING: build_runner clean failed (may be first run)" -ForegroundColor Yellow
}
Write-Host "✓ Cache cleaned" -ForegroundColor Green
Write-Host ""

# Step 3: Generate Hive adapters
Write-Host "[3/4] Generating Hive adapters..." -ForegroundColor Yellow
flutter pub run build_runner build
if ($LASTEXITCODE -ne 0) {
  Write-Host "ERROR: build_runner build failed" -ForegroundColor Red
  exit 1
}
Write-Host "✓ Hive adapters generated" -ForegroundColor Green
Write-Host ""

# Step 4: Verify generated files
Write-Host "[4/4] Verifying generated files..." -ForegroundColor Yellow
$generatedFile = "lib\models\hive\app_usage_cache.g.dart"
if (Test-Path $generatedFile) {
  Write-Host "✓ app_usage_cache.g.dart found" -ForegroundColor Green
  Write-Host ""
  Write-Host "==========================================" -ForegroundColor Cyan
  Write-Host "Setup Complete!" -ForegroundColor Cyan
  Write-Host "==========================================" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "Generated file:" -ForegroundColor White
  Write-Host "  lib\models\hive\app_usage_cache.g.dart" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "Next steps:" -ForegroundColor White
  Write-Host "  1. Run 'flutter pub get' again if needed" -ForegroundColor Gray
  Write-Host "  2. Run 'flutter run' to start the app" -ForegroundColor Gray
  Write-Host ""
  Write-Host "To regenerate after model changes:" -ForegroundColor White
  Write-Host "  flutter pub run build_runner build --delete-conflicting-outputs" -ForegroundColor Cyan
  Write-Host ""
} else {
  Write-Host "ERROR: app_usage_cache.g.dart not found" -ForegroundColor Red
  Write-Host "Try running: flutter pub run build_runner build --delete-conflicting-outputs" -ForegroundColor Yellow
  exit 1
}
