# App Icon Setup

## Required File

Place your UpHeal logo image here as: **`app_icon.png`**

## Image Requirements

- **Format**: PNG
- **Size**: 1024x1024 pixels (square)
- **Background**: Transparent or solid color
- **Content**: 
  - For best results, use the graphic element (upward arrow + human figure) from the UpHeal logo
  - The logo should be centered and fill approximately 80% of the square (safe zone for adaptive icons)
  - Text "UpHeal" is optional - graphic-only works better for small icon sizes

## After Adding the Image

1. Run: `flutter pub get`
2. Run: `flutter pub run flutter_launcher_icons`
3. Rebuild your app to see the new icons

## Configuration

The icon configuration is set in `pubspec.yaml` under `flutter_launcher_icons`:
- **Android**: Adaptive icon with purple background (#7C3AED)
- **iOS**: All required sizes (20x20 to 1024x1024)
- **Web**: Favicon and PWA icons
- **Windows**: .ico file
- **macOS**: All required sizes

## Notes

- The adaptive icon background uses purple (#7C3AED) to match the app's dark mode theme
- If you prefer teal background, update `adaptive_icon_background` in pubspec.yaml to `"#14B8A6"`
