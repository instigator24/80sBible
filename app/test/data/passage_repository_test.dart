import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/data/passage_repository.dart';

void main() {
  group('PassageRepository.fromJsonList', () {
    test('parses a list of raw maps into Passages', () {
      final repo = PassageRepository.fromJsonList([
        {
          'book': 'John', 'chapter': 1, 'verse_start': 1, 'verse_end': 4,
          'web_text': 'a', 'slang_text': 'A',
        },
        {
          'book': 'John', 'chapter': 1, 'verse_start': 5, 'verse_end': 8,
          'web_text': 'b', 'slang_text': 'B',
        },
        {
          'book': 'John', 'chapter': 2, 'verse_start': 1, 'verse_end': 3,
          'web_text': 'c', 'slang_text': 'C',
        },
      ]);

      expect(repo.all.length, 3);
      expect(repo.availableBooks, ['John']);
      expect(repo.chaptersFor('John'), [1, 2]);
      expect(repo.hasChapter('John', 1), isTrue);
      expect(repo.hasChapter('John', 3), isFalse);
      expect(repo.hasChapter('Genesis', 1), isFalse);
    });

    test('passagesFor returns passages sorted by verseStart', () {
      final repo = PassageRepository.fromJsonList([
        {
          'book': 'John', 'chapter': 1, 'verse_start': 5, 'verse_end': 8,
          'web_text': 'b', 'slang_text': 'B',
        },
        {
          'book': 'John', 'chapter': 1, 'verse_start': 1, 'verse_end': 4,
          'web_text': 'a', 'slang_text': 'A',
        },
      ]);

      final passages = repo.passagesFor('John', 1);
      expect(passages.map((p) => p.verseStart).toList(), [1, 5]);
    });
  });

  group('PassageRepository.loadFromAssets', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('loads and parses the bundled john.json asset', () async {
      final repo = await PassageRepository.loadFromAssets(
        ['assets/data/john.json'],
      );
      expect(repo.all, isNotEmpty);
      expect(repo.availableBooks, ['John']);
      expect(repo.hasChapter('John', 1), isTrue);
    });
  });
}
