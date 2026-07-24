import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// Shows a full-screen celebration overlay for a streak milestone. Auto-
/// dismisses after 3 seconds, or immediately on tap.
Future<void> showStreakMilestoneOverlay(BuildContext context, int days) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Streak milestone',
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (context, _, _) => StreakMilestoneOverlay(days: days),
  );
}

class StreakMilestoneOverlay extends StatefulWidget {
  final int days;

  const StreakMilestoneOverlay({super.key, required this.days});

  @override
  State<StreakMilestoneOverlay> createState() =>
      _StreakMilestoneOverlayState();
}

class _StreakMilestoneOverlayState extends State<StreakMilestoneOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildParticle(ThemeData theme, int index) {
    const particleCount = 8;
    final angle = (pi * 2 / particleCount) * index;
    final distance = 80.0 * _controller.value;
    return Transform.translate(
      offset: Offset(cos(angle) * distance, sin(angle) * distance),
      child: Opacity(
        opacity: 1 - _controller.value,
        child: Icon(Icons.star, color: theme.colorScheme.primary, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      key: const Key('streak-milestone-overlay'),
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Material(
        color: theme.colorScheme.scrim.withValues(alpha: 0.85),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Stack(
              alignment: Alignment.center,
              children: [
                for (var i = 0; i < 8; i++) _buildParticle(theme, i),
                Opacity(
                  opacity: _controller.value,
                  child: Text(
                    '🔥 ${widget.days}-Day Streak!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
