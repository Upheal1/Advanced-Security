import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../main.dart';

class DrawerMenuButton extends StatelessWidget {
  final Color? iconColor;
  final double size;
  final String tooltip;

  const DrawerMenuButton({super.key, this.iconColor, this.size = 24, this.tooltip = 'Menu'});

  @override
  Widget build(BuildContext context) {
    final color = iconColor ??
        (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary);
    return IconButton(
      icon: Icon(LucideIcons.menu, color: color, size: size),
      onPressed: () {
        // Open the root drawer via the global scaffold key
        rootScaffoldKey.currentState?.openDrawer();
      },
      tooltip: tooltip,
    );
  }
}
