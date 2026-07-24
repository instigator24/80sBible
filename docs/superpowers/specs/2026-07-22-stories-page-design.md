# Stories Page

## Problem

The app currently has no way to browse the Bible by narrative — only by
book/chapter (Reader), bookmarks, or keyword search. `top_50_bible_stories.md`
already contains a chronologically-ordered, hand-curated list of the 50 most
famous Bible stories (32 Old Testament, 18 New Testament), each with a title,
scripture reference, and 2-sentence summary. We want a "Stories" page that
lets a user browse this list by testament and drill into a story to read
either its summary or its actual verses (in the app's existing slang/WEB
toggle style).

## Scope

- A new 6th bottom-nav tab, "Stories", alongside Home/Reader/Bookmarks/
  Search/Settings.
- A build-time script that turns `top_50_bible_stories.md` into a JSON data
  asset, following the existing `fetch.py`/`compile.py` convention of
  source-of-truth files under `data/` copied into `app/assets/data/`.
- A list screen (OT/NT selector + chronological list) and a detail screen
  (Summary tab + Verses tab) for an individual story.
- Reuse of the existing `PassageRepository`/`PassageCard` for rendering
  verses — no new verse-rendering logic, no new theme-specific styling.
- Does not include drafting any new slang content. Old Testament stories
  (and NT chapters not yet drafted) will show a "Not translated yet"
  placeholder in their Verses tab until that content exists, exactly as the
  Reader screen already does for untranslated books.

## Data pipeline

A new script, `generate_stories.py` (sibling to `fetch.py`/`compile.py` at
the repo root), parses `top_50_bible_stories.md` and writes
`data/stories.json`, which then gets copied to `app/assets/data/stories.json`
(matching how compiled book JSON files are copied today). No `pubspec.yaml`
change is needed since `assets/data/` is already declared as a whole-directory
asset glob.

Each story record in the JSON array:

```json
{
  "id": 1,
  "testament": "old",
  "title": "The Creation",
  "reference_display": "Genesis 1:1 – 2:25",
  "references": [
    {"book": "Genesis", "chapter_start": 1, "verse_start": 1, "chapter_end": 2, "verse_end": 25}
  ],
  "summary": "God speaks the universe into existence over six days, forming light, land, and life. He crowns creation by forming Adam and Eve in His image to care for the Garden of Eden."
}
```

- `id` is the story's position (1-50) in the source file, which is already
  in chronological order — the OT/NT list views just filter by `testament`
  and sort by `id`, no separate ordering field needed.
- `testament` is `"old"` for entries under the file's "## The Old Testament"
  heading, `"new"` for "## The New Testament".
- `references` is a list because some stories cite multiple ranges,
  separated by `;` in the source (e.g. "Luke 2:1-20; Matthew 1:18 – 2:12",
  or same-book shorthand like "Genesis 25:19–34; 27:1–45" and "Job 1:1 –
  2:13; 42:1–17", where a later segment omits the book name and inherits
  the previous segment's book). The parser must handle:
  - single verse endpoints: `Book C:V`
  - same-chapter verse ranges: `Book C:V–V` (hyphen or en dash)
  - cross-chapter ranges: `Book C:V – C:V`
  - multiple `;`-separated segments per story, with book-name inheritance
    when a segment starts with a bare `C:V...` (no book name)
  - numbered book names (`1 Samuel`, `2 Kings`, etc.)
- `summary` is the single summary line/paragraph under each story's
  title line in the source.

This script is run manually (like `fetch.py`/`compile.py` today) whenever
`top_50_bible_stories.md` changes; it is not invoked by the Flutter app or
its test suite.

## App structure

**`lib/data/models/story.dart`** — `Story` (id, testament, title,
referenceDisplay, summary, references) and `StoryReferenceRange` (book,
chapterStart, verseStart, chapterEnd, verseEnd) data classes with
`fromJson` factories, following the existing `Passage` model's style.

**`lib/data/story_repository.dart`** — `StoryRepository.loadFromAssets()`
loads and parses `assets/data/stories.json` (mirroring
`PassageRepository.loadFromAssets`). Exposes `all` (all 50, in `id` order)
and a helper to filter by testament.

**`lib/ui/stories/stories_screen.dart`** — the new 6th tab.
- A `SegmentedButton` for Old/New Testament selection, styled like the
  Search screen's existing 80s/WEB toggle.
- A `ListView` of the filtered stories in `id` order, each item showing
  title + `referenceDisplay`.
- Tapping a story does `Navigator.push(MaterialPageRoute(...))` to
  `StoryDetailScreen`. This is the app's first use of stack-based
  navigation — until now, all 5 tabs just swap an `IndexedStack` index in
  `RootShell`. It's scoped to this one feature; the existing tabs are
  unaffected.

**`lib/ui/stories/story_detail_screen.dart`** — takes a `Story` and the
`PassageRepository`. `Scaffold` with an `AppBar` (title = story title) and
a `TabBar`/`TabBarView` with two tabs:
- **Summary** — the story's summary text in a simple padded `Text`.
- **Verses** — for each `StoryReferenceRange` in the story, filter
  `PassageRepository.all` for passages whose `book` matches and whose
  `chapter` falls within `[chapterStart, chapterEnd]` (chapter-level
  granularity — matching how the Reader screen already renders whole
  chapters as a sequence of passage chunks, not exact-verse cropping).
  Render each matching passage as an ordinary `PassageCard`, in order.
  If a given range has zero matches, render a "Not translated yet"
  placeholder in its place (same message/precedent as the Reader screen's
  untranslated-book case) instead of skipping it silently — so a
  compound-reference story can show some translated ranges and some
  "not yet" placeholders side by side.

Because `PassageCard` is reused as-is, the WEB/slang toggle (slang shown
by default), bookmarking, sharing, and per-theme styling (including the
Retro Arcade cabinet look) all work automatically with no new code.

**`main.dart`** — add `StoriesScreen` as a 6th entry in `RootShell`'s
`screens` list and a 6th `NavigationDestination`. No changes to the
existing `_pendingBook`/`_tabIndex` cross-tab navigation plumbing; the
Stories tab's own drill-down uses `Navigator.push` independently.

## Testing

- `test/data/models/story_test.dart` — `fromJson` parsing, including a
  multi-reference story.
- `test/data/story_repository_test.dart` — loads fixture JSON, filters by
  testament, preserves `id` order.
- `test/ui/stories/stories_screen_test.dart` — OT/NT toggle filters the
  list; tapping a story pushes to `StoryDetailScreen` showing that story's
  title.
- `test/ui/stories/story_detail_screen_test.dart` — Summary tab shows the
  summary text; Verses tab renders matching `PassageCard`s for a covered
  reference, and a "Not translated yet" placeholder for an uncovered one;
  a compound-reference fixture with one covered and one uncovered range
  shows both a `PassageCard` and a placeholder together.

## Out of scope

- Drafting any new slang content (Old Testament or otherwise).
- Bookmarking or sharing "stories" as a unit (only per-passage bookmarking/
  sharing, already provided by the reused `PassageCard`).
- Any change to the existing 5 tabs' navigation behavior.
