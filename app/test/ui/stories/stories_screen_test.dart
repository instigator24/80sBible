import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/data/passage_repository.dart';
import 'package:slang_bible/data/story_repository.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/ui/stories/stories_screen.dart';

StoryRepository _repo() => StoryRepository.fromJsonList([
      {
        'id': 1, 'testament': 'old', 'title': 'The Creation',
        'reference_display': 'Genesis 1:1 – 2:25', 'summary': 'summary 1',
        'references': [
          {
            'book': 'Genesis', 'chapter_start': 1, 'verse_start': 1,
            'chapter_end': 2, 'verse_end': 25,
          },
        ],
      },
      {
        'id': 33, 'testament': 'new', 'title': 'The Birth of Jesus',
        'reference_display': 'Luke 2:1–20', 'summary': 'summary 33',
        'references': [
          {
            'book': 'Luke', 'chapter_start': 2, 'verse_start': 1,
            'chapter_end': 2, 'verse_end': 20,
          },
        ],
      },
    ]);

Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: Scaffold(
          body: StoriesScreen(
            storyRepository: _repo(),
            passageRepository: PassageRepository.fromJsonList([]),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('defaults to showing New Testament stories', (tester) async {
    await _pump(tester);
    expect(find.text('The Birth of Jesus'), findsOneWidget);
    expect(find.text('The Creation'), findsNothing);
    expect(find.byKey(const Key('old-testament-coming-soon')), findsNothing);
  });

  testWidgets('toggling to Old Testament shows a "Coming soon" placeholder instead of a list',
      (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Old Testament'));
    await tester.pump();

    expect(find.byKey(const Key('old-testament-coming-soon')), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.text('The Creation'), findsNothing);
    expect(find.text('The Birth of Jesus'), findsNothing);
  });

  testWidgets('tapping a story pushes to StoryDetailScreen', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('The Birth of Jesus'));
    await tester.pumpAndSettle();

    expect(find.text('Luke 2:1–20'), findsOneWidget);

    await tester.tap(find.text('Verses'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('not-translated-message-0')), findsOneWidget);
  });
}
