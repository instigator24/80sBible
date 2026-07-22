import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/data/models/passage.dart';
import 'package:slang_bible/logic/verse_of_the_day.dart';

Passage _p(int verseStart) => Passage(
      book: 'John',
      chapter: 1,
      verseStart: verseStart,
      verseEnd: verseStart,
      webText: 'web-$verseStart',
      slangText: 'slang-$verseStart',
    );

void main() {
  group('pickVerseOfTheDay', () {
    test('same date always returns the same passage', () {
      final passages = [_p(1), _p(2), _p(3)];
      final date = DateTime.utc(2026, 7, 22);

      final first = pickVerseOfTheDay(passages, date);
      final second = pickVerseOfTheDay(passages, date);

      expect(first.verseStart, second.verseStart);
    });

    test('consecutive days can pick different passages', () {
      final passages = [_p(1), _p(2), _p(3)];
      final day1 = pickVerseOfTheDay(passages, DateTime.utc(2026, 7, 22));
      final day2 = pickVerseOfTheDay(passages, DateTime.utc(2026, 7, 23));

      final passageList = passages.map((p) => p.verseStart).toList();
      final day1Index = passageList.indexOf(day1.verseStart);
      final day2Index = passageList.indexOf(day2.verseStart);
      expect(day2Index, (day1Index + 1) % passages.length);
    });

    test('throws on an empty passage list', () {
      expect(
        () => pickVerseOfTheDay(<Passage>[], DateTime.utc(2026, 7, 22)),
        throwsArgumentError,
      );
    });
  });
}
