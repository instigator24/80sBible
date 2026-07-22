# Arcade Cabinet PassageCard (Retro Arcade theme)

## Problem

In the Retro Arcade theme, `PassageCard` currently looks the same as it does in
every other theme (plain white `Card`, black border, scanline texture painted
behind it) — only the color/border/scanline decoration changes. We want each
verse card in this theme to look like it's displayed inside an arcade
cabinet: a marquee banner for the reference, a bezel around a CRT-style
screen for the verse text, and arcade-style round buttons for the actions.

## Scope

- Applies only to `AppThemeId.retroArcade`. The other two themes (pastel,
  neon) are unaffected.
- Applies to `PassageCard`, which is used by both `ReaderScreen` (list of
  verses) and `HomeScreen` (verse of the day) — both get the new look
  automatically since they share the widget.
- Does not change `PassageCard`'s public API (`Passage passage`), its state
  (`_showWeb`), or its callbacks (bookmarks, share text, share image).

## Approach

`PassageCard` stays a single `ConsumerStatefulWidget` with its existing
state and logic (bookmark toggle, show WEB/slang toggle, share text, share
as image via `RepaintBoundary`). At build time, it branches on `themeId`:

- `themeId == AppThemeId.retroArcade` → render the new arcade cabinet layout.
- otherwise → render the existing plain-card layout (unchanged).

Rejected alternatives:
- **Separate `ArcadeCabinetCard` widget with its own state** — would
  duplicate the toggle/bookmark/share logic in two places and risk them
  drifting out of sync. Rejected.
- **Generalize `theme_decoration.dart` into a full "card chrome"
  abstraction** all three themes plug into — premature: only retro needs a
  structural reskin today, the other two only need a background painter.
  Revisit if a second theme needs a deep reskin later.

## Visual structure (retro branch)

Modeled on "Variant A" from the mockup review, with buttons wired to real
actions (not decorative):

1. **Marquee** — red banner, black border, bold cream text showing
   `passage.reference`. Replaces the current plain reference `Text`.
2. **Bezel** — dark gray/black chunky frame wrapping the screen.
3. **Screen** — near-black background; verse text (`_showWeb ? webText :
   slangText`) rendered in Flutter's built-in `monospace` font family,
   green-ish text color, with:
   - the existing `RetroScanlinesPainter` reused/tuned for a dark
     background (subtle white-on-black lines instead of ink-on-cream), and
   - an inset shadow/glow effect for CRT feel.
4. **Control deck** — below the screen, the 4 existing actions rendered as
   round arcade-style buttons (colored circles with black borders) instead
   of `TextButton`/`IconButton`:
   - Show WEB / Show slang toggle
   - Bookmark (star)
   - Share text
   - Share as image
   Same `Key`s (`toggle-web-slang`, `bookmark-button`, `share-text-button`,
   `share-image-button`) and same callbacks as today — only the visual
   treatment changes.
5. **Font** — Flutter's built-in `monospace` family. No new font asset or
   pubspec dependency.

## Fallback

If the full cabinet (marquee + bezel + control deck) reads too bulky/tall
once seen in a real scrolling list of many verses, drop to a slimmer
variant: tighter padding/sizes, smaller marquee, keeping the same arcade
buttons for the control deck. This is a follow-up tuning pass, not a
different architecture.

## Testing

- Existing `test/ui/reader/passage_card_test.dart` continues to cover the
  2 non-retro themes unchanged (no behavior change there).
- Add retro-specific widget tests (in the same file or a new
  `passage_card_retro_test.dart`):
  - pump with `themeProvider` overridden to `AppThemeId.retroArcade`
  - assert the marquee/screen render (e.g. reference text appears, verse
    text appears)
  - assert all 4 action buttons still fire their existing callbacks by key
    (toggle shows WEB/slang text change, bookmark toggle updates
    `bookmarksProvider`, share text/image call through to the `Sharer`
    fake) — mirroring the assertions already made for the default theme.

## Out of scope

- No changes to the other two themes' `PassageCard` rendering.
- No new fonts/assets.
- No changes to `HomeScreen`/`ReaderScreen` beyond what falls out of
  `PassageCard` automatically looking different in retro theme.
