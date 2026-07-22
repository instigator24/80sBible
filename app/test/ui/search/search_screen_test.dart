import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/data/passage_repository.dart';
import 'package:slang_bible/ui/search/search_screen.dart';

void main() {
  final repo = PassageRepository.fromJsonList([
    {
      'book': 'John', 'chapter': 1, 'verse_start': 1, 'verse_end': 4,
      'web_text': 'In the beginning', 'slang_text': 'Way back',
    },
    {
      'book': 'John', 'chapter': 3, 'verse_start': 16, 'verse_end': 16,
      'web_text': 'For God so loved', 'slang_text': 'God loved so hard',
    },
  ]);

  testWidgets('shows no results before typing anything', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(repository: repo, onOpenPassage: (_, _) {}),
        ),
      ),
    );

    expect(find.byKey(const Key('no-results-message')), findsOneWidget);
  });

  testWidgets('typing a reference filters to matching passages', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(repository: repo, onOpenPassage: (_, _) {}),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('search-field')), 'John 3');
    await tester.pump();

    expect(find.text('John 3:16'), findsOneWidget);
    expect(find.text('John 1:1-4'), findsNothing);
  });

  testWidgets('defaults to 80s mode, matching slang text only', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(repository: repo, onOpenPassage: (_, _) {}),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('search-field')), 'beginning');
    await tester.pump();

    expect(find.byKey(const Key('no-results-message')), findsOneWidget);
  });

  testWidgets('switching to WEB mode searches and shows WEB text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(repository: repo, onOpenPassage: (_, _) {}),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('search-field')), 'beginning');
    await tester.pump();
    expect(find.byKey(const Key('no-results-message')), findsOneWidget);

    await tester.tap(find.text('WEB'));
    await tester.pump();

    expect(find.text('John 1:1-4'), findsOneWidget);
    expect(find.text('In the beginning'), findsOneWidget);
  });

  testWidgets('switching back to 80s mode shows slang text in results', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(repository: repo, onOpenPassage: (_, _) {}),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('search-field')), 'loved');
    await tester.pump();

    await tester.tap(find.text('WEB'));
    await tester.pump();
    expect(find.text('For God so loved'), findsOneWidget);

    await tester.tap(find.text('80s'));
    await tester.pump();
    expect(find.text('God loved so hard'), findsOneWidget);
  });

  testWidgets('tapping a result calls onOpenPassage', (tester) async {
    String? openedBook;
    int? openedChapter;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(
            repository: repo,
            onOpenPassage: (book, chapter) {
              openedBook = book;
              openedChapter = chapter;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('search-field')), 'John 3');
    await tester.pump();
    await tester.tap(find.byKey(const Key('result-John-3-16-16')));
    await tester.pump();

    expect(openedBook, 'John');
    expect(openedChapter, 3);
  });
}
