import '../data/models/passage.dart';

/// Deterministically picks a passage for a given date, so the same date
/// always shows the same Verse of the Day without needing a server.
Passage pickVerseOfTheDay(List<Passage> passages, DateTime date) {
  if (passages.isEmpty) {
    throw ArgumentError('passages must not be empty');
  }
  final daysSinceEpoch = date.toUtc().millisecondsSinceEpoch ~/ 86400000;
  final index = daysSinceEpoch % passages.length;
  return passages[index];
}
