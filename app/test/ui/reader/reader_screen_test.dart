import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/data/passage_repository.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/ui/reader/reader_screen.dart';

PassageRepository _johnOnlyRepo() => PassageRepository.fromJsonList([
      {
        'book': 'John', 'chapter': 1, 'verse_start': 1, 'verse_end': 4,
        'web_text': 'In the beginning', 'slang_text': 'Way back',
      },
    ]);

Future<void> _pump(WidgetTester tester, PassageRepository repo,
    {String? initialBook, int? initialChapter}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: Scaffold(
          body: ReaderScreen(
            repository: repo,
            initialBook: initialBook,
            initialChapter: initialChapter,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('defaults to the first available book and chapter', (tester) async {
    await _pump(tester, _johnOnlyRepo());
    expect(find.text('Way back'), findsOneWidget);
  });

  testWidgets('selecting an untranslated book shows "Not translated yet"',
      (tester) async {
    await _pump(tester, _johnOnlyRepo());

    await tester.tap(find.byKey(const Key('book-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matthew').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('not-translated-message')), findsOneWidget);
    expect(find.text('Way back'), findsNothing);
  });

  testWidgets('honors initialBook/initialChapter', (tester) async {
    await _pump(tester, _johnOnlyRepo(), initialBook: 'John', initialChapter: 1);
    expect(find.text('Way back'), findsOneWidget);
  });
}
