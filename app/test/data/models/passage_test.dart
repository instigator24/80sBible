import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/data/models/passage.dart';

void main() {
  group('Passage', () {
    test('fromJson parses all fields', () {
      final passage = Passage.fromJson({
        'book': 'John',
        'chapter': 1,
        'verse_start': 1,
        'verse_end': 4,
        'web_text': 'In the beginning...',
        'slang_text': 'Way back...',
      });

      expect(passage.book, 'John');
      expect(passage.chapter, 1);
      expect(passage.verseStart, 1);
      expect(passage.verseEnd, 4);
      expect(passage.webText, 'In the beginning...');
      expect(passage.slangText, 'Way back...');
    });

    test('reference formats a range', () {
      final passage = Passage.fromJson({
        'book': 'John',
        'chapter': 1,
        'verse_start': 1,
        'verse_end': 4,
        'web_text': 'x',
        'slang_text': 'y',
      });
      expect(passage.reference, 'John 1:1-4');
    });

    test('reference formats a single verse', () {
      final passage = Passage.fromJson({
        'book': 'John',
        'chapter': 3,
        'verse_start': 16,
        'verse_end': 16,
        'web_text': 'x',
        'slang_text': 'y',
      });
      expect(passage.reference, 'John 3:16');
    });

    test('id is stable and unique per passage', () {
      final a = Passage.fromJson({
        'book': 'John', 'chapter': 1, 'verse_start': 1, 'verse_end': 4,
        'web_text': 'x', 'slang_text': 'y',
      });
      final b = Passage.fromJson({
        'book': 'John', 'chapter': 1, 'verse_start': 5, 'verse_end': 8,
        'web_text': 'x', 'slang_text': 'y',
      });
      expect(a.id, isNot(equals(b.id)));
      expect(a.id, 'John-1-1-4');
    });
  });
}
