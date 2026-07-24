import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/logic/streak_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer(
      {Map<String, Object> initial = const {}}) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    // Explicitly remove all streak keys to ensure a clean slate
    await prefs.remove('streak_current');
    await prefs.remove('streak_longest');
    await prefs.remove('streak_last_date');
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('streakProvider', () {
    test('starts at 0/0 with no stored streak', () async {
      final container = await makeContainer();
      final state = container.read(streakProvider);
      expect(state.current, 0);
      expect(state.longest, 0);
      expect(state.lastReadDate, isNull);
    });

    test('first-ever open sets current to 1, no milestone', () async {
      final container = await makeContainer();
      final milestone = await container
          .read(streakProvider.notifier)
          .recordAppOpen(DateTime(2026, 7, 1));

      expect(milestone, isNull);
      final state = container.read(streakProvider);
      expect(state.current, 1);
      expect(state.longest, 1);
      expect(state.lastReadDate, DateTime(2026, 7, 1));
    });

    test('opening again the same day is a no-op', () async {
      final container = await makeContainer();
      final notifier = container.read(streakProvider.notifier);
      await notifier.recordAppOpen(DateTime(2026, 7, 1));
      final milestone = await notifier.recordAppOpen(DateTime(2026, 7, 1, 22));

      expect(milestone, isNull);
      expect(container.read(streakProvider).current, 1);
    });

    test('opening the next day increments the streak', () async {
      final container = await makeContainer();
      final notifier = container.read(streakProvider.notifier);
      await notifier.recordAppOpen(DateTime(2026, 7, 1));
      await notifier.recordAppOpen(DateTime(2026, 7, 2));

      expect(container.read(streakProvider).current, 2);
      expect(container.read(streakProvider).longest, 2);
    });

    test('missing a day resets current but keeps the longest', () async {
      final container = await makeContainer();
      final notifier = container.read(streakProvider.notifier);
      await notifier.recordAppOpen(DateTime(2026, 7, 1));
      await notifier.recordAppOpen(DateTime(2026, 7, 2));
      await notifier.recordAppOpen(DateTime(2026, 7, 2));
      await notifier.recordAppOpen(DateTime(2026, 7, 5));

      final state = container.read(streakProvider);
      expect(state.current, 1);
      expect(state.longest, 2);
    });

    test('persists across container rebuilds', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container1 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      await container1
          .read(streakProvider.notifier)
          .recordAppOpen(DateTime(2026, 7, 1));
      container1.dispose();

      final container2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container2.dispose);
      expect(container2.read(streakProvider).current, 1);
    });

    for (final day in kStreakMilestones) {
      test('returns milestone $day on the day the streak reaches it', () async {
        final container = await makeContainer();
        final notifier = container.read(streakProvider.notifier);
        int? lastMilestone;
        for (var i = 0; i < day; i++) {
          lastMilestone = await notifier
              .recordAppOpen(DateTime(2026, 1, 1).add(Duration(days: i)));
        }
        expect(lastMilestone, day);
        expect(container.read(streakProvider).current, day);
      });
    }
  });
}
