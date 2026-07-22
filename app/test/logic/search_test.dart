import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/data/models/passage.dart';
import 'package:slang_bible/logic/search.dart';

void main() {
  final passages = [
    Passage(
      book: 'John', chapter: 1, verseStart: 1, verseEnd: 4,
      webText: 'In the beginning was the Word',
      slangText: 'Way back the Word was already there',
    ),
    Passage(
      book: 'John', chapter: 3, verseStart: 16, verseEnd: 16,
      webText: 'For God so loved the world',
      slangText: 'God loved the world so hard, totally',
    ),
    Passage(
      book: '1 Samuel', chapter: 1, verseStart: 1, verseEnd: 2,
      webText: 'There was a certain man of Ramathaim-zophim',
      slangText: 'There was this dude from Ramathaim',
    ),
  ];

  group('searchPassages', () {
    test('empty query returns no results', () {
      expect(searchPassages(passages, ''), isEmpty);
      expect(searchPassages(passages, '   '), isEmpty);
    });

    test('a "Book Chapter" query matches by reference, case-insensitively', () {
      final results = searchPassages(passages, 'john 1');
      expect(results.length, 1);
      expect(results.first.chapter, 1);
    });

    test('a "Book Chapter" query matches a numbered book by reference', () {
      final results = searchPassages(passages, '1 Samuel 1');
      expect(results.length, 1);
      expect(results.first.book, '1 Samuel');
      expect(results.first.chapter, 1);
    });

    test('a keyword query matches slang or WEB text, case-insensitively', () {
      final results = searchPassages(passages, 'TOTALLY');
      expect(results.length, 1);
      expect(results.first.verseStart, 16);
    });

    test('a keyword query with no matches returns empty', () {
      expect(searchPassages(passages, 'xyzzy'), isEmpty);
    });

    test('mode: slang restricts matches to slang text only', () {
      expect(
        searchPassages(passages, 'beginning', mode: SearchTextMode.slang),
        isEmpty,
      );
      expect(
        searchPassages(passages, 'totally', mode: SearchTextMode.slang).length,
        1,
      );
    });

    test('mode: web restricts matches to WEB text only', () {
      expect(
        searchPassages(passages, 'totally', mode: SearchTextMode.web),
        isEmpty,
      );
      expect(
        searchPassages(passages, 'beginning', mode: SearchTextMode.web).length,
        1,
      );
    });
  });
}
