import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/data/passage_repository.dart';
import 'package:slang_bible/data/story_repository.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('records a streak day on open and shows it in the AppBar',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: RootShell(
            repository: PassageRepository.fromJsonList([]),
            storyRepository: StoryRepository.fromJsonList([]),
            today: DateTime(2026, 7, 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appbar-streak-badge')), findsOneWidget);
    // Scoped to the AppBar badge specifically: RootShell's IndexedStack keeps
    // every tab (including Home, which has its own StreakBadge) mounted at
    // once, so an unscoped find.text('1') would match both.
    expect(
      find.descendant(
        of: find.byKey(const Key('appbar-streak-badge')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the milestone overlay on the 3rd consecutive day',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'streak_current': 2,
      'streak_longest': 2,
      'streak_last_date': '2026-07-01',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: RootShell(
            repository: PassageRepository.fromJsonList([]),
            storyRepository: StoryRepository.fromJsonList([]),
            today: DateTime(2026, 7, 2),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('streak-milestone-overlay')), findsOneWidget);
    expect(find.text('🔥 3-Day Streak!'), findsOneWidget);
  });
}
