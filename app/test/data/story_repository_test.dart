import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/data/models/story.dart';
import 'package:slang_bible/data/story_repository.dart';

List<Map<String, dynamic>> _fixture() => [
      {
        'id': 2,
        'testament': 'old',
        'title': 'The Fall of Man',
        'reference_display': 'Genesis 3:1–24',
        'summary': 'summary 2',
        'references': [
          {
            'book': 'Genesis', 'chapter_start': 3, 'verse_start': 1,
            'chapter_end': 3, 'verse_end': 24,
          },
        ],
      },
      {
        'id': 1,
        'testament': 'old',
        'title': 'The Creation',
        'reference_display': 'Genesis 1:1 – 2:25',
        'summary': 'summary 1',
        'references': [
          {
            'book': 'Genesis', 'chapter_start': 1, 'verse_start': 1,
            'chapter_end': 2, 'verse_end': 25,
          },
        ],
      },
      {
        'id': 33,
        'testament': 'new',
        'title': 'The Birth of Jesus',
        'reference_display': 'Luke 2:1–20',
        'summary': 'summary 33',
        'references': [
          {
            'book': 'Luke', 'chapter_start': 2, 'verse_start': 1,
            'chapter_end': 2, 'verse_end': 20,
          },
        ],
      },
    ];

void main() {
  group('StoryRepository.fromJsonList', () {
    test('sorts stories by id regardless of input order', () {
      final repo = StoryRepository.fromJsonList(_fixture());
      expect(repo.all.map((s) => s.id).toList(), [1, 2, 33]);
    });

    test('forTestament filters to just that testament, preserving id order', () {
      final repo = StoryRepository.fromJsonList(_fixture());
      expect(
        repo.forTestament(Testament.oldTestament).map((s) => s.id).toList(),
        [1, 2],
      );
      expect(
        repo.forTestament(Testament.newTestament).map((s) => s.id).toList(),
        [33],
      );
    });
  });

  group('StoryRepository.loadFromAssets', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('loads and parses the bundled stories.json asset', () async {
      final repo = await StoryRepository.loadFromAssets(kStoriesAssetPath);
      expect(repo.all.length, 50);
      expect(repo.all.first.id, 1);
      expect(repo.all.last.id, 50);
    });
  });
}
