class Passage {
  final String book;
  final int chapter;
  final int verseStart;
  final int verseEnd;
  final String webText;
  final String slangText;

  const Passage({
    required this.book,
    required this.chapter,
    required this.verseStart,
    required this.verseEnd,
    required this.webText,
    required this.slangText,
  });

  factory Passage.fromJson(Map<String, dynamic> json) {
    return Passage(
      book: json['book'] as String,
      chapter: json['chapter'] as int,
      verseStart: json['verse_start'] as int,
      verseEnd: json['verse_end'] as int,
      webText: json['web_text'] as String,
      slangText: json['slang_text'] as String,
    );
  }

  String get reference => verseStart == verseEnd
      ? '$book $chapter:$verseStart'
      : '$book $chapter:$verseStart-$verseEnd';

  String get id => '$book-$chapter-$verseStart-$verseEnd';
}
