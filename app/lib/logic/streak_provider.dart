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

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

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
      lastReadDate: rawDate == null ? null : DateTime.parse(rawDate),
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

    // Check if today is exactly 1 day after last. To avoid daylight saving time
    // issues with difference().inDays, we add Duration(days: 1) to last and compare.
    bool isConsecutive = false;
    if (last != null) {
      final nextDay = DateTime(last.year, last.month, last.day).add(Duration(days: 1));
      isConsecutive = today == nextDay;
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
