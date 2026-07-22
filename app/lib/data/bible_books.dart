/// The 27 books of the New Testament, in canonical order, matching the
/// book names used by the WEB translation (and thus by the pipeline's
/// `book` field). Used to populate the book picker in the Reader even for
/// books that don't have translated content yet.
///
/// Old Testament books are omitted for now — the app is releasing with the
/// New Testament only. Re-add the Old Testament book list ahead of this one
/// when that content is ready.
const List<String> kAllBibleBooks = [
  'Matthew', 'Mark', 'Luke', 'John', 'Acts',
  'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians',
  'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
  '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews',
  'James', '1 Peter', '2 Peter', '1 John', '2 John', '3 John',
  'Jude', 'Revelation',
];

/// Asset paths for translated books. Add an entry here whenever a new
/// book's JSON is copied into `assets/data/` (see Task 2's copy step).
const List<String> kBookAssetPaths = [
  'assets/data/matthew.json',
  'assets/data/mark.json',
  'assets/data/luke.json',
  'assets/data/john.json',
  'assets/data/acts.json',
  'assets/data/romans.json',
  'assets/data/1corinthians.json',
  'assets/data/2corinthians.json',
  'assets/data/galatians.json',
  'assets/data/ephesians.json',
  'assets/data/philippians.json',
  'assets/data/colossians.json',
];
