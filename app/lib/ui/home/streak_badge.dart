import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/streak_provider.dart';

/// Shows the current reading streak as a flame + day count. Used both on
/// [HomeScreen] (full size) and in `RootShell`'s AppBar ([compact]).
class StreakBadge extends ConsumerWidget {
  final bool compact;

  const StreakBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final style = compact
        ? Theme.of(context).textTheme.bodyMedium
        : Theme.of(context).textTheme.titleMedium;

    return Semantics(
      label: '${streak.current} day streak',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥'),
          const SizedBox(width: 4),
          Text('${streak.current}', style: style),
        ],
      ),
    );
  }
}
