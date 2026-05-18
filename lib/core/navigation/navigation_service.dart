import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static NavigatorState? get navigator => navigatorKey.currentState;
  static BuildContext? get currentContext => navigatorKey.currentContext;

  static bool canPop() {
    final context = navigatorKey.currentContext;
    if (context == null) return false;
    return Navigator.of(context).canPop();
  }

  static Future<bool> maybePop<T extends Object?>([T? result]) async {
    final context = navigatorKey.currentContext;
    if (context == null) return false;
    
    if (!context.mounted) return false;
    
    final result2 = await Navigator.of(context).maybePop<T>(result);
    return result2;
  }

  static void pop<T extends Object?>([T? result]) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    if (!context.mounted) return;
    
    Navigator.of(context).pop(result);
  }

  static void popUntil(bool Function(Route<dynamic>) predicate) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    Navigator.of(context).popUntil(predicate);
  }

  static void showSnackBar(String message, {bool isError = false}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showLoadingSnackBar(String message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 30),
      ),
    );
  }

  static void hideSnackBar() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}

class NavigationThrottle {
  static DateTime? _lastNavigationTime;
  static const int _minDelayMs = 300;

  static bool canNavigate() {
    final now = DateTime.now();
    if (_lastNavigationTime == null) {
      _lastNavigationTime = now;
      return true;
    }

    final diff = now.difference(_lastNavigationTime!).inMilliseconds;
    if (diff < _minDelayMs) {
      return false;
    }

    _lastNavigationTime = now;
    return true;
  }

  static void execute(void Function() action) {
    if (canNavigate()) {
      HapticFeedback.lightImpact();
      action();
    }
  }
}

extension SafeNavigationExtension on BuildContext {
  void safePop() {
    if (mounted) {
      Navigator.of(this).maybePop();
    }
  }
}