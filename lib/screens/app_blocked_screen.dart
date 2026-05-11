import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../viewmodels/blocked_app_view_model.dart';

class AppBlockedScreen extends StatelessWidget {
  const AppBlockedScreen({
    super.key,
    required this.viewModel,
    this.onReturnHome,
    this.onTakeBreath,
  });

  final BlockedAppViewModel viewModel;
  final VoidCallback? onReturnHome;
  final VoidCallback? onTakeBreath;

  @override
  Widget build(BuildContext context) {
    // Provide the view model to the widget tree (MVVM + Provider).
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: const _AppBlockedBody(),
    );
  }
}

class _AppBlockedBody extends StatelessWidget {
  const _AppBlockedBody();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F1419) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryText = isDark ? Colors.white70 : AppColors.textSecondary;

    return WillPopScope(
      // Prevent back navigation or bypassing the block screen.
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Consumer<BlockedAppViewModel>(
                  builder: (context, vm, _) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.block,
                            color: AppColors.orange,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'App Blocked',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${vm.appName} is blocked right now.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vm.reasonText,
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : AppColors.textPrimary.withOpacity(0.08),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Remaining time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                vm.remainingText,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'This is a moment to pause and choose what matters.',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        if (vm.showTakeBreath)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                // Optional mindful action; stays on the block screen.
                                final handler =
                                    context.findAncestorWidgetOfExactType<AppBlockedScreen>();
                                handler?.onTakeBreath?.call();
                              },
                              child: const Text('Take a deep breath'),
                            ),
                          ),
                        if (vm.showReturnHome) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // Optional navigation back to the app home.
                                final handler =
                                    context.findAncestorWidgetOfExactType<AppBlockedScreen>();
                                handler?.onReturnHome?.call();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isDark ? AppColors.purple : AppColors.teal,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Return to Home'),
                            ),
                          ),
                        ],
                        if (vm.allowEmergencyAllow) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: vm.emergencyGranted
                                  ? null
                                  : () async {
                                      await vm.grantEmergencyAllow();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Emergency allow granted for 5 minutes'),
                                            backgroundColor: Color(0xFF4CAF50),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        // Close block screen after 1 second
                                        await Future.delayed(const Duration(seconds: 1));
                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                      }
                                    },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.orange,
                              ),
                              child: Text(
                                vm.emergencyGranted
                                    ? 'Emergency Granted'
                                    : 'Emergency Allow (5 min)',
                              ),
                            ),
                          ),
                        ],
                        if (vm.hasUsedEmergencyToday && vm.canEmergencyAllow) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Emergency allow already used today',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.orange.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
