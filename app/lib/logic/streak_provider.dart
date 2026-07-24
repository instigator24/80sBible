import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bookmarks_provider.dart' show sharedPreferencesProvider;

const _currentKey = 'streak_current';
const _longestKey = 'streak_longest';
const _lastDateKey = 'streak_last_date';

const kStreakMilestones = [3, 7, 14, 30, 60, 100, 365];

class StreakState {
  final int current;
  final int longest;
  final DateTime? lastReadDate;

  const StreakState({
    required this.current,
    required this.longest,
    required this.lastReadDate,
  });
}

/// Normalizes [dt] to a UTC date with no time component.
///
/// Uses UTC to avoid DST-related date-arithmetic bugs: during DST transitions
/// (e.g., spring-forward), local-time day differences can compute as 0 or 2
/// instead of 1. This bug was found during implementation but can't be pinned
/// by a unit test, since it only reproduces on systems with DST on the exact
/// days exercised.
DateTime _dateOnly(DateTime dt) => DateTime.utc(dt.year, dt.month, dt.day);

String _formatDate(DateTime dt) {
  final d = _dateOnly(dt);
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

class StreakNotifier extends Notifier<StreakState> {
  @override
  StreakState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final rawDate = prefs.getString(_lastDateKey);
    return StreakState(
      current: prefs.getInt(_currentKey) ?? 0,
      longest: prefs.getInt(_longestKey) ?? 0,
      lastReadDate: rawDate == null ? null : DateTime.parse('${rawDate}T00:00:00Z'),
    );
  }

  /// Records that the app was opened at [now]. Returns the milestone day
  /// count if this open just reached one of [kStreakMilestones], else null.
  Future<int?> recordAppOpen(DateTime now) async {
    final today = _dateOnly(now);
    final last = state.lastReadDate;

    if (last != null && last == today) {
      return null;
    }

    // Check if today is exactly 1 day after last. Both dates are normalized to UTC,
    // so the difference is precise regardless of DST transitions.
    bool isConsecutive = false;
    if (last != null) {
      isConsecutive = today.difference(last).inDays == 1;
    }

    final nextCurrent = isConsecutive ? state.current + 1 : 1;
    final nextLongest = nextCurrent > state.longest ? nextCurrent : state.longest;

    state = StreakState(
      current: nextCurrent,
      longest: nextLongest,
      lastReadDate: today,
    );

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_currentKey, nextCurrent);
    await prefs.setInt(_longestKey, nextLongest);
    await prefs.setString(_lastDateKey, _formatDate(today));

    return kStreakMilestones.contains(nextCurrent) ? nextCurrent : null;
  }
}

final streakProvider = NotifierProvider<StreakNotifier, StreakState>(
  StreakNotifier.new,
);
