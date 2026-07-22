import '../data/models/passage.dart';

final RegExp _referencePattern =
    RegExp(r'^((?:[123]\s)?[A-Za-z]+(?:\s[A-Za-z]+)*)\s+(\d+)$');

/// Which text field a keyword search is scoped to. `null` (the default in
/// [searchPassages]) searches both.
enum SearchTextMode { slang, web }

/// Interprets `query` as a "Book Chapter" reference if it matches that
/// shape (e.g. "John 3"), otherwise as a case-insensitive keyword search.
/// A keyword search checks both the slang and WEB text unless [mode]
/// restricts it to just one.
List<Passage> searchPassages(
  List<Passage> passages,
  String query, {
  SearchTextMode? mode,
}) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return <Passage>[];

  final refMatch = _referencePattern.firstMatch(trimmed);
  if (refMatch != null) {
    final book = refMatch.group(1)!.trim();
    final chapter = int.parse(refMatch.group(2)!);
    final results = passages
        .where((p) =>
            p.book.toLowerCase() == book.toLowerCase() && p.chapter == chapter)
        .toList();
    results.sort((a, b) => a.verseStart.compareTo(b.verseStart));
    return results;
  }

  final lower = trimmed.toLowerCase();
  return passages.where((p) {
    switch (mode) {
      case SearchTextMode.slang:
        return p.slangText.toLowerCase().contains(lower);
      case SearchTextMode.web:
        return p.webText.toLowerCase().contains(lower);
      case null:
        return p.slangText.toLowerCase().contains(lower) ||
            p.webText.toLowerCase().contains(lower);
    }
  }).toList();
}
