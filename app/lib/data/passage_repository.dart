import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models/passage.dart';

class PassageRepository {
  final List<Passage> _passages;

  PassageRepository(this._passages);

  factory PassageRepository.fromJsonList(List<dynamic> decoded) {
    return PassageRepository(
      decoded
          .map((e) => Passage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<PassageRepository> loadFromAssets(
    List<String> assetPaths,
  ) async {
    final all = <Passage>[];
    for (final path in assetPaths) {
      final raw = await rootBundle.loadString(path);
      final decoded = json.decode(raw) as List<dynamic>;
      all.addAll(PassageRepository.fromJsonList(decoded).all);
    }
    return PassageRepository(all);
  }

  List<Passage> get all => List.unmodifiable(_passages);

  List<String> get availableBooks {
    final books = _passages.map((p) => p.book).toSet().toList();
    books.sort();
    return books;
  }

  List<int> chaptersFor(String book) {
    final chapters =
        _passages.where((p) => p.book == book).map((p) => p.chapter).toSet().toList();
    chapters.sort();
    return chapters;
  }

  List<Passage> passagesFor(String book, int chapter) {
    final result =
        _passages.where((p) => p.book == book && p.chapter == chapter).toList();
    result.sort((a, b) => a.verseStart.compareTo(b.verseStart));
    return result;
  }

  bool hasChapter(String book, int chapter) =>
      _passages.any((p) => p.book == book && p.chapter == chapter);
}
