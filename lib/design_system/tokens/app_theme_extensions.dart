import 'package:flutter/material.dart';

import 'app_gradients.dart';
import 'app_shadows.dart';

extension AppThemeDataX on ThemeData {
  AppGradientTheme get appGradients => extension<AppGradientTheme>()!;

  AppShadowTheme get appShadows => extension<AppShadowTheme>()!;
}

extension AppBuildContextThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);

  AppGradientTheme get appGradients => theme.appGradients;

  AppShadowTheme get appShadows => theme.appShadows;
}
