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
  final String? slangNarrative;
  final List<StoryReferenceRange> references;

  const Story({
    required this.id,
    required this.testament,
    required this.title,
    required this.referenceDisplay,
    required this.summary,
    this.slangNarrative,
    required this.references,
  });

  /// The longer 80s-slang narrative retelling, falling back to the short
  /// [summary] for stories that don't have one drafted yet.
  String get displayText => slangNarrative ?? summary;

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as int,
      testament: switch (json['testament'] as String) {
        'old' => Testament.oldTestament,
        'new' => Testament.newTestament,
        final other => throw ArgumentError('Unknown testament: $other'),
      },
      title: json['title'] as String,
      referenceDisplay: json['reference_display'] as String,
      summary: json['summary'] as String,
      slangNarrative: json['slang_narrative'] as String?,
      references: (json['references'] as List<dynamic>)
          .map((e) => StoryReferenceRange.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
