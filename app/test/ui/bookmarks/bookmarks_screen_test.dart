import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/data/passage_repository.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/ui/bookmarks/bookmarks_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('shows a message when there are no bookmarks', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(
            body: BookmarksScreen(repository: repo, onOpenPassage: (_, _) {}),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('no-bookmarks-message')), findsOneWidget);
  });

  testWidgets('lists bookmarked passages and opens them on tap', (tester) async {
    SharedPreferences.setMockInitialValues({
      'bookmarked_passage_ids': ['John-1-1-4'],
    });
    final prefs = await SharedPreferences.getInstance();
    String? openedBook;
    int? openedChapter;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(
            body: BookmarksScreen(
              repository: repo,
              onOpenPassage: (book, chapter) {
                openedBook = book;
                openedChapter = chapter;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Way back'), findsOneWidget);
    expect(find.text('God loved so hard'), findsNothing);

    await tester.tap(find.byKey(const Key('bookmark-John-1-1-4')));
    await tester.pump();

    expect(openedBook, 'John');
    expect(openedChapter, 1);
  });
}
