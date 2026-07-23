import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/data/models/story.dart';
import 'package:slang_bible/data/passage_repository.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/ui/reader/passage_card.dart';
import 'package:slang_bible/ui/stories/story_detail_screen.dart';

Story _story({required List<StoryReferenceRange> references}) => Story(
      id: 33,
      testament: Testament.newTestament,
      title: 'The Birth of Jesus',
      referenceDisplay: 'Luke 2:1-20; Matthew 1:18-2:12',
      summary: 'Jesus is born to the virgin Mary in a humble manger.',
      references: references,
    );

Future<void> _pump(
  WidgetTester tester, {
  required Story story,
  required PassageRepository repository,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: StoryDetailScreen(story: story, passageRepository: repository),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Summary tab shows the story summary text', (tester) async {
    final story = _story(references: [
      const StoryReferenceRange(
        book: 'Luke', chapterStart: 2, verseStart: 1, chapterEnd: 2, verseEnd: 20,
      ),
    ]);

    await _pump(tester, story: story, repository: PassageRepository.fromJsonList([]));

    expect(
      find.text('Jesus is born to the virgin Mary in a humble manger.'),
      findsOneWidget,
    );
  });

  testWidgets('Verses tab shows a PassageCard for a covered reference', (tester) async {
    final story = _story(references: [
      const StoryReferenceRange(
        book: 'Luke', chapterStart: 2, verseStart: 1, chapterEnd: 2, verseEnd: 20,
      ),
    ]);
    final repo = PassageRepository.fromJsonList([
      {
        'book': 'Luke', 'chapter': 2, 'verse_start': 1, 'verse_end': 20,
        'web_text': 'web text', 'slang_text': 'slang text',
      },
    ]);

    await _pump(tester, story: story, repository: repo);
    await tester.tap(find.text('Verses'));
    await tester.pumpAndSettle();

    expect(find.text('slang text'), findsOneWidget);
    expect(find.text('Not translated yet'), findsNothing);
  });

  testWidgets('Verses tab shows "Not translated yet" for an uncovered reference',
      (tester) async {
    final story = _story(references: [
      const StoryReferenceRange(
        book: 'Genesis', chapterStart: 1, verseStart: 1, chapterEnd: 2, verseEnd: 25,
      ),
    ]);

    await _pump(tester, story: story, repository: PassageRepository.fromJsonList([]));
    await tester.tap(find.text('Verses'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('not-translated-message-0')),
      findsOneWidget,
    );
  });

  testWidgets(
      'Verses tab shows partial coverage for a compound reference '
      '(one covered range, one not)', (tester) async {
    final story = _story(references: [
      const StoryReferenceRange(
        book: 'Luke', chapterStart: 2, verseStart: 1, chapterEnd: 2, verseEnd: 20,
      ),
      const StoryReferenceRange(
        book: 'Matthew', chapterStart: 1, verseStart: 18, chapterEnd: 2, verseEnd: 12,
      ),
    ]);
    final repo = PassageRepository.fromJsonList([
      {
        'book': 'Luke', 'chapter': 2, 'verse_start': 1, 'verse_end': 20,
        'web_text': 'web text', 'slang_text': 'slang text',
      },
    ]);

    await _pump(tester, story: story, repository: repo);
    await tester.tap(find.text('Verses'));
    await tester.pumpAndSettle();

    expect(find.text('slang text'), findsOneWidget);
    expect(
      find.byKey(const Key('not-translated-message-1')),
      findsOneWidget,
    );
  });

  testWidgets(
      'Verses tab shows both PassageCards for two covered ranges',
      (tester) async {
    final story = _story(references: [
      const StoryReferenceRange(
        book: 'Luke', chapterStart: 2, verseStart: 1, chapterEnd: 2, verseEnd: 20,
      ),
      const StoryReferenceRange(
        book: 'Matthew', chapterStart: 1, verseStart: 18, chapterEnd: 2, verseEnd: 12,
      ),
    ]);
    final repo = PassageRepository.fromJsonList([
      {
        'book': 'Luke', 'chapter': 2, 'verse_start': 1, 'verse_end': 20,
        'web_text': 'web text luke', 'slang_text': 'slang text luke',
      },
      {
        'book': 'Matthew', 'chapter': 1, 'verse_start': 18, 'verse_end': 25,
        'web_text': 'web text matthew', 'slang_text': 'slang text matthew',
      },
    ]);

    await _pump(tester, story: story, repository: repo);
    await tester.tap(find.text('Verses'));
    await tester.pumpAndSettle();

    expect(find.text('slang text luke'), findsOneWidget);
    expect(find.text('slang text matthew'), findsOneWidget);
  });

  testWidgets('Verses tab renders nothing for an empty references list',
      (tester) async {
    final story = _story(references: const []);

    await _pump(tester, story: story, repository: PassageRepository.fromJsonList([]));
    await tester.tap(find.text('Verses'));
    await tester.pumpAndSettle();

    expect(find.byType(PassageCard), findsNothing);
    expect(find.text('Not translated yet'), findsNothing);
  });

  testWidgets('Verses tab gives each uncovered range a distinct placeholder key',
      (tester) async {
    final story = _story(references: [
      const StoryReferenceRange(
        book: 'Luke', chapterStart: 1, verseStart: 5, chapterEnd: 1, verseEnd: 25,
      ),
      const StoryReferenceRange(
        book: 'Luke', chapterStart: 1, verseStart: 26, chapterEnd: 1, verseEnd: 38,
      ),
    ]);

    await _pump(tester, story: story, repository: PassageRepository.fromJsonList([]));
    await tester.tap(find.text('Verses'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('not-translated-message-0')), findsOneWidget);
    expect(find.byKey(const Key('not-translated-message-1')), findsOneWidget);
  });

  testWidgets('Switching tabs Verses -> Summary -> Verses does not crash',
      (tester) async {
    final story = _story(references: [
      const StoryReferenceRange(
        book: 'Luke', chapterStart: 2, verseStart: 1, chapterEnd: 2, verseEnd: 20,
      ),
    ]);
    final repo = PassageRepository.fromJsonList([
      {
        'book': 'Luke', 'chapter': 2, 'verse_start': 1, 'verse_end': 20,
        'web_text': 'web text', 'slang_text': 'slang text',
      },
    ]);

    await _pump(tester, story: story, repository: repo);

    await tester.tap(find.text('Verses'));
    await tester.pumpAndSettle();
    expect(find.text('slang text'), findsOneWidget);

    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle();
    expect(
      find.text('Jesus is born to the virgin Mary in a humble manger.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Verses'));
    await tester.pumpAndSettle();
    expect(find.text('slang text'), findsOneWidget);
  });
}
