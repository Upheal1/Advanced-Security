import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NavigationErrorDisplay extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onGoHome;

  const NavigationErrorDisplay({
    super.key,
    this.errorMessage,
    this.onRetry,
    this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A2E),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  LucideIcons.alertTriangle,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage ?? 'We encountered an unexpected issue. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              if (onRetry != null || onGoHome != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (onRetry != null)
                      _ActionButton(
                        label: 'Try Again',
                        icon: LucideIcons.refreshCw,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          onRetry!();
                        },
                        isPrimary: true,
                      ),
                    if (onRetry != null && onGoHome != null)
                      const SizedBox(width: 16),
                    if (onGoHome != null)
                      _ActionButton(
                        label: 'Go Home',
                        icon: LucideIcons.home,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          onGoHome!();
                        },
                        isPrimary: false,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                )
              : null,
          color: isPrimary ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: isPrimary
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorBoundaryWidget extends StatefulWidget {
  final Widget child;
  final Widget Function(String error)? errorBuilder;

  const ErrorBoundaryWidget({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<ErrorBoundaryWidget> {
  bool _hasError = false;
  String _errorMessage = '';

  void resetError() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_errorMessage);
      }
      return NavigationErrorDisplay(
        errorMessage: _errorMessage,
        onRetry: resetError,
      );
    }

    return widget.child;
  }
}

void handleFlutterError(FlutterErrorDetails details) {
  debugPrint('═══════════════════════════════════════════════════════════');
  debugPrint('FLUTTER ERROR: ${details.exception}');
  debugPrint('═══════════════════════════════════════════════════════════');
}

void handlePlatformError(Object error, StackTrace stack) {
  debugPrint('═══════════════════════════════════════════════════════════');
  debugPrint('PLATFORM ERROR: $error');
  debugPrint('═══════════════════════════════════════════════════════════');
}