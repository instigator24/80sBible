import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/data/passage_repository.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/ui/home/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repo = PassageRepository.fromJsonList([
    {
      'book': 'John', 'chapter': 1, 'verse_start': 1, 'verse_end': 4,
      'web_text': 'In the beginning', 'slang_text': 'Way back',
    },
  ]);

  Future<void> pump(
    WidgetTester tester, {
    String? Function(String, int)? onOpen,
    Map<String, Object> initialPrefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              repository: repo,
              today: DateTime.utc(2026, 7, 22),
              onOpenPassage: onOpen ?? (_, _) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the verse of the day slang text', (tester) async {
    await pump(tester);
    expect(find.text('Way back'), findsOneWidget);
  });

  testWidgets('shows the current streak badge', (tester) async {
    await pump(tester, initialPrefs: {'streak_current': 4});
    expect(find.byKey(const Key('home-streak-badge')), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('tapping the verse of the day card calls onOpenPassage', (tester) async {
    String? openedBook;
    int? openedChapter;

    await pump(
      tester,
      onOpen: (book, chapter) {
        openedBook = book;
        openedChapter = chapter;
        return null;
      },
    );

    await tester.tap(find.byKey(const Key('verse-of-the-day-card')));
    await tester.pump();

    expect(openedBook, 'John');
    expect(openedChapter, 1);
  });
}
