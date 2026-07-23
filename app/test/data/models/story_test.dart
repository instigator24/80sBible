import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/data/models/story.dart';

void main() {
  group('Story.fromJson', () {
    test('parses a single-reference story', () {
      final story = Story.fromJson({
        'id': 1,
        'testament': 'old',
        'title': 'The Creation',
        'reference_display': 'Genesis 1:1 – 2:25',
        'summary': 'God speaks the universe into existence.',
        'references': [
          {
            'book': 'Genesis',
            'chapter_start': 1,
            'verse_start': 1,
            'chapter_end': 2,
            'verse_end': 25,
          },
        ],
      });

      expect(story.id, 1);
      expect(story.testament, Testament.oldTestament);
      expect(story.title, 'The Creation');
      expect(story.referenceDisplay, 'Genesis 1:1 – 2:25');
      expect(story.summary, 'God speaks the universe into existence.');
      expect(story.references.length, 1);
      expect(story.references.first.book, 'Genesis');
      expect(story.references.first.chapterStart, 1);
      expect(story.references.first.verseStart, 1);
      expect(story.references.first.chapterEnd, 2);
      expect(story.references.first.verseEnd, 25);
    });

    test('parses a multi-reference (compound) story', () {
      final story = Story.fromJson({
        'id': 33,
        'testament': 'new',
        'title': 'The Birth of Jesus',
        'reference_display': 'Luke 2:1–20; Matthew 1:18 – 2:12',
        'summary': 'Jesus is born to the virgin Mary.',
        'references': [
          {
            'book': 'Luke',
            'chapter_start': 2,
            'verse_start': 1,
            'chapter_end': 2,
            'verse_end': 20,
          },
          {
            'book': 'Matthew',
            'chapter_start': 1,
            'verse_start': 18,
            'chapter_end': 2,
            'verse_end': 12,
          },
        ],
      });

      expect(story.testament, Testament.newTestament);
      expect(story.references.length, 2);
      expect(story.references[0].book, 'Luke');
      expect(story.references[1].book, 'Matthew');
    });
  });
}
