# Slang Bible App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Flutter app (Android + iOS) that reads the pipeline's slang-Bible JSON and lets a user browse, toggle WEB/slang, bookmark, search, and share passages, themed in 1980s preppy pastel.

**Architecture:** Layered Flutter app — a pure-Dart data layer (`Passage` model + `PassageRepository` loading bundled JSON assets), a logic layer (Riverpod providers for bookmarks; plain functions for search and verse-of-the-day), and a UI layer (four screens behind a bottom-nav shell), styled via a centralized `ThemeData`.

**Tech Stack:** Flutter 3.41 (already installed, `flutter doctor` clean), `flutter_riverpod` for state, `shared_preferences` for bookmark persistence, `share_plus` + `path_provider` for sharing.

**Note on version control:** this project isn't using git yet (explicit user preference). Steps that would normally end in `git commit` instead end in a plain verification step — do not run any `git` commands during this plan.

---

## File Structure

```
bible_slang/
  data/john.json                      # already exists (pipeline output)
  app/                                 # Flutter project (created in Task 1)
    pubspec.yaml
    assets/data/john.json              # copied from ../data/john.json (Task 2)
    lib/
      main.dart                        # app entry, RootShell wiring (Task 17)
      data/
        models/passage.dart            # Passage model (Task 3)
        bible_books.dart                # kAllBibleBooks, kBookAssetPaths (Task 4)
        passage_repository.dart         # PassageRepository (Task 5)
      logic/
        verse_of_the_day.dart           # pickVerseOfTheDay (Task 6)
        search.dart                     # searchPassages (Task 7)
        bookmarks_provider.dart         # BookmarksNotifier + providers (Task 8)
        sharer.dart                     # Sharer abstraction + SharePlusSharer (Task 9)
      ui/
        theme/
          app_theme.dart                # AppColors, buildAppTheme (Task 10)
          memphis_decorations.dart      # MemphisDotGrid (Task 11)
        reader/
          passage_card.dart             # PassageCard widget (Task 12)
          reader_screen.dart            # ReaderScreen (Task 13)
        home/
          home_screen.dart              # HomeScreen (Task 14)
        bookmarks/
          bookmarks_screen.dart         # BookmarksScreen (Task 15)
        search/
          search_screen.dart            # SearchScreen (Task 16)
    test/
      data/
        models/passage_test.dart
        passage_repository_test.dart
      logic/
        verse_of_the_day_test.dart
        search_test.dart
        bookmarks_provider_test.dart
      ui/
        theme/
          app_theme_test.dart
          memphis_decorations_test.dart
        reader/
          passage_card_test.dart
          reader_screen_test.dart
        home/
          home_screen_test.dart
        bookmarks/
          bookmarks_screen_test.dart
        search/
          search_screen_test.dart
```

---

### Task 1: Scaffold Flutter project and add dependencies

**Files:**
- Create: `app/` (entire Flutter project, generated)
- Modify: `app/pubspec.yaml`

- [ ] **Step 1: Create the Flutter project**

Run (from `/home/joel/Code/bible_slang`):
```bash
flutter create --org com.slangbible --project-name slang_bible app
```
Expected: `app/` directory created with `lib/main.dart`, `pubspec.yaml`, `android/`, `ios/`, etc.

- [ ] **Step 2: Add dependencies**

Run (from `/home/joel/Code/bible_slang/app`):
```bash
flutter pub add flutter_riverpod shared_preferences share_plus path_provider
```
Expected: `pubspec.yaml`'s `dependencies:` section now lists all four packages, and `flutter pub get` runs automatically with no errors.

- [ ] **Step 3: Verify the default counter app still builds**

Run: `cd /home/joel/Code/bible_slang/app && flutter test`
Expected: the default generated `test/widget_test.dart` passes (1 test, 0 failures). This confirms the toolchain works before any custom code is added.

- [ ] **Step 4: Verify and move on**

No commit (git isn't set up for this project yet). Confirm `app/pubspec.yaml` and `app/pubspec.lock` exist and `flutter pub get` exited 0.

---

### Task 2: Bundle pipeline data as an app asset

**Files:**
- Create: `app/assets/data/john.json` (copy of `data/john.json`)
- Modify: `app/pubspec.yaml`

- [ ] **Step 1: Copy the pipeline output into the app**

Run (from `/home/joel/Code/bible_slang`):
```bash
mkdir -p app/assets/data
cp data/john.json app/assets/data/john.json
```
Expected: `app/assets/data/john.json` exists with the same content as `data/john.json`. Note for later: re-run this `cp` command whenever the pipeline's `data/*.json` output changes — this is a manual sync step, not automated.

- [ ] **Step 2: Declare the asset folder in pubspec.yaml**

Open `app/pubspec.yaml`, find the commented-out `# assets:` section under `flutter:`, and add:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/data/
```

- [ ] **Step 3: Verify pub recognizes the asset**

Run: `cd /home/joel/Code/bible_slang/app && flutter pub get`
Expected: exits 0 with no errors (asset paths in `pubspec.yaml` are only validated at build time, but this confirms the YAML is well-formed).

- [ ] **Step 4: Verify and move on**

No commit. Confirm the file exists at `app/assets/data/john.json` via `ls app/assets/data/`.

---

### Task 3: Passage model

**Files:**
- Create: `app/lib/data/models/passage.dart`
- Test: `app/test/data/models/passage_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/data/models/passage_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/data/models/passage.dart';

void main() {
  group('Passage', () {
    test('fromJson parses all fields', () {
      final passage = Passage.fromJson({
        'book': 'John',
        'chapter': 1,
        'verse_start': 1,
        'verse_end': 4,
        'web_text': 'In the beginning...',
        'slang_text': 'Way back...',
      });

      expect(passage.book, 'John');
      expect(passage.chapter, 1);
      expect(passage.verseStart, 1);
      expect(passage.verseEnd, 4);
      expect(passage.webText, 'In the beginning...');
      expect(passage.slangText, 'Way back...');
    });

    test('reference formats a range', () {
      final passage = Passage.fromJson({
        'book': 'John',
        'chapter': 1,
        'verse_start': 1,
        'verse_end': 4,
        'web_text': 'x',
        'slang_text': 'y',
      });
      expect(passage.reference, 'John 1:1-4');
    });

    test('reference formats a single verse', () {
      final passage = Passage.fromJson({
        'book': 'John',
        'chapter': 3,
        'verse_start': 16,
        'verse_end': 16,
        'web_text': 'x',
        'slang_text': 'y',
      });
      expect(passage.reference, 'John 3:16');
    });

    test('id is stable and unique per passage', () {
      final a = Passage.fromJson({
        'book': 'John', 'chapter': 1, 'verse_start': 1, 'verse_end': 4,
        'web_text': 'x', 'slang_text': 'y',
      });
      final b = Passage.fromJson({
        'book': 'John', 'chapter': 1, 'verse_start': 5, 'verse_end': 8,
        'web_text': 'x', 'slang_text': 'y',
      });
      expect(a.id, isNot(equals(b.id)));
      expect(a.id, 'John-1-1-4');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/data/models/passage_test.dart`
Expected: FAIL — `package:slang_bible/data/models/passage.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/data/models/passage.dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/data/models/passage_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Verify and move on**

No commit.

---

### Task 4: Bible book list and known asset paths

**Files:**
- Create: `app/lib/data/bible_books.dart`

- [ ] **Step 1: Write the implementation**

No test for this task — it's a static data constant, not behavior. (Its correctness is exercised indirectly by Task 13's Reader screen tests, which rely on `kAllBibleBooks` containing 'John' and 'Genesis'.)

```dart
// app/lib/data/bible_books.dart

/// The 66 books of the Protestant canon, in canonical order, matching the
/// book names used by the WEB translation (and thus by the pipeline's
/// `book` field). Used to populate the book picker in the Reader even for
/// books that don't have translated content yet.
const List<String> kAllBibleBooks = [
  'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
  'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
  '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles', 'Ezra',
  'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs',
  'Ecclesiastes', 'Song of Solomon', 'Isaiah', 'Jeremiah', 'Lamentations',
  'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
  'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk',
  'Zephaniah', 'Haggai', 'Zechariah', 'Malachi',
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
  'assets/data/john.json',
];
```

- [ ] **Step 2: Verify and move on**

Run: `cd /home/joel/Code/bible_slang/app && flutter analyze lib/data/bible_books.dart`
Expected: "No issues found!"
No commit.

---

### Task 5: PassageRepository

**Files:**
- Create: `app/lib/data/passage_repository.dart`
- Test: `app/test/data/passage_repository_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/data/passage_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/data/models/passage.dart';
import 'package:slang_bible/data/passage_repository.dart';

void main() {
  group('PassageRepository.fromJsonList', () {
    test('parses a list of raw maps into Passages', () {
      final repo = PassageRepository.fromJsonList([
        {
          'book': 'John', 'chapter': 1, 'verse_start': 1, 'verse_end': 4,
          'web_text': 'a', 'slang_text': 'A',
        },
        {
          'book': 'John', 'chapter': 1, 'verse_start': 5, 'verse_end': 8,
          'web_text': 'b', 'slang_text': 'B',
        },
        {
          'book': 'John', 'chapter': 2, 'verse_start': 1, 'verse_end': 3,
          'web_text': 'c', 'slang_text': 'C',
        },
      ]);

      expect(repo.all.length, 3);
      expect(repo.availableBooks, ['John']);
      expect(repo.chaptersFor('John'), [1, 2]);
      expect(repo.hasChapter('John', 1), isTrue);
      expect(repo.hasChapter('John', 3), isFalse);
      expect(repo.hasChapter('Genesis', 1), isFalse);
    });

    test('passagesFor returns passages sorted by verseStart', () {
      final repo = PassageRepository.fromJsonList([
        {
          'book': 'John', 'chapter': 1, 'verse_start': 5, 'verse_end': 8,
          'web_text': 'b', 'slang_text': 'B',
        },
        {
          'book': 'John', 'chapter': 1, 'verse_start': 1, 'verse_end': 4,
          'web_text': 'a', 'slang_text': 'A',
        },
      ]);

      final passages = repo.passagesFor('John', 1);
      expect(passages.map((p) => p.verseStart).toList(), [1, 5]);
    });
  });

  group('PassageRepository.loadFromAssets', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('loads and parses the bundled john.json asset', () async {
      final repo = await PassageRepository.loadFromAssets(
        ['assets/data/john.json'],
      );
      expect(repo.all, isNotEmpty);
      expect(repo.availableBooks, ['John']);
      expect(repo.hasChapter('John', 1), isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/data/passage_repository_test.dart`
Expected: FAIL — `package:slang_bible/data/passage_repository.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/data/passage_repository.dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/data/passage_repository_test.dart`
Expected: PASS (3 tests). If the `loadFromAssets` test fails with an asset-not-found error, confirm Task 2 was completed (the asset exists and is declared in `pubspec.yaml`).

- [ ] **Step 5: Verify and move on**

No commit.

---

### Task 6: Verse-of-the-day picker

**Files:**
- Create: `app/lib/logic/verse_of_the_day.dart`
- Test: `app/test/logic/verse_of_the_day_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/logic/verse_of_the_day_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/data/models/passage.dart';
import 'package:slang_bible/logic/verse_of_the_day.dart';

Passage _p(int verseStart) => Passage(
      book: 'John',
      chapter: 1,
      verseStart: verseStart,
      verseEnd: verseStart,
      webText: 'web-$verseStart',
      slangText: 'slang-$verseStart',
    );

void main() {
  group('pickVerseOfTheDay', () {
    test('same date always returns the same passage', () {
      final passages = [_p(1), _p(2), _p(3)];
      final date = DateTime.utc(2026, 7, 22);

      final first = pickVerseOfTheDay(passages, date);
      final second = pickVerseOfTheDay(passages, date);

      expect(first.verseStart, second.verseStart);
    });

    test('consecutive days can pick different passages', () {
      final passages = [_p(1), _p(2), _p(3)];
      final day1 = pickVerseOfTheDay(passages, DateTime.utc(2026, 7, 22));
      final day2 = pickVerseOfTheDay(passages, DateTime.utc(2026, 7, 23));

      // Not a strict inequality requirement (3-item list could coincide
      // over a longer span), but with 3 distinct consecutive days the
      // index must advance by exactly 1 (mod 3).
      final passageList = passages.map((p) => p.verseStart).toList();
      final day1Index = passageList.indexOf(day1.verseStart);
      final day2Index = passageList.indexOf(day2.verseStart);
      expect(day2Index, (day1Index + 1) % passages.length);
    });

    test('throws on an empty passage list', () {
      expect(
        () => pickVerseOfTheDay(<Passage>[], DateTime.utc(2026, 7, 22)),
        throwsArgumentError,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/logic/verse_of_the_day_test.dart`
Expected: FAIL — `package:slang_bible/logic/verse_of_the_day.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/logic/verse_of_the_day.dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/logic/verse_of_the_day_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Verify and move on**

No commit.

---

### Task 7: Search logic

**Files:**
- Create: `app/lib/logic/search.dart`
- Test: `app/test/logic/search_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/logic/search_test.dart
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

    test('a keyword query matches slang or WEB text, case-insensitively', () {
      final results = searchPassages(passages, 'TOTALLY');
      expect(results.length, 1);
      expect(results.first.verseStart, 16);
    });

    test('a keyword query with no matches returns empty', () {
      expect(searchPassages(passages, 'xyzzy'), isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/logic/search_test.dart`
Expected: FAIL — `package:slang_bible/logic/search.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/logic/search.dart
import '../data/models/passage.dart';

final RegExp _referencePattern = RegExp(r'^([A-Za-z ]+?)\s+(\d+)$');

/// Interprets `query` as a "Book Chapter" reference if it matches that
/// shape (e.g. "John 3"), otherwise as a case-insensitive keyword search
/// over both the slang and WEB text.
List<Passage> searchPassages(List<Passage> passages, String query) {
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
  return passages
      .where((p) =>
          p.slangText.toLowerCase().contains(lower) ||
          p.webText.toLowerCase().contains(lower))
      .toList();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/logic/search_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Verify and move on**

No commit.

---

### Task 8: Bookmarks state (Riverpod + SharedPreferences)

**Files:**
- Create: `app/lib/logic/bookmarks_provider.dart`
- Test: `app/test/logic/bookmarks_provider_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/logic/bookmarks_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer(
      {Map<String, Object> initial = const {}}) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('bookmarksProvider', () {
    test('starts empty when no bookmarks are stored', () async {
      final container = await makeContainer();
      expect(container.read(bookmarksProvider), isEmpty);
    });

    test('starts with previously stored bookmarks', () async {
      final container = await makeContainer(initial: {
        'bookmarked_passage_ids': ['John-1-1-4'],
      });
      expect(container.read(bookmarksProvider), ['John-1-1-4']);
    });

    test('toggle adds an id and persists it', () async {
      final container = await makeContainer();
      await container.read(bookmarksProvider.notifier).toggle('John-1-1-4');

      expect(container.read(bookmarksProvider), ['John-1-1-4']);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('bookmarked_passage_ids'), ['John-1-1-4']);
    });

    test('toggle removes an id that is already bookmarked', () async {
      final container = await makeContainer(initial: {
        'bookmarked_passage_ids': ['John-1-1-4'],
      });
      await container.read(bookmarksProvider.notifier).toggle('John-1-1-4');

      expect(container.read(bookmarksProvider), isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/logic/bookmarks_provider_test.dart`
Expected: FAIL — `package:slang_bible/logic/bookmarks_provider.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/logic/bookmarks_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bookmarksKey = 'bookmarked_passage_ids';

/// Overridden in `main()` with the real `SharedPreferences.getInstance()`
/// result; left unimplemented here so tests are forced to override it
/// explicitly rather than accidentally hitting real device storage.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class BookmarksNotifier extends StateNotifier<List<String>> {
  final SharedPreferences _prefs;

  BookmarksNotifier(this._prefs)
      : super(_prefs.getStringList(_bookmarksKey) ?? <String>[]);

  Future<void> toggle(String passageId) async {
    final next = state.contains(passageId)
        ? state.where((id) => id != passageId).toList()
        : [...state, passageId];
    state = next;
    await _prefs.setStringList(_bookmarksKey, next);
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BookmarksNotifier(prefs);
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/logic/bookmarks_provider_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Verify and move on**

No commit.

---

### Task 9: Sharer abstraction

**Files:**
- Create: `app/lib/logic/sharer.dart`

- [ ] **Step 1: Write the implementation**

No test in this task — `SharePlusSharer` is a thin wrapper over a plugin that talks to the OS share sheet, which isn't meaningfully testable in a widget test. The abstraction itself (the `Sharer` interface) is what makes Task 12's `PassageCard` testable, via a fake implementation defined in that task's test file.

```dart
// app/lib/logic/sharer.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract class Sharer {
  Future<void> shareText(String text);
  Future<void> shareImage(Uint8List pngBytes, {required String filename});
}

class SharePlusSharer implements Sharer {
  @override
  Future<void> shareText(String text) async {
    await Share.share(text);
  }

  @override
  Future<void> shareImage(Uint8List pngBytes, {required String filename}) async {
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/$filename').writeAsBytes(pngBytes);
    await Share.shareXFiles([XFile(file.path)]);
  }
}

final sharerProvider = Provider<Sharer>((ref) => SharePlusSharer());
```

- [ ] **Step 2: Verify and move on**

Run: `cd /home/joel/Code/bible_slang/app && flutter analyze lib/logic/sharer.dart`
Expected: "No issues found!"
No commit.

---

### Task 10: App theme (pastel Memphis)

**Files:**
- Create: `app/lib/ui/theme/app_theme.dart`
- Test: `app/test/ui/theme/app_theme_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/ui/theme/app_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/app_theme.dart';

void main() {
  group('buildAppTheme', () {
    test('uses the pastel background and lavender primary color', () {
      final theme = buildAppTheme();
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.colorScheme.primary, AppColors.lavender);
      expect(theme.colorScheme.secondary, AppColors.mint);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('card theme has rounded corners and an ink border', () {
      final theme = buildAppTheme();
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(20));
      expect((shape.side.color), AppColors.ink);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/app_theme_test.dart`
Expected: FAIL — `package:slang_bible/ui/theme/app_theme.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/ui/theme/app_theme.dart
import 'package:flutter/material.dart';

/// 1980s "preppy pastel" palette: soft pink/mint/lavender/peach on a warm
/// cream background, with a dark ink color for text and card borders
/// (Memphis-design style — bold outlines on soft colors).
class AppColors {
  static const pink = Color(0xFFFFC2D1);
  static const mint = Color(0xFFB8F2E6);
  static const lavender = Color(0xFFD9C9F2);
  static const peach = Color(0xFFFFDAB9);
  static const ink = Color(0xFF2E2A3B);
  static const background = Color(0xFFFFF7F0);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.lavender,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.lavender,
      secondary: AppColors.mint,
      tertiary: AppColors.peach,
      surface: AppColors.background,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      bodyLarge: TextStyle(color: AppColors.ink, height: 1.4),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.ink, width: 2),
      ),
    ),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/app_theme_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Verify and move on**

No commit.

---

### Task 11: Memphis dot-grid decoration

**Files:**
- Create: `app/lib/ui/theme/memphis_decorations.dart`
- Test: `app/test/ui/theme/memphis_decorations_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/ui/theme/memphis_decorations_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/memphis_decorations.dart';

void main() {
  testWidgets('MemphisDotGrid renders without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 200,
          height: 100,
          child: MemphisDotGrid(),
        ),
      ),
    );

    expect(find.byType(MemphisDotGrid), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('MemphisDotGridPainter.shouldRepaint', () {
    test('returns true when spacing changes', () {
      const a = MemphisDotGridPainter(spacing: 16);
      const b = MemphisDotGridPainter(spacing: 24);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('returns false when nothing changes', () {
      const a = MemphisDotGridPainter();
      const b = MemphisDotGridPainter();
      expect(a.shouldRepaint(b), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/memphis_decorations_test.dart`
Expected: FAIL — `package:slang_bible/ui/theme/memphis_decorations.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/ui/theme/memphis_decorations.dart
import 'package:flutter/material.dart';

import 'app_theme.dart';

class MemphisDotGridPainter extends CustomPainter {
  final Color color;
  final double dotRadius;
  final double spacing;

  const MemphisDotGridPainter({
    this.color = AppColors.ink,
    this.dotRadius = 2,
    this.spacing = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.35);
    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MemphisDotGridPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dotRadius != dotRadius ||
      oldDelegate.spacing != spacing;
}

/// A decorative dot-grid background, used behind cards/headers to add the
/// Memphis-design texture called for in the 80s theme.
class MemphisDotGrid extends StatelessWidget {
  final double dotRadius;
  final double spacing;

  const MemphisDotGrid({super.key, this.dotRadius = 2, this.spacing = 16});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MemphisDotGridPainter(dotRadius: dotRadius, spacing: spacing),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/memphis_decorations_test.dart`
Expected: PASS (3 tests). If `color.withValues` is unavailable in the installed Flutter version, use `color.withOpacity(0.35)` instead — check the installed version's `Color` API with `flutter analyze` if this line errors.

- [ ] **Step 5: Verify and move on**

No commit.

---

### Task 12: PassageCard widget

**Files:**
- Create: `app/lib/ui/reader/passage_card.dart`
- Test: `app/test/ui/reader/passage_card_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/ui/reader/passage_card_test.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/data/models/passage.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/logic/sharer.dart';
import 'package:slang_bible/ui/reader/passage_card.dart';

class FakeSharer implements Sharer {
  String? lastText;
  Uint8List? lastImageBytes;

  @override
  Future<void> shareText(String text) async {
    lastText = text;
  }

  @override
  Future<void> shareImage(Uint8List pngBytes, {required String filename}) async {
    lastImageBytes = pngBytes;
  }
}

final _passage = Passage(
  book: 'John',
  chapter: 1,
  verseStart: 1,
  verseEnd: 4,
  webText: 'In the beginning was the Word',
  slangText: 'Way back the Word was already there',
);

Future<void> _pump(
  WidgetTester tester, {
  required FakeSharer sharer,
  Map<String, Object> initialBookmarks = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialBookmarks);
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        sharerProvider.overrideWithValue(sharer),
      ],
      child: MaterialApp(
        home: Scaffold(body: PassageCard(passage: _passage)),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows slang text by default', (tester) async {
    await _pump(tester, sharer: FakeSharer());
    expect(find.text(_passage.slangText), findsOneWidget);
    expect(find.text(_passage.webText), findsNothing);
  });

  testWidgets('toggle button switches to WEB text and back', (tester) async {
    await _pump(tester, sharer: FakeSharer());

    await tester.tap(find.byKey(const Key('toggle-web-slang')));
    await tester.pump();
    expect(find.text(_passage.webText), findsOneWidget);
    expect(find.text(_passage.slangText), findsNothing);

    await tester.tap(find.byKey(const Key('toggle-web-slang')));
    await tester.pump();
    expect(find.text(_passage.slangText), findsOneWidget);
  });

  testWidgets('bookmark button toggles bookmarked state', (tester) async {
    await _pump(tester, sharer: FakeSharer());

    expect(find.byIcon(Icons.star_border), findsOneWidget);

    await tester.tap(find.byKey(const Key('bookmark-button')));
    await tester.pump();

    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('share-text button sends reference and slang text', (tester) async {
    final sharer = FakeSharer();
    await _pump(tester, sharer: sharer);

    await tester.tap(find.byKey(const Key('share-text-button')));
    await tester.pump();

    expect(sharer.lastText, contains('John 1:1-4'));
    expect(sharer.lastText, contains(_passage.slangText));
  });

  testWidgets('share-image button sends non-empty PNG bytes', (tester) async {
    final sharer = FakeSharer();
    await tester.runAsync(() async {
      await _pump(tester, sharer: sharer);
      await tester.tap(find.byKey(const Key('share-image-button')));
      await tester.pumpAndSettle();
    });

    expect(sharer.lastImageBytes, isNotNull);
    expect(sharer.lastImageBytes!.isNotEmpty, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/reader/passage_card_test.dart`
Expected: FAIL — `package:slang_bible/ui/reader/passage_card.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/ui/reader/passage_card.dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/passage.dart';
import '../../logic/bookmarks_provider.dart';
import '../../logic/sharer.dart';

class PassageCard extends ConsumerStatefulWidget {
  final Passage passage;

  const PassageCard({super.key, required this.passage});

  @override
  ConsumerState<PassageCard> createState() => _PassageCardState();
}

class _PassageCardState extends ConsumerState<PassageCard> {
  bool _showWeb = false;
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final passage = widget.passage;
    final bookmarks = ref.watch(bookmarksProvider);
    final isBookmarked = bookmarks.contains(passage.id);

    return RepaintBoundary(
      key: _boundaryKey,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                passage.reference,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _showWeb ? passage.webText : passage.slangText,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    key: const Key('toggle-web-slang'),
                    onPressed: () => setState(() => _showWeb = !_showWeb),
                    child: Text(_showWeb ? 'Show slang' : 'Show WEB'),
                  ),
                  IconButton(
                    key: const Key('bookmark-button'),
                    icon: Icon(isBookmarked ? Icons.star : Icons.star_border),
                    onPressed: () =>
                        ref.read(bookmarksProvider.notifier).toggle(passage.id),
                  ),
                  IconButton(
                    key: const Key('share-text-button'),
                    icon: const Icon(Icons.share),
                    onPressed: () => ref.read(sharerProvider).shareText(
                          '${passage.reference}\n${passage.slangText}',
                        ),
                  ),
                  IconButton(
                    key: const Key('share-image-button'),
                    icon: const Icon(Icons.image),
                    onPressed: _shareAsImage,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareAsImage() async {
    final boundary =
        _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    await ref.read(sharerProvider).shareImage(
          bytes,
          filename: '${widget.passage.id}.png',
        );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/reader/passage_card_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Verify and move on**

No commit.

---

### Task 13: Reader screen

**Files:**
- Create: `app/lib/ui/reader/reader_screen.dart`
- Test: `app/test/ui/reader/reader_screen_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/ui/reader/reader_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/data/passage_repository.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/ui/reader/reader_screen.dart';

PassageRepository _johnOnlyRepo() => PassageRepository.fromJsonList([
      {
        'book': 'John', 'chapter': 1, 'verse_start': 1, 'verse_end': 4,
        'web_text': 'In the beginning', 'slang_text': 'Way back',
      },
    ]);

Future<void> _pump(WidgetTester tester, PassageRepository repo,
    {String? initialBook, int? initialChapter}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: Scaffold(
          body: ReaderScreen(
            repository: repo,
            initialBook: initialBook,
            initialChapter: initialChapter,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('defaults to the first available book and chapter', (tester) async {
    await _pump(tester, _johnOnlyRepo());
    expect(find.text('Way back'), findsOneWidget);
  });

  testWidgets('selecting an untranslated book shows "Not translated yet"',
      (tester) async {
    await _pump(tester, _johnOnlyRepo());

    await tester.tap(find.byKey(const Key('book-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Genesis').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('not-translated-message')), findsOneWidget);
    expect(find.text('Way back'), findsNothing);
  });

  testWidgets('honors initialBook/initialChapter', (tester) async {
    await _pump(tester, _johnOnlyRepo(), initialBook: 'John', initialChapter: 1);
    expect(find.text('Way back'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/reader/reader_screen_test.dart`
Expected: FAIL — `package:slang_bible/ui/reader/reader_screen.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/ui/reader/reader_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bible_books.dart';
import '../../data/models/passage.dart';
import '../../data/passage_repository.dart';
import 'passage_card.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final PassageRepository repository;
  final String? initialBook;
  final int? initialChapter;

  const ReaderScreen({
    super.key,
    required this.repository,
    this.initialBook,
    this.initialChapter,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late String _selectedBook;
  int? _selectedChapter;

  @override
  void initState() {
    super.initState();
    final available = widget.repository.availableBooks;
    _selectedBook = widget.initialBook ??
        (available.isNotEmpty ? available.first : kAllBibleBooks.first);
    final chapters = widget.repository.chaptersFor(_selectedBook);
    _selectedChapter =
        widget.initialChapter ?? (chapters.isNotEmpty ? chapters.first : null);
  }

  void _onBookChanged(String book) {
    setState(() {
      _selectedBook = book;
      final chapters = widget.repository.chaptersFor(book);
      _selectedChapter = chapters.isNotEmpty ? chapters.first : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chapters = widget.repository.chaptersFor(_selectedBook);
    final passages = _selectedChapter != null
        ? widget.repository.passagesFor(_selectedBook, _selectedChapter!)
        : <Passage>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              DropdownButton<String>(
                key: const Key('book-dropdown'),
                value: _selectedBook,
                items: kAllBibleBooks
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (book) {
                  if (book != null) _onBookChanged(book);
                },
              ),
              const SizedBox(width: 12),
              if (chapters.isNotEmpty)
                DropdownButton<int>(
                  key: const Key('chapter-dropdown'),
                  value: _selectedChapter,
                  items: chapters
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text('Chapter $c')))
                      .toList(),
                  onChanged: (chapter) {
                    if (chapter != null) setState(() => _selectedChapter = chapter);
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: passages.isNotEmpty
              ? ListView(
                  children:
                      passages.map((p) => PassageCard(passage: p)).toList(),
                )
              : const Center(
                  key: Key('not-translated-message'),
                  child: Text('Not translated yet'),
                ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/reader/reader_screen_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Verify and move on**

No commit.

---

### Task 14: Home screen

**Files:**
- Create: `app/lib/ui/home/home_screen.dart`
- Test: `app/test/ui/home/home_screen_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/ui/home/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/data/passage_repository.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/ui/home/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repo = PassageRepository.fromJsonList([
    {
      'book': 'John', 'chapter': 1, 'verse_start': 1, 'verse_end': 4,
      'web_text': 'In the beginning', 'slang_text': 'Way back',
    },
  ]);

  Future<void> pump(WidgetTester tester, {String? Function(String, int)? onOpen}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    String? openedBook;
    int? openedChapter;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              repository: repo,
              today: DateTime.utc(2026, 7, 22),
              onOpenPassage: (book, chapter) {
                openedBook = book;
                openedChapter = chapter;
              },
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the verse of the day slang text', (tester) async {
    await pump(tester);
    expect(find.text('Way back'), findsOneWidget);
  });

  testWidgets('tapping the verse of the day card calls onOpenPassage', (tester) async {
    String? openedBook;
    int? openedChapter;

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              repository: repo,
              today: DateTime.utc(2026, 7, 22),
              onOpenPassage: (book, chapter) {
                openedBook = book;
                openedChapter = chapter;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('verse-of-the-day-card')));
    await tester.pump();

    expect(openedBook, 'John');
    expect(openedChapter, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/home/home_screen_test.dart`
Expected: FAIL — `package:slang_bible/ui/home/home_screen.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/ui/home/home_screen.dart
import 'package:flutter/material.dart';

import '../../data/passage_repository.dart';
import '../../logic/verse_of_the_day.dart';
import '../reader/passage_card.dart';

class HomeScreen extends StatelessWidget {
  final PassageRepository repository;
  final void Function(String book, int chapter) onOpenPassage;
  final DateTime? today;

  const HomeScreen({
    super.key,
    required this.repository,
    required this.onOpenPassage,
    this.today,
  });

  @override
  Widget build(BuildContext context) {
    final all = repository.all;
    if (all.isEmpty) {
      return const Center(child: Text('No content available yet'));
    }

    final verse = pickVerseOfTheDay(all, today ?? DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verse of the Day',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            key: const Key('verse-of-the-day-card'),
            onTap: () => onOpenPassage(verse.book, verse.chapter),
            child: PassageCard(passage: verse),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/home/home_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Verify and move on**

No commit.

---

### Task 15: Bookmarks screen

**Files:**
- Create: `app/lib/ui/bookmarks/bookmarks_screen.dart`
- Test: `app/test/ui/bookmarks/bookmarks_screen_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/ui/bookmarks/bookmarks_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/data/passage_repository.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/ui/bookmarks/bookmarks_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repo = PassageRepository.fromJsonList([
    {
      'book': 'John', 'chapter': 1, 'verse_start': 1, 'verse_end': 4,
      'web_text': 'In the beginning', 'slang_text': 'Way back',
    },
    {
      'book': 'John', 'chapter': 3, 'verse_start': 16, 'verse_end': 16,
      'web_text': 'For God so loved', 'slang_text': 'God loved so hard',
    },
  ]);

  testWidgets('shows a message when there are no bookmarks', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(
            body: BookmarksScreen(repository: repo, onOpenPassage: (_, __) {}),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('no-bookmarks-message')), findsOneWidget);
  });

  testWidgets('lists bookmarked passages and opens them on tap', (tester) async {
    SharedPreferences.setMockInitialValues({
      'bookmarked_passage_ids': ['John-1-1-4'],
    });
    final prefs = await SharedPreferences.getInstance();
    String? openedBook;
    int? openedChapter;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(
            body: BookmarksScreen(
              repository: repo,
              onOpenPassage: (book, chapter) {
                openedBook = book;
                openedChapter = chapter;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Way back'), findsOneWidget);
    expect(find.text('God loved so hard'), findsNothing);

    await tester.tap(find.byKey(const Key('bookmark-John-1-1-4')));
    await tester.pump();

    expect(openedBook, 'John');
    expect(openedChapter, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/bookmarks/bookmarks_screen_test.dart`
Expected: FAIL — `package:slang_bible/ui/bookmarks/bookmarks_screen.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/ui/bookmarks/bookmarks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/passage_repository.dart';
import '../../logic/bookmarks_provider.dart';

class BookmarksScreen extends ConsumerWidget {
  final PassageRepository repository;
  final void Function(String book, int chapter) onOpenPassage;

  const BookmarksScreen({
    super.key,
    required this.repository,
    required this.onOpenPassage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkedIds = ref.watch(bookmarksProvider);
    final passages =
        repository.all.where((p) => bookmarkedIds.contains(p.id)).toList();

    if (passages.isEmpty) {
      return const Center(
        key: Key('no-bookmarks-message'),
        child: Text('No bookmarks yet'),
      );
    }

    return ListView(
      children: passages
          .map((p) => ListTile(
                key: Key('bookmark-${p.id}'),
                title: Text(p.reference),
                subtitle: Text(
                  p.slangText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => onOpenPassage(p.book, p.chapter),
              ))
          .toList(),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/bookmarks/bookmarks_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Verify and move on**

No commit.

---

### Task 16: Search screen

**Files:**
- Create: `app/lib/ui/search/search_screen.dart`
- Test: `app/test/ui/search/search_screen_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/ui/search/search_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/data/passage_repository.dart';
import 'package:slang_bible/ui/search/search_screen.dart';

void main() {
  final repo = PassageRepository.fromJsonList([
    {
      'book': 'John', 'chapter': 1, 'verse_start': 1, 'verse_end': 4,
      'web_text': 'In the beginning', 'slang_text': 'Way back',
    },
    {
      'book': 'John', 'chapter': 3, 'verse_start': 16, 'verse_end': 16,
      'web_text': 'For God so loved', 'slang_text': 'God loved so hard',
    },
  ]);

  testWidgets('shows no results before typing anything', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(repository: repo, onOpenPassage: (_, __) {}),
        ),
      ),
    );

    expect(find.byKey(const Key('no-results-message')), findsOneWidget);
  });

  testWidgets('typing a reference filters to matching passages', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(repository: repo, onOpenPassage: (_, __) {}),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('search-field')), 'John 3');
    await tester.pump();

    expect(find.text('John 3:16'), findsOneWidget);
    expect(find.text('John 1:1-4'), findsNothing);
  });

  testWidgets('tapping a result calls onOpenPassage', (tester) async {
    String? openedBook;
    int? openedChapter;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(
            repository: repo,
            onOpenPassage: (book, chapter) {
              openedBook = book;
              openedChapter = chapter;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('search-field')), 'John 3');
    await tester.pump();
    await tester.tap(find.byKey(const Key('result-John-3-16-16')));
    await tester.pump();

    expect(openedBook, 'John');
    expect(openedChapter, 3);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/search/search_screen_test.dart`
Expected: FAIL — `package:slang_bible/ui/search/search_screen.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/ui/search/search_screen.dart
import 'package:flutter/material.dart';

import '../../data/models/passage.dart';
import '../../data/passage_repository.dart';
import '../../logic/search.dart';

class SearchScreen extends StatefulWidget {
  final PassageRepository repository;
  final void Function(String book, int chapter) onOpenPassage;

  const SearchScreen({
    super.key,
    required this.repository,
    required this.onOpenPassage,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Passage> _results = <Passage>[];

  void _onChanged(String query) {
    setState(() {
      _results = searchPassages(widget.repository.all, query);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            key: const Key('search-field'),
            controller: _controller,
            onChanged: _onChanged,
            decoration:
                const InputDecoration(hintText: 'Search reference or keyword'),
          ),
        ),
        Expanded(
          child: _results.isEmpty
              ? const Center(
                  key: Key('no-results-message'),
                  child: Text('No results'),
                )
              : ListView(
                  children: _results
                      .map((p) => ListTile(
                            key: Key('result-${p.id}'),
                            title: Text(p.reference),
                            subtitle: Text(
                              p.slangText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => widget.onOpenPassage(p.book, p.chapter),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/search/search_screen_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Verify and move on**

No commit.

---

### Task 17: App shell and main.dart wiring

**Files:**
- Modify: `app/lib/main.dart` (replace the generated counter-app content entirely)

- [ ] **Step 1: Replace main.dart**

```dart
// app/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/bible_books.dart';
import 'data/passage_repository.dart';
import 'logic/bookmarks_provider.dart';
import 'ui/bookmarks/bookmarks_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/reader/reader_screen.dart';
import 'ui/search/search_screen.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final repository = await PassageRepository.loadFromAssets(kBookAssetPaths);

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: SlangBibleApp(repository: repository),
    ),
  );
}

class SlangBibleApp extends StatelessWidget {
  final PassageRepository repository;

  const SlangBibleApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slang Bible',
      theme: buildAppTheme(),
      home: RootShell(repository: repository),
    );
  }
}

class RootShell extends StatefulWidget {
  final PassageRepository repository;

  const RootShell({super.key, required this.repository});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tabIndex = 0;
  String? _pendingBook;
  int? _pendingChapter;

  void _openInReader(String book, int chapter) {
    setState(() {
      _pendingBook = book;
      _pendingChapter = chapter;
      _tabIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(repository: widget.repository, onOpenPassage: _openInReader),
      ReaderScreen(
        key: ValueKey('$_pendingBook-$_pendingChapter'),
        repository: widget.repository,
        initialBook: _pendingBook,
        initialChapter: _pendingChapter,
      ),
      BookmarksScreen(
        repository: widget.repository,
        onOpenPassage: _openInReader,
      ),
      SearchScreen(repository: widget.repository, onOpenPassage: _openInReader),
    ];

    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Reader'),
          NavigationDestination(icon: Icon(Icons.star), label: 'Bookmarks'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Remove the stale default test**

The generated `app/test/widget_test.dart` references the old counter app and will fail to compile now. Delete it:
```bash
rm /home/joel/Code/bible_slang/app/test/widget_test.dart
```

- [ ] **Step 3: Run the full test suite**

Run: `cd /home/joel/Code/bible_slang/app && flutter test`
Expected: PASS — all tests from Tasks 3-16 (should be ~30 tests total across every file), 0 failures.

- [ ] **Step 4: Analyze the whole project**

Run: `cd /home/joel/Code/bible_slang/app && flutter analyze`
Expected: "No issues found!" Fix any lints before proceeding (e.g. unused imports).

- [ ] **Step 5: Verify and move on**

No commit.

---

### Task 18: Manual verification on Android emulator

**Files:** none (manual QA pass, no code changes)

- [ ] **Step 1: Launch an emulator**

Run: `flutter emulators --launch Pixel_7a`
Wait for the emulator window to fully boot (check with `flutter devices` until "Pixel 7a" appears as a connected device, not just an available emulator).

- [ ] **Step 2: Run the app**

Run: `cd /home/joel/Code/bible_slang/app && flutter run`
Expected: app builds and launches on the Pixel 7a emulator, showing the Home tab with a Verse of the Day card styled in the pastel theme.

- [ ] **Step 3: Walk the golden path**

With the app running, manually verify each of these in order (this is the golden path from the design spec):
1. Home tab shows a Verse of the Day card with slang text visible.
2. Tap the card — it navigates to the Reader tab, showing that same passage's chapter.
3. Tap "Show WEB" on a passage — text switches to the WEB wording; tap again to switch back to slang.
4. Tap the bookmark (star) icon on a passage — icon fills in solid.
5. Switch to the Bookmarks tab — the bookmarked passage appears in the list.
6. Tap it — navigates back to the Reader at that passage.
7. Switch to the Reader tab and use the book dropdown to select "Genesis" — body shows "Not translated yet".
8. Select "John" again, pick chapter 1 — passages reappear.
9. Switch to the Search tab, type "John 1" — results show John 1 passages; tap one — navigates to the Reader at that passage.
10. Tap the share (arrow) icon on a passage — the OS share sheet opens with the reference + slang text.
11. Tap the image-share icon on a passage — the OS share sheet opens offering an image file.

- [ ] **Step 4: Record the outcome**

If every step in Step 3 behaves as described, the app is functionally complete for this plan's scope. If anything deviates, note which step failed and fix the relevant task's code before considering the plan done — do not claim completion without having actually walked through all 11 steps above.

- [ ] **Step 5: Verify and move on**

No commit. (iOS has not been verified — this environment has no Xcode/macOS available. iOS verification needs to happen on a Mac before shipping to the App Store; flag this as a known gap, not a silent skip.)

---

## Self-Review Notes

- **Spec coverage:** Reader (toggle) → Task 12-13; Home/Verse of the Day → Task 6, 14; Bookmarks → Task 8, 15; Search → Task 7, 16; Share (text + image) → Task 9, 12; 80s pastel theme → Task 10-11; offline/bundled JSON → Task 2, 5; "not translated yet" handling → Task 13; manual golden-path verification → Task 18. All spec sections have a corresponding task.
- **Type consistency:** `Passage`, `PassageRepository`, `pickVerseOfTheDay`, `searchPassages`, `BookmarksNotifier`/`bookmarksProvider`, `Sharer`/`sharerProvider`, `AppColors`/`buildAppTheme`, `MemphisDotGrid` are each defined once and referenced identically (same names, same signatures) across all later tasks that use them.
- **iOS:** this plan can only be verified on Android in the current (Linux) environment. No task claims iOS verification — Task 18 explicitly flags this as an open gap rather than skipping it silently.
