enum Testament { oldTestament, newTestament }

class StoryReferenceRange {
  final String book;
  final int chapterStart;
  final int verseStart;
  final int chapterEnd;
  final int verseEnd;

  const StoryReferenceRange({
    required this.book,
    required this.chapterStart,
    required this.verseStart,
    required this.chapterEnd,
    required this.verseEnd,
  });

  factory StoryReferenceRange.fromJson(Map<String, dynamic> json) {
    return StoryReferenceRange(
      book: json['book'] as String,
      chapterStart: json['chapter_start'] as int,
      verseStart: json['verse_start'] as int,
      chapterEnd: json['chapter_end'] as int,
      verseEnd: json['verse_end'] as int,
    );
  }
}

class Story {
  final int id;
  final Testament testament;
  final String title;
  final String referenceDisplay;
  final String summary;
  final List<StoryReferenceRange> references;

  const Story({
    required this.id,
    required this.testament,
    required this.title,
    required this.referenceDisplay,
    required this.summary,
    required this.references,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as int,
      testament:
          (json['testament'] as String) == 'old'
              ? Testament.oldTestament
              : Testament.newTestament,
      title: json['title'] as String,
      referenceDisplay: json['reference_display'] as String,
      summary: json['summary'] as String,
      references: (json['references'] as List<dynamic>)
          .map((e) => StoryReferenceRange.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
