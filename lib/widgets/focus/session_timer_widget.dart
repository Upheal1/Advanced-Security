import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/focus_session_model.dart';
import '../../models/hive/focus_session_history.dart';

/// Circular timer widget for focus sessions with animated progress
class SessionTimerWidget extends StatefulWidget {
  final FocusSessionData? session;
  final FocusSessionStatus status;
  final FocusSessionType selectedType;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;

  const SessionTimerWidget({
    super.key,
    this.session,
    required this.status,
    required this.selectedType,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onStop,
  });

  @override
  State<SessionTimerWidget> createState() => _SessionTimerWidgetState();
}

class _SessionTimerWidgetState extends State<SessionTimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for active state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Progress animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _updateAnimations();
  }

  @override
  void didUpdateWidget(SessionTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    if (widget.status == FocusSessionStatus.running) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Color _getSessionColor() {
    final type = widget.session?.type ?? widget.selectedType;
    switch (type) {
      case FocusSessionType.focus:
        return const Color(0xFF7C3AED); // Purple
      case FocusSessionType.shortBreak:
        return const Color(0xFF10B981); // Green
      case FocusSessionType.longBreak:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  String _getDisplayTime() {
    if (widget.session != null) {
      return widget.session!.formattedTime;
    }
    // Show default time for selected type
    final duration = widget.selectedType.defaultDuration;
    final minutes = duration.inMinutes;
    return '${minutes.toString().padLeft(2, '0')}:00';
  }

  String _getStatusText() {
    switch (widget.status) {
      case FocusSessionStatus.idle:
        return 'Ready to focus';
      case FocusSessionStatus.running:
        return widget.session?.type.displayName ?? 'Focus';
      case FocusSessionStatus.paused:
        return 'Paused';
      case FocusSessionStatus.completed:
        return 'Completed!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getSessionColor();
    final progress = widget.session?.progress ?? 0.0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.status == FocusSessionStatus.running 
              ? _pulseAnimation.value 
              : 1.0,
          child: child,
        );
      },
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(widget.status == FocusSessionStatus.running ? 0.3 : 0.1),
              blurRadius: widget.status == FocusSessionStatus.running ? 30 : 20,
              spreadRadius: widget.status == FocusSessionStatus.running ? 5 : 0,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            CustomPaint(
              size: const Size(260, 260),
              painter: _CircleProgressPainter(
                progress: progress,
                color: color,
                backgroundColor: isDark 
                    ? Colors.white.withOpacity(0.1) 
                    : Colors.grey.shade200,
                strokeWidth: 12,
              ),
            ),
            
            // Center content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Time display
                Text(
                  _getDisplayTime(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 2,
                  ),
                ).animate(
                  target: widget.status == FocusSessionStatus.running ? 1 : 0,
                ).shimmer(
                  duration: 2.seconds,
                  color: color.withOpacity(0.3),
                ),
                
                const SizedBox(height: 8),
                
                // Status text
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Control buttons
                _buildControlButtons(color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(Color color) {
    switch (widget.status) {
      case FocusSessionStatus.idle:
        return _buildStartButton(color);
      case FocusSessionStatus.running:
        return _buildRunningButtons(color);
      case FocusSessionStatus.paused:
        return _buildPausedButtons(color);
      case FocusSessionStatus.completed:
        return _buildStartButton(color);
    }
  }

  Widget _buildStartButton(Color color) {
    return GestureDetector(
      onTap: widget.onStart,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    ).animate().scale(duration: 200.ms);
  }

  Widget _buildRunningButtons(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pause button
        GestureDetector(
          onTap: widget.onPause,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: const Icon(
              Icons.pause_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Stop button
        GestureDetector(
          onTap: widget.onStop,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.shade400, width: 2),
            ),
            child: Icon(
              Icons.stop_rounded,
              color: Colors.red.shade400,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPausedButtons(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Resume button
        GestureDetector(
          onTap: widget.onResume,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Stop button
        GestureDetector(
          onTap: widget.onStop,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.shade400, width: 2),
            ),
            child: Icon(
              Icons.stop_rounded,
              color: Colors.red.shade400,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for circular progress
class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _CircleProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

/// Session type selector chips
class SessionTypeSelector extends StatelessWidget {
  final FocusSessionType selectedType;
  final bool enabled;
  final ValueChanged<FocusSessionType> onChanged;

  const SessionTypeSelector({
    super.key,
    required this.selectedType,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: FocusSessionType.values.map((type) {
          final isSelected = type == selectedType;
          return Expanded(
            child: GestureDetector(
              onTap: enabled ? () => onChanged(type) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _getTypeColor(type)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      type.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${type.defaultDuration.inMinutes}min',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isSelected
                            ? Colors.white70
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getTypeColor(FocusSessionType type) {
    switch (type) {
      case FocusSessionType.focus:
        return const Color(0xFF7C3AED);
      case FocusSessionType.shortBreak:
        return const Color(0xFF10B981);
      case FocusSessionType.longBreak:
        return const Color(0xFF3B82F6);
    }
  }
}

/// Session counter display
class SessionCounter extends StatelessWidget {
  final int currentSession;
  final int totalSessions;

  const SessionCounter({
    super.key,
    required this.currentSession,
    required this.totalSessions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSessions, (index) {
        final isCompleted = index < currentSession - 1;
        final isCurrent = index == currentSession - 1;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 24 : 12,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isCompleted
                ? const Color(0xFF7C3AED)
                : isCurrent
                    ? const Color(0xFF7C3AED).withOpacity(0.5)
                    : (isDark ? Colors.white12 : Colors.grey.shade300),
          ),
        );
      }),
    );
  }
}
