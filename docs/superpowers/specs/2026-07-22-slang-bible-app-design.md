# Slang Bible App — Design Spec

## Status: approved, ready for implementation planning

## Context

Sub-project 2 of 2 for the overall Bible-in-slang project (see
`docs/superpowers/specs/` for the sibling content-pipeline spec, and
`fetch.py` / `compile.py` / `data/*.json` in the project root for the pipeline
itself). The pipeline produces structured JSON translations; this app
consumes them. The translation style is 1980s slang, which led to the
decision to theme the whole app around the 1980s (preppy pastel aesthetic,
not synthwave or arcade).

The app does not need the whole Bible translated to be built — it should be
designed to read whatever books/chapters exist in its bundled data and treat
untranslated books as an expected, handled state. Currently only a 13-passage
sample of John chapter 1 exists (`data/john.json`).

## Goals

- Android + iOS app, built with Flutter (single Dart codebase).
- Offline-first: no backend, no network calls. Content ships as bundled JSON
  assets inside the app package.
- Core reading experience: browse Book → Chapter → passage, slang text by
  default with a toggle to view the original WEB (World English Bible) text
  for the same passage.
- Supporting features: verse-of-the-day home feed, bookmarks/favorites,
  keyword/reference search, and sharing (image card + plain text).
- Visual theme: 1980s preppy pastel — soft pastel palette (pink/mint/lavender
  /peach), Memphis-design geometric accents (squiggles, triangles, dot-grids),
  rounded/friendly typography, applied consistently via Flutter's theming
  system.

## Non-goals (for this version)

- No backend/remote content delivery — adding new translated books happens
  via an app update, not a runtime fetch. (Revisit if content delivery
  cadence becomes a problem later.)
- No user accounts or cross-device sync — bookmarks are local to the device.
- No full-Bible content requirement — the app must work correctly with
  partial content (currently just a sample of John 1).

## Architecture

Layered Flutter structure:

- **Data layer** — loads bundled JSON assets (e.g. `assets/data/john.json`,
  one file per book as the pipeline produces more) into Dart model objects at
  startup. Exposes lookup by (book, chapter) and a flat list for search.
- **Logic layer** — state management (Riverpod or Provider) for: current
  reading position, WEB/slang toggle state per passage, bookmarks (persisted
  locally, e.g. via `shared_preferences` or a lightweight local DB), and
  search query/results.
- **UI layer** — screens and widgets, styled through a centralized
  `ThemeData`/custom theme extension for the pastel 80s look, so colors and
  decorative motifs aren't hand-coded per screen.

### Data model

Mirrors the pipeline's output directly (`data/*.json`) — no transformation
needed between pipeline and app:

```dart
class Passage {
  final String book;
  final int chapter;
  final int verseStart;
  final int verseEnd;
  final String webText;
  final String slangText;
}
```

Identity for bookmarks/navigation is `(book, chapter, verseStart, verseEnd)`.

## Screens

- **Home** — Verse of the Day card (date-seeded pick from available bundled
  passages, so it's stable across the day and doesn't require any server);
  entry point into the Reader.
- **Reader** — Book → Chapter navigation, passage view. Slang text shown by
  default; a toggle switches the *currently viewed passage* between slang and
  WEB text (toggle is per-passage granularity, matching how content is
  chunked — not per-verse). Share action available per passage.
- **Bookmarks** — list of saved passages; tapping one jumps into the Reader
  at that passage.
- **Search** — search by reference (e.g. "John 3") or keyword, scoped to
  whatever books are currently bundled; results link into the Reader at the
  matching passage.

## Sharing

- From the Reader (and from the Home Verse of the Day card): share as a
  styled image card (rendered in the 80s pastel theme, includes reference +
  slang text) or as plain text, using the platform share sheet.

## Error handling / edge cases

- Requesting a book/chapter not yet present in bundled data is an **expected
  state**, not an error: Reader shows a "not translated yet" message rather
  than crashing or showing a blank screen.
- Search and Bookmarks only ever operate over bundled data, so there's no
  "stale reference" case to handle (nothing points to content that isn't
  there, since bookmarks can only be created from content the app has
  actually shown).

## Testing

- Widget tests for the Reader (slang/WEB toggle behavior, passage rendering,
  "not translated yet" state for a missing book).
- Unit tests for the data layer (JSON asset parsing, book/chapter lookup,
  search matching logic).
- Manual verification via Android emulator and/or iOS simulator of the golden
  path: browse → read a passage → toggle WEB/slang → bookmark it → find it
  again via Bookmarks → search for a reference → share a passage.

## Key files (to be created during implementation)

- `app/` — Flutter project root (name TBD during implementation planning)
- `app/assets/data/*.json` — copies of/symlinks to the pipeline's `data/*.json`
  output
- `app/lib/data/` — data layer (models, asset loading, lookup/search)
- `app/lib/logic/` — state management (reading position, toggle state,
  bookmarks, search)
- `app/lib/ui/` — screens and shared widgets, plus the centralized 80s pastel
  theme definition

## Open items for the implementation plan

- Exact Flutter package choices (state management library, local persistence
  library, image-card rendering approach for sharing).
- How pipeline output gets copied into `app/assets/data/` (manual copy step
  vs. a small build script) — not a design concern, but should be nailed down
  during planning so the two sub-projects stay in sync.
