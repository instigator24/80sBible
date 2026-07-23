import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models/story.dart';

const kStoriesAssetPath = 'assets/data/stories.json';

class StoryRepository {
  final List<Story> _stories;

  StoryRepository(this._stories);

  factory StoryRepository.fromJsonList(List<dynamic> decoded) {
    final stories = decoded
        .map((e) => Story.fromJson(e as Map<String, dynamic>))
        .toList();
    stories.sort((a, b) => a.id.compareTo(b.id));
    return StoryRepository(stories);
  }

  static Future<StoryRepository> loadFromAssets(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw) as List<dynamic>;
    return StoryRepository.fromJsonList(decoded);
  }

  List<Story> get all => List.unmodifiable(_stories);

  List<Story> forTestament(Testament testament) =>
      _stories.where((s) => s.testament == testament).toList();
}
