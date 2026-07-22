# Multiple Selectable Themes — Design Spec

## Status: approved, ready for implementation planning

## Context

The app currently ships with one fixed theme (preppy pastel, built in
`lib/ui/theme/app_theme.dart`'s `buildAppTheme()`). During the original app
brainstorm, two other 80s aesthetics were considered and set aside: neon
synthwave and retro arcade/VHS. The user now wants all three available as
user-selectable themes rather than picking just one at build time.

A decorative dot-grid painter (`MemphisDotGrid`/`MemphisDotGridPainter` in
`lib/ui/theme/memphis_decorations.dart`) already exists from the original
build but isn't currently used anywhere in the UI — this feature is the
occasion to actually wire per-theme decoration into the screens, not just
recolor a single unused painter three ways.

## Goals

- Three selectable themes: Preppy Pastel (existing), Neon Synthwave (new),
  Retro Arcade/VHS (new) — each with its own color palette AND its own
  decorative motif (not just a recolor of one motif).
- A new Settings screen (5th bottom-nav tab) lets the user pick a theme;
  the choice applies immediately and persists across app restarts.
- Default theme remains Preppy Pastel for existing/new users.

## Non-goals

- No per-screen theme overrides (the whole app follows one selected theme).
- No custom/user-defined themes — exactly three fixed options.
- No changes to the content pipeline or data model — this is UI-only.

## Architecture

### Theme identity and builders

```dart
enum AppThemeId { pastel, neon, retroArcade }
```

`lib/ui/theme/app_theme.dart` is restructured into one file per theme plus a
dispatcher:
- `lib/ui/theme/pastel_theme.dart` — `PastelColors` (moved from today's
  `AppColors`) + `buildPastelTheme()` (today's `buildAppTheme()`, renamed).
- `lib/ui/theme/neon_theme.dart` — `NeonColors` (dark background, neon pink
  `#FF3EC9`/cyan `#3EF7FF`/purple `#B537F2`) + `buildNeonTheme()` (dark
  `ThemeData`, high-contrast text).
- `lib/ui/theme/retro_theme.dart` — `RetroColors` (bold primaries: red
  `#FF3B30`, yellow `#FFD60A`, blue `#0A84FF`, black borders) +
  `buildRetroTheme()` (chunky rounded-rect cards, thick borders).
- `lib/ui/theme/app_theme.dart` keeps a single dispatcher:
  `ThemeData buildTheme(AppThemeId id)` switching over the three builders.

### Decorations per theme

`lib/ui/theme/memphis_decorations.dart`'s existing `MemphisDotGrid`/
`MemphisDotGridPainter` stay as the pastel motif. Two new sibling widgets are
added in the same file (or split into `neon_decorations.dart` /
`retro_decorations.dart` if they grow large — decided during planning):
- `NeonGridLines`/`NeonGridLinesPainter` — a glowing grid-line pattern
  (horizontal/vertical lines with a neon color and slight blur/glow effect
  via `MaskFilter.blur`).
- `RetroScanlines`/`RetroScanlinesPainter` — horizontal scanline texture
  (thin semi-transparent bands) evoking a CRT/VHS look.

A single helper, `decorationForTheme(AppThemeId id)`, returns the right
decoration widget so calling code doesn't need its own switch statement.

**Wiring into the UI:** since the pastel dot-grid was built but never used,
this feature adds the decoration as a background layer behind `PassageCard`
(the one widget shared by Reader/Home/Bookmarks/Search), via a `Stack` with
the decoration positioned behind the existing `Card`. This makes all three
themes' motifs actually visible without touching every screen individually.

### Theme selection state

`lib/logic/theme_provider.dart`, following the exact pattern already
established by `lib/logic/bookmarks_provider.dart`:

```dart
class ThemeNotifier extends Notifier<AppThemeId> {
  @override
  AppThemeId build() {
    final stored = ref.watch(sharedPreferencesProvider).getString('app_theme_id');
    return AppThemeId.values.firstWhere(
      (v) => v.name == stored,
      orElse: () => AppThemeId.pastel,
    );
  }

  Future<void> select(AppThemeId id) async {
    state = id;
    await ref.read(sharedPreferencesProvider).setString('app_theme_id', id.name);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeId>(ThemeNotifier.new);
```

(Reuses the existing `sharedPreferencesProvider` from `bookmarks_provider.dart`
— no new SharedPreferences plumbing needed.)

### App wiring

`main.dart`'s `SlangBibleApp` becomes a `ConsumerWidget`:
```dart
class SlangBibleApp extends ConsumerWidget {
  ...
  Widget build(BuildContext context, WidgetRef ref) {
    final themeId = ref.watch(themeProvider);
    return MaterialApp(theme: buildTheme(themeId), home: RootShell(...));
  }
}
```
`RootShell`'s `NavigationBar` gains a 5th destination ("Settings"), and its
`IndexedStack` gains a 5th screen.

### Settings screen

`lib/ui/settings/settings_screen.dart` — a `ConsumerWidget` showing a simple
list of the three themes (name + small color-swatch preview), with the
currently-selected one visually marked (e.g. a checkmark or highlighted
tile). Tapping a theme calls `ref.read(themeProvider.notifier).select(id)`.

## Error handling / edge cases

- A corrupted/unrecognized stored theme string (e.g. from a future removed
  theme id) falls back to `AppThemeId.pastel` via the `orElse` in
  `ThemeNotifier.build()` — never crashes on a bad persisted value.

## Testing

- Unit tests per theme builder (`buildPastelTheme`, `buildNeonTheme`,
  `buildRetroTheme`) asserting key colors/shapes, following the existing
  `app_theme_test.dart` pattern.
- Widget tests for each new decoration painter (renders without throwing,
  `shouldRepaint` behaves correctly), following the existing
  `memphis_decorations_test.dart` pattern.
- Unit tests for `ThemeNotifier` (defaults to pastel, hydrates from storage,
  `select()` persists), following the existing `bookmarks_provider_test.dart`
  pattern.
- Widget tests for `SettingsScreen` (lists three themes, tapping one updates
  `themeProvider` and is reflected in a subsequent rebuild).
- Manual verification on the Android emulator: switch between all three
  themes from Settings, confirm the whole app (Home/Reader/Bookmarks/Search)
  updates immediately, confirm the choice survives an app restart.

## Key files

- `lib/ui/theme/app_theme.dart` — becomes the `AppThemeId` + dispatcher only
- `lib/ui/theme/pastel_theme.dart`, `neon_theme.dart`, `retro_theme.dart` — new
- `lib/ui/theme/memphis_decorations.dart` — gains `NeonGridLines`/`RetroScanlines`
  (or split into new sibling files if it grows unwieldy)
- `lib/logic/theme_provider.dart` — new
- `lib/ui/settings/settings_screen.dart` — new
- `lib/ui/reader/passage_card.dart` — modified to render the theme's
  decoration behind the card
- `lib/main.dart` — `SlangBibleApp` becomes `ConsumerWidget`; `RootShell` gains
  a 5th tab

## Open items for the implementation plan

- Exact neon/retro hex values are illustrative above — fine-tune during
  implementation for contrast/accessibility (e.g. text legibility on the
  neon theme's dark background).
- Whether the three decoration painters stay in one file or get split —
  decide based on how large `memphis_decorations.dart` grows.
