# Multiple Selectable Themes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user pick between three 80s themes (Preppy Pastel, Neon Synthwave, Retro Arcade/VHS) from a new Settings screen, with the choice applied live and persisted, and each theme carrying its own distinct decorative motif visible behind passage cards.

**Architecture:** Split the single `app_theme.dart` into one file per theme plus an `AppThemeId`-keyed dispatcher; add a matching decoration widget per theme and a `decorationForTheme` dispatcher; add a `themeProvider` (Riverpod `Notifier` + `SharedPreferences`, following the exact pattern of the existing `bookmarksProvider`); wire the selected theme into `MaterialApp` and into `PassageCard`'s background; add a `SettingsScreen` as a 5th bottom-nav tab.

**Tech Stack:** Same as the rest of the app — Flutter 3.41, `flutter_riverpod`, `shared_preferences`. No new dependencies.

**Note on version control:** this project isn't using git yet. Every task's final step is plain verification, not a commit — do not run any `git` commands during this plan.

---

## File Structure

```
app/lib/ui/theme/
  app_theme.dart            # becomes AppThemeId enum + buildTheme() dispatcher (Task 1)
  pastel_theme.dart          # PastelColors + buildPastelTheme() (Task 1, moved from app_theme.dart)
  neon_theme.dart            # NeonColors + buildNeonTheme() (Task 2)
  retro_theme.dart           # RetroColors + buildRetroTheme() (Task 3)
  memphis_decorations.dart   # MemphisDotGrid(Painter) — import updated to pastel_theme.dart (Task 4)
  neon_decorations.dart      # NeonGridLines(Painter) (Task 5)
  retro_decorations.dart     # RetroScanlines(Painter) (Task 6)
  theme_decoration.dart      # decorationForTheme(AppThemeId) dispatcher (Task 7)
app/lib/logic/
  theme_provider.dart        # ThemeNotifier + themeProvider (Task 8)
app/lib/ui/reader/
  passage_card.dart          # modified: renders decorationForTheme() behind the Card (Task 9)
app/lib/ui/settings/
  settings_screen.dart       # SettingsScreen (Task 10)
app/lib/main.dart            # SlangBibleApp -> ConsumerWidget; RootShell gains Settings tab (Task 11)

app/test/ui/theme/
  pastel_theme_test.dart     # renamed/updated from app_theme_test.dart (Task 1)
  app_theme_test.dart        # rewritten: tests buildTheme() dispatcher (Task 1)
  neon_theme_test.dart       # (Task 2)
  retro_theme_test.dart      # (Task 3)
  memphis_decorations_test.dart  # updated import only (Task 4)
  neon_decorations_test.dart # (Task 5)
  retro_decorations_test.dart # (Task 6)
  theme_decoration_test.dart # (Task 7)
app/test/logic/
  theme_provider_test.dart   # (Task 8)
app/test/ui/reader/
  passage_card_test.dart     # existing file, gains 2 new test cases (Task 9)
app/test/ui/settings/
  settings_screen_test.dart  # (Task 10)
```

---

### Task 1: Split pastel theme out; add `AppThemeId` + dispatcher

**Files:**
- Create: `app/lib/ui/theme/pastel_theme.dart`
- Modify: `app/lib/ui/theme/app_theme.dart` (becomes the dispatcher)
- Modify: `app/lib/ui/theme/memphis_decorations.dart` (import path only)
- Create: `app/test/ui/theme/pastel_theme_test.dart` (moved/renamed content)
- Modify: `app/test/ui/theme/app_theme_test.dart` (rewritten for the dispatcher)
- Modify: `app/test/ui/theme/memphis_decorations_test.dart` (import path only)

This is a rename/refactor of existing, already-tested code — the "failing test" step here is the *new* dispatcher test (which can't pass until `app_theme.dart` is rewritten), not a re-test of the pastel colors themselves (those tests just move file and keep passing).

- [ ] **Step 1: Create `pastel_theme.dart` with today's pastel theme, renamed**

```dart
// app/lib/ui/theme/pastel_theme.dart
import 'package:flutter/material.dart';

/// 1980s "preppy pastel" palette: soft pink/mint/lavender/peach on a warm
/// cream background, with a dark ink color for text and card borders
/// (Memphis-design style — bold outlines on soft colors).
class PastelColors {
  static const pink = Color(0xFFFFC2D1);
  static const mint = Color(0xFFB8F2E6);
  static const lavender = Color(0xFFD9C9F2);
  static const peach = Color(0xFFFFDAB9);
  static const ink = Color(0xFF2E2A3B);
  static const background = Color(0xFFFFF7F0);
}

ThemeData buildPastelTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: PastelColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PastelColors.lavender,
      brightness: Brightness.light,
    ).copyWith(
      primary: PastelColors.lavender,
      secondary: PastelColors.mint,
      tertiary: PastelColors.peach,
      surface: PastelColors.background,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w800,
        color: PastelColors.ink,
      ),
      bodyLarge: TextStyle(color: PastelColors.ink, height: 1.4),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: PastelColors.ink, width: 2),
      ),
    ),
  );
}
```

- [ ] **Step 2: Move the old test file's content to `pastel_theme_test.dart`, updated for the new names**

```dart
// app/test/ui/theme/pastel_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/pastel_theme.dart';

void main() {
  group('buildPastelTheme', () {
    test('uses the pastel background and lavender primary color', () {
      final theme = buildPastelTheme();
      expect(theme.scaffoldBackgroundColor, PastelColors.background);
      expect(theme.colorScheme.primary, PastelColors.lavender);
      expect(theme.colorScheme.secondary, PastelColors.mint);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('card theme has rounded corners and an ink border', () {
      final theme = buildPastelTheme();
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(20));
      expect((shape.side.color), PastelColors.ink);
    });
  });
}
```

- [ ] **Step 3: Delete the old `app/lib/ui/theme/app_theme.dart` content and old test content**

Run:
```bash
rm /home/joel/Code/bible_slang/app/lib/ui/theme/app_theme.dart
rm /home/joel/Code/bible_slang/app/test/ui/theme/app_theme_test.dart
```
(Both are recreated in the next steps with new content — this avoids leaving stale `AppColors`/`buildAppTheme` symbols around.)

- [ ] **Step 4: Write the new (failing) dispatcher test**

```dart
// app/test/ui/theme/app_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/app_theme.dart';
import 'package:slang_bible/ui/theme/pastel_theme.dart';

void main() {
  group('buildTheme', () {
    test('pastel id returns the pastel theme', () {
      final theme = buildTheme(AppThemeId.pastel);
      expect(theme.scaffoldBackgroundColor, PastelColors.background);
    });

    test('each AppThemeId value produces a distinct scaffoldBackgroundColor', () {
      final colors = AppThemeId.values.map((id) => buildTheme(id).scaffoldBackgroundColor).toSet();
      expect(colors.length, AppThemeId.values.length);
    });
  });
}
```

- [ ] **Step 5: Run tests to verify the dispatcher test fails and the pastel test passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/`
Expected: `pastel_theme_test.dart` passes (2 tests); `app_theme_test.dart` FAILS to compile — `package:slang_bible/ui/theme/app_theme.dart` has no `AppThemeId`/`buildTheme` (file doesn't exist yet after Step 3's delete).

- [ ] **Step 6: Write the new `app_theme.dart` dispatcher**

This step's full content depends on Tasks 2 and 3 existing (`neon_theme.dart`, `retro_theme.dart`), so this file is completed incrementally: write it now importing only `pastel_theme.dart` with a 1-case switch, then Tasks 2 and 3 will each add one case. For this task, write:

```dart
// app/lib/ui/theme/app_theme.dart
import 'package:flutter/material.dart';

import 'pastel_theme.dart';

enum AppThemeId { pastel, neon, retroArcade }

ThemeData buildTheme(AppThemeId id) {
  switch (id) {
    case AppThemeId.pastel:
      return buildPastelTheme();
    case AppThemeId.neon:
      throw UnimplementedError('neon theme added in a later task');
    case AppThemeId.retroArcade:
      throw UnimplementedError('retro theme added in a later task');
  }
}
```

- [ ] **Step 7: Update `memphis_decorations.dart`'s import**

```dart
// app/lib/ui/theme/memphis_decorations.dart
import 'package:flutter/material.dart';

import 'pastel_theme.dart';

class MemphisDotGridPainter extends CustomPainter {
  final Color color;
  final double dotRadius;
  final double spacing;

  const MemphisDotGridPainter({
    this.color = PastelColors.ink,
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
/// Memphis-design texture called for in the pastel theme.
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
(Only the import and `AppColors` → `PastelColors` references changed; everything else is byte-identical to before.)

- [ ] **Step 8: Update `memphis_decorations_test.dart`'s import**

Open `app/test/ui/theme/memphis_decorations_test.dart` and change any reference from `app_theme.dart` to `pastel_theme.dart` if present (the current version of this file doesn't actually import `app_theme.dart` directly — it only imports `memphis_decorations.dart` — so this step may be a no-op; check the actual current file content and only change what's needed).

- [ ] **Step 9: Run the full theme test directory to verify everything passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/`
Expected: `pastel_theme_test.dart` (2 tests), `app_theme_test.dart` (2 tests), `memphis_decorations_test.dart` (3 tests) all pass. `buildTheme(AppThemeId.neon)` and `buildTheme(AppThemeId.retroArcade)` still throw `UnimplementedError` at this point — that's expected and fixed in Tasks 2-3. The dispatcher test's "distinct scaffoldBackgroundColor" case will fail until Tasks 2 and 3 land; note this and continue (this is a multi-task file, expected to be red until Task 3 completes) — do not treat it as a regression to fix within this task.

- [ ] **Step 10: Verify and move on**

Run: `cd /home/joel/Code/bible_slang/app && flutter analyze lib/ui/theme/ test/ui/theme/`
Expected: no issues other than the intentionally-incomplete dispatcher (which should still analyze cleanly — `UnimplementedError` is valid Dart). No commit.

---

### Task 2: Neon Synthwave theme

**Files:**
- Create: `app/lib/ui/theme/neon_theme.dart`
- Modify: `app/lib/ui/theme/app_theme.dart` (wire in the neon case)
- Test: `app/test/ui/theme/neon_theme_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/ui/theme/neon_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/neon_theme.dart';

void main() {
  group('buildNeonTheme', () {
    test('uses a dark background and neon pink primary color', () {
      final theme = buildNeonTheme();
      expect(theme.scaffoldBackgroundColor, NeonColors.background);
      expect(theme.colorScheme.primary, NeonColors.pink);
      expect(theme.colorScheme.secondary, NeonColors.cyan);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('card theme uses a dark card color and a cyan border', () {
      final theme = buildNeonTheme();
      expect(theme.cardTheme.color, NeonColors.cardBackground);
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect((shape.side.color), NeonColors.cyan);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/neon_theme_test.dart`
Expected: FAIL — `package:slang_bible/ui/theme/neon_theme.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/ui/theme/neon_theme.dart
import 'package:flutter/material.dart';

/// Synthwave/neon palette: a near-black deep-purple background with
/// glowing neon pink/cyan/purple accents, evoking 80s sci-fi/arcade art.
class NeonColors {
  static const pink = Color(0xFFFF2CDF);
  static const cyan = Color(0xFF00F0FF);
  static const purple = Color(0xFFB537F2);
  static const background = Color(0xFF0D0221);
  static const cardBackground = Color(0xFF1A0B2E);
  static const text = Color(0xFFF5F5FF);
}

ThemeData buildNeonTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: NeonColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: NeonColors.pink,
      brightness: Brightness.dark,
    ).copyWith(
      primary: NeonColors.pink,
      secondary: NeonColors.cyan,
      tertiary: NeonColors.purple,
      surface: NeonColors.cardBackground,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w800,
        color: NeonColors.cyan,
      ),
      bodyLarge: TextStyle(color: NeonColors.text, height: 1.4),
    ),
    cardTheme: CardThemeData(
      color: NeonColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: NeonColors.cyan, width: 2),
      ),
    ),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/neon_theme_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Wire the neon case into the dispatcher**

In `app/lib/ui/theme/app_theme.dart`, add the import and replace the neon case:
```dart
import 'neon_theme.dart';
```
```dart
    case AppThemeId.neon:
      return buildNeonTheme();
```
(Leave the `retroArcade` case as `throw UnimplementedError(...)` — Task 3 handles it.)

- [ ] **Step 6: Run the dispatcher test — still expect one failure**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/app_theme_test.dart`
Expected: "pastel id returns the pastel theme" passes; "each AppThemeId value produces a distinct scaffoldBackgroundColor" still FAILS (retroArcade still throws). This is expected — Task 3 completes it.

- [ ] **Step 7: Verify and move on**

Run: `cd /home/joel/Code/bible_slang/app && flutter analyze lib/ui/theme/neon_theme.dart`
Expected: "No issues found!" No commit.

---

### Task 3: Retro Arcade/VHS theme

**Files:**
- Create: `app/lib/ui/theme/retro_theme.dart`
- Modify: `app/lib/ui/theme/app_theme.dart` (wire in the retro case)
- Test: `app/test/ui/theme/retro_theme_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/ui/theme/retro_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/retro_theme.dart';

void main() {
  group('buildRetroTheme', () {
    test('uses a cream background and red primary color', () {
      final theme = buildRetroTheme();
      expect(theme.scaffoldBackgroundColor, RetroColors.cream);
      expect(theme.colorScheme.primary, RetroColors.red);
      expect(theme.colorScheme.secondary, RetroColors.blue);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('card theme has a chunky ink border', () {
      final theme = buildRetroTheme();
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.side.width, 4);
      expect(shape.side.color, RetroColors.ink);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/retro_theme_test.dart`
Expected: FAIL — `package:slang_bible/ui/theme/retro_theme.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/ui/theme/retro_theme.dart
import 'package:flutter/material.dart';

/// Retro arcade/VHS palette: bold primary colors on a warm cream
/// background with thick black borders, evoking 80s arcade cabinets and
/// VHS box art.
class RetroColors {
  static const red = Color(0xFFFF3B30);
  static const blue = Color(0xFF0A84FF);
  static const yellow = Color(0xFFFFD60A);
  static const cream = Color(0xFFFDF6E3);
  static const ink = Color(0xFF1C1C1E);
}

ThemeData buildRetroTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: RetroColors.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: RetroColors.red,
      brightness: Brightness.light,
    ).copyWith(
      primary: RetroColors.red,
      secondary: RetroColors.blue,
      tertiary: RetroColors.yellow,
      surface: RetroColors.cream,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w900,
        color: RetroColors.ink,
      ),
      bodyLarge: TextStyle(color: RetroColors.ink, height: 1.4),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: RetroColors.ink, width: 4),
      ),
    ),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/retro_theme_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Wire the retro case into the dispatcher**

In `app/lib/ui/theme/app_theme.dart`, add the import and replace the retro case:
```dart
import 'retro_theme.dart';
```
```dart
    case AppThemeId.retroArcade:
      return buildRetroTheme();
```

- [ ] **Step 6: Run the full dispatcher test — both should now pass**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/app_theme_test.dart`
Expected: PASS (2 tests) — all three themes now produce distinct `scaffoldBackgroundColor`s.

- [ ] **Step 7: Verify and move on**

Run: `cd /home/joel/Code/bible_slang/app && flutter analyze lib/ui/theme/`
Expected: "No issues found!" No commit.

---

### Task 4: Neon grid-line decoration

**Files:**
- Create: `app/lib/ui/theme/neon_decorations.dart`
- Test: `app/test/ui/theme/neon_decorations_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/ui/theme/neon_decorations_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/neon_decorations.dart';

void main() {
  testWidgets('NeonGridLines renders without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 200, height: 100, child: NeonGridLines()),
      ),
    );

    expect(find.byType(NeonGridLines), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('NeonGridLinesPainter.shouldRepaint', () {
    test('returns true when spacing changes', () {
      const a = NeonGridLinesPainter(spacing: 24);
      const b = NeonGridLinesPainter(spacing: 32);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('returns false when nothing changes', () {
      const a = NeonGridLinesPainter();
      const b = NeonGridLinesPainter();
      expect(a.shouldRepaint(b), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/neon_decorations_test.dart`
Expected: FAIL — `package:slang_bible/ui/theme/neon_decorations.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/ui/theme/neon_decorations.dart
import 'package:flutter/material.dart';

import 'neon_theme.dart';

class NeonGridLinesPainter extends CustomPainter {
  final Color color;
  final double spacing;

  const NeonGridLinesPainter({
    this.color = NeonColors.cyan,
    this.spacing = 24,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant NeonGridLinesPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.spacing != spacing;
}

/// A glowing grid-line background evoking the synthwave/neon aesthetic.
class NeonGridLines extends StatelessWidget {
  final double spacing;

  const NeonGridLines({super.key, this.spacing = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: NeonGridLinesPainter(spacing: spacing));
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/neon_decorations_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Verify and move on**

Run: `cd /home/joel/Code/bible_slang/app && flutter analyze lib/ui/theme/neon_decorations.dart`
Expected: "No issues found!" No commit.

---

### Task 5: Retro scanline decoration

**Files:**
- Create: `app/lib/ui/theme/retro_decorations.dart`
- Test: `app/test/ui/theme/retro_decorations_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/ui/theme/retro_decorations_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/retro_decorations.dart';

void main() {
  testWidgets('RetroScanlines renders without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 200, height: 100, child: RetroScanlines()),
      ),
    );

    expect(find.byType(RetroScanlines), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('RetroScanlinesPainter.shouldRepaint', () {
    test('returns true when lineSpacing changes', () {
      const a = RetroScanlinesPainter(lineSpacing: 6);
      const b = RetroScanlinesPainter(lineSpacing: 10);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('returns false when nothing changes', () {
      const a = RetroScanlinesPainter();
      const b = RetroScanlinesPainter();
      expect(a.shouldRepaint(b), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/retro_decorations_test.dart`
Expected: FAIL — `package:slang_bible/ui/theme/retro_decorations.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/ui/theme/retro_decorations.dart
import 'package:flutter/material.dart';

import 'retro_theme.dart';

class RetroScanlinesPainter extends CustomPainter {
  final Color color;
  final double lineSpacing;
  final double lineThickness;

  const RetroScanlinesPainter({
    this.color = RetroColors.ink,
    this.lineSpacing = 6,
    this.lineThickness = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.08);
    for (double y = 0; y < size.height; y += lineSpacing) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, lineThickness), paint);
    }
  }

  @override
  bool shouldRepaint(covariant RetroScanlinesPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.lineSpacing != lineSpacing ||
      oldDelegate.lineThickness != lineThickness;
}

/// A horizontal scanline texture evoking a CRT/VHS look.
class RetroScanlines extends StatelessWidget {
  final double lineSpacing;
  final double lineThickness;

  const RetroScanlines({
    super.key,
    this.lineSpacing = 6,
    this.lineThickness = 1,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RetroScanlinesPainter(
        lineSpacing: lineSpacing,
        lineThickness: lineThickness,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/retro_decorations_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Verify and move on**

Run: `cd /home/joel/Code/bible_slang/app && flutter analyze lib/ui/theme/retro_decorations.dart`
Expected: "No issues found!" No commit.

---

### Task 6: `decorationForTheme` dispatcher

**Files:**
- Create: `app/lib/ui/theme/theme_decoration.dart`
- Test: `app/test/ui/theme/theme_decoration_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/ui/theme/theme_decoration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/app_theme.dart';
import 'package:slang_bible/ui/theme/memphis_decorations.dart';
import 'package:slang_bible/ui/theme/neon_decorations.dart';
import 'package:slang_bible/ui/theme/retro_decorations.dart';
import 'package:slang_bible/ui/theme/theme_decoration.dart';

void main() {
  group('decorationForTheme', () {
    test('pastel maps to MemphisDotGrid', () {
      expect(decorationForTheme(AppThemeId.pastel), isA<MemphisDotGrid>());
    });

    test('neon maps to NeonGridLines', () {
      expect(decorationForTheme(AppThemeId.neon), isA<NeonGridLines>());
    });

    test('retroArcade maps to RetroScanlines', () {
      expect(decorationForTheme(AppThemeId.retroArcade), isA<RetroScanlines>());
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/theme_decoration_test.dart`
Expected: FAIL — `package:slang_bible/ui/theme/theme_decoration.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/ui/theme/theme_decoration.dart
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'memphis_decorations.dart';
import 'neon_decorations.dart';
import 'retro_decorations.dart';

/// Returns the decorative background widget for the given theme, so each
/// theme carries a distinct visual motif (not just distinct colors).
Widget decorationForTheme(AppThemeId id) {
  switch (id) {
    case AppThemeId.pastel:
      return const MemphisDotGrid();
    case AppThemeId.neon:
      return const NeonGridLines();
    case AppThemeId.retroArcade:
      return const RetroScanlines();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/theme/theme_decoration_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Verify and move on**

Run: `cd /home/joel/Code/bible_slang/app && flutter analyze lib/ui/theme/theme_decoration.dart`
Expected: "No issues found!" No commit.

---

### Task 7: Theme selection state (`themeProvider`)

**Files:**
- Create: `app/lib/logic/theme_provider.dart`
- Test: `app/test/logic/theme_provider_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/logic/theme_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/logic/theme_provider.dart';
import 'package:slang_bible/ui/theme/app_theme.dart';

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

  group('themeProvider', () {
    test('defaults to pastel when nothing is stored', () async {
      final container = await makeContainer();
      expect(container.read(themeProvider), AppThemeId.pastel);
    });

    test('hydrates from a previously stored theme id', () async {
      final container = await makeContainer(initial: {'app_theme_id': 'neon'});
      expect(container.read(themeProvider), AppThemeId.neon);
    });

    test('falls back to pastel on an unrecognized stored value', () async {
      final container =
          await makeContainer(initial: {'app_theme_id': 'not_a_real_theme'});
      expect(container.read(themeProvider), AppThemeId.pastel);
    });

    test('select() updates state and persists the choice', () async {
      final container = await makeContainer();
      await container.read(themeProvider.notifier).select(AppThemeId.retroArcade);

      expect(container.read(themeProvider), AppThemeId.retroArcade);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_id'), 'retroArcade');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/logic/theme_provider_test.dart`
Expected: FAIL — `package:slang_bible/logic/theme_provider.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/logic/theme_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/theme/app_theme.dart';
import 'bookmarks_provider.dart';

const _themeKey = 'app_theme_id';

class ThemeNotifier extends Notifier<AppThemeId> {
  @override
  AppThemeId build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_themeKey);
    return AppThemeId.values.firstWhere(
      (v) => v.name == stored,
      orElse: () => AppThemeId.pastel,
    );
  }

  Future<void> select(AppThemeId id) async {
    state = id;
    await ref.read(sharedPreferencesProvider).setString(_themeKey, id.name);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeId>(
  ThemeNotifier.new,
);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/logic/theme_provider_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Verify and move on**

Run: `cd /home/joel/Code/bible_slang/app && flutter analyze lib/logic/theme_provider.dart`
Expected: "No issues found!" No commit.

---

### Task 8: Wire per-theme decoration into `PassageCard`

**Files:**
- Modify: `app/lib/ui/reader/passage_card.dart`
- Modify: `app/test/ui/reader/passage_card_test.dart` (add 2 new test cases; existing 5 cases must keep passing unmodified)

- [ ] **Step 1: Add the two new (failing) test cases to the existing test file**

Add these two `testWidgets` cases to the existing `app/test/ui/reader/passage_card_test.dart` (append after the existing 5 — do not remove or alter the existing ones), and add the needed imports (`ProviderScope` overrides already exist in the file's `_pump` helper — extend it to accept an optional theme override):

```dart
// Add to imports at the top of the existing file:
import 'package:slang_bible/logic/theme_provider.dart';
import 'package:slang_bible/ui/theme/app_theme.dart';
import 'package:slang_bible/ui/theme/memphis_decorations.dart';
import 'package:slang_bible/ui/theme/neon_decorations.dart';

// Modify the existing `_pump` helper to accept an optional theme override:
Future<void> _pump(
  WidgetTester tester, {
  required FakeSharer sharer,
  Map<String, Object> initialBookmarks = const {},
  AppThemeId? themeOverride,
}) async {
  SharedPreferences.setMockInitialValues(initialBookmarks);
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        sharerProvider.overrideWithValue(sharer),
        if (themeOverride != null) themeProvider.overrideWith(() {
          final notifier = ThemeNotifier();
          return notifier;
        }),
      ],
      child: MaterialApp(
        home: Scaffold(body: PassageCard(passage: _passage)),
      ),
    ),
  );
}

// New test cases:
testWidgets('shows the Memphis dot-grid decoration by default (pastel theme)',
    (tester) async {
  await _pump(tester, sharer: FakeSharer());
  expect(find.byType(MemphisDotGrid), findsOneWidget);
  expect(find.byType(NeonGridLines), findsNothing);
});

testWidgets('shows the neon grid-line decoration when the neon theme is selected',
    (tester) async {
  SharedPreferences.setMockInitialValues({'app_theme_id': 'neon'});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        sharerProvider.overrideWithValue(FakeSharer()),
      ],
      child: MaterialApp(
        home: Scaffold(body: PassageCard(passage: _passage)),
      ),
    ),
  );

  expect(find.byType(NeonGridLines), findsOneWidget);
  expect(find.byType(MemphisDotGrid), findsNothing);
});
```

Note: the `themeOverride` parameter added to `_pump` above turns out to be unnecessary once you see the second test doesn't need it (it constructs its own `ProviderScope` directly, matching the existing file's style for one-off cases like the bookmarks test). Remove the unused `themeOverride` parameter and the `if (themeOverride != null)` block from `_pump` before finalizing — keep `_pump` exactly as it was, and only add the two new `testWidgets` blocks. This avoids adding unused/dead parameters.

- [ ] **Step 2: Run test to verify the two new cases fail**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/reader/passage_card_test.dart`
Expected: the original 5 cases still pass; the 2 new cases FAIL because `PassageCard` doesn't render any decoration widget yet.

- [ ] **Step 3: Modify `PassageCard` to render the theme's decoration behind the card**

```dart
// app/lib/ui/reader/passage_card.dart
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/passage.dart';
import '../../logic/bookmarks_provider.dart';
import '../../logic/sharer.dart';
import '../../logic/theme_provider.dart';
import '../theme/theme_decoration.dart';

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
    final themeId = ref.watch(themeProvider);

    return RepaintBoundary(
      key: _boundaryKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Stack(
          children: [
            Positioned.fill(child: decorationForTheme(themeId)),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Card(
                margin: EdgeInsets.zero,
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
                            onPressed: () =>
                                setState(() => _showWeb = !_showWeb),
                            child: Text(_showWeb ? 'Show slang' : 'Show WEB'),
                          ),
                          IconButton(
                            key: const Key('bookmark-button'),
                            icon: Icon(
                              isBookmarked ? Icons.star : Icons.star_border,
                            ),
                            onPressed: () => ref
                                .read(bookmarksProvider.notifier)
                                .toggle(passage.id),
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareAsImage() async {
    // RenderRepaintBoundary.toImage() asserts !debugNeedsPaint. Called
    // synchronously from a tap handler, the button's own ink-splash visual
    // feedback hasn't painted yet, so defer the capture to the end of the
    // current frame (post-frame callbacks run after paint completes).
    // scheduleFrame() ensures a frame actually happens rather than relying
    // on incidental animation-driven frames (e.g. the button's ink splash).
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
    WidgetsBinding.instance.scheduleFrame();
    await completer.future;
    if (!mounted) return;

    final boundary =
        _boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    if (!mounted) {
      image.dispose();
      return;
    }

    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      if (!mounted) return;
      await ref
          .read(sharerProvider)
          .shareImage(bytes, filename: '${widget.passage.id}.png');
    } finally {
      image.dispose();
    }
  }
}
```
(Only the outer wrapping changed — from `Card(margin: ...)` directly under `RepaintBoundary`, to `RepaintBoundary > Padding > Stack[decoration, Padding > Card(margin: zero)]`. The Card's own internal content — `Padding > Column > ...` — is untouched.)

- [ ] **Step 4: Run test to verify all 7 cases pass**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/reader/passage_card_test.dart`
Expected: PASS (6 passed, 1 skipped — the pre-existing skipped image-share test — plus the 2 new decoration tests bring the passing count to 6; confirm the exact count matches: 5 original non-skipped + 2 new = 7 run, 1 skipped, so `+6 ~1`).

- [ ] **Step 5: Run the full suite to check for regressions**

Run: `cd /home/joel/Code/bible_slang/app && flutter test`
Expected: all previously-passing tests still pass; only the counts change (2 more tests than before).

- [ ] **Step 6: Verify and move on**

Run: `cd /home/joel/Code/bible_slang/app && flutter analyze lib/ui/reader/passage_card.dart`
Expected: "No issues found!" No commit.

---

### Task 9: Settings screen

**Files:**
- Create: `app/lib/ui/settings/settings_screen.dart`
- Test: `app/test/ui/settings/settings_screen_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// app/test/ui/settings/settings_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/logic/theme_provider.dart';
import 'package:slang_bible/ui/settings/settings_screen.dart';

Future<ProviderContainer> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
    ),
  );

  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('lists all three themes with the current one checked',
      (tester) async {
    await _pump(tester);

    expect(find.text('Preppy Pastel'), findsOneWidget);
    expect(find.text('Neon Synthwave'), findsOneWidget);
    expect(find.text('Retro Arcade'), findsOneWidget);
    expect(find.byKey(const Key('theme-selected-check')), findsOneWidget);
  });

  testWidgets('tapping a theme updates themeProvider', (tester) async {
    final container = await _pump(tester);

    await tester.tap(find.byKey(const Key('theme-option-neon')));
    await tester.pump();

    expect(container.read(themeProvider), AppThemeId.neon);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/settings/settings_screen_test.dart`
Expected: FAIL — `package:slang_bible/ui/settings/settings_screen.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// app/lib/ui/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/theme_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _labels = {
    AppThemeId.pastel: 'Preppy Pastel',
    AppThemeId.neon: 'Neon Synthwave',
    AppThemeId.retroArcade: 'Retro Arcade',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeProvider);

    return ListView(
      children: AppThemeId.values.map((id) {
        return ListTile(
          key: Key('theme-option-${id.name}'),
          title: Text(_labels[id]!),
          trailing: selected == id
              ? const Icon(Icons.check, key: Key('theme-selected-check'))
              : null,
          onTap: () => ref.read(themeProvider.notifier).select(id),
        );
      }).toList(),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/joel/Code/bible_slang/app && flutter test test/ui/settings/settings_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Verify and move on**

Run: `cd /home/joel/Code/bible_slang/app && flutter analyze lib/ui/settings/settings_screen.dart`
Expected: "No issues found!" No commit.

---

### Task 10: Wire theme selection and Settings tab into `main.dart`

**Files:**
- Modify: `app/lib/main.dart`

- [ ] **Step 1: Replace `main.dart` with the theme-aware version**

```dart
// app/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/bible_books.dart';
import 'data/passage_repository.dart';
import 'logic/bookmarks_provider.dart';
import 'logic/theme_provider.dart';
import 'ui/bookmarks/bookmarks_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/reader/reader_screen.dart';
import 'ui/search/search_screen.dart';
import 'ui/settings/settings_screen.dart';
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

class SlangBibleApp extends ConsumerWidget {
  final PassageRepository repository;

  const SlangBibleApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeId = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Slang Bible',
      theme: buildTheme(themeId),
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
  int _navSeq = 0;

  void _openInReader(String book, int chapter) {
    setState(() {
      _pendingBook = book;
      _pendingChapter = chapter;
      _navSeq++;
      _tabIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(repository: widget.repository, onOpenPassage: _openInReader),
      ReaderScreen(
        key: ValueKey('$_pendingBook-$_pendingChapter-$_navSeq'),
        repository: widget.repository,
        initialBook: _pendingBook,
        initialChapter: _pendingChapter,
      ),
      BookmarksScreen(
        repository: widget.repository,
        onOpenPassage: _openInReader,
      ),
      SearchScreen(repository: widget.repository, onOpenPassage: _openInReader),
      const SettingsScreen(),
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
          NavigationDestination(icon: Icon(Icons.palette), label: 'Settings'),
        ],
      ),
    );
  }
}
```
(Changes from the current file: `SlangBibleApp` becomes `ConsumerWidget` and reads `themeProvider`/`buildTheme`; `RootShell`'s `screens` list and `NavigationBar.destinations` each gain a 5th entry for Settings.)

- [ ] **Step 2: Run the full test suite**

Run: `cd /home/joel/Code/bible_slang/app && flutter test`
Expected: PASS — every test from Tasks 1-9 plus the pre-existing suite, 0 failures (1 pre-existing skip).

- [ ] **Step 3: Analyze the whole project**

Run: `cd /home/joel/Code/bible_slang/app && flutter analyze`
Expected: "No issues found!"

- [ ] **Step 4: Verify and move on**

No commit.

---

### Task 11: Manual verification on Android emulator

**Files:** none (manual QA pass, no code changes)

- [ ] **Step 1: Launch the emulator and run the app**

Run: `flutter emulators --launch Pixel_7a` (wait for it to fully boot), then `cd /home/joel/Code/bible_slang/app && flutter run -d emulator-5554` (adjust device id if it differs — check with `flutter devices`/`adb devices`).

- [ ] **Step 2: Walk the theme-switching golden path**

With the app running, manually verify each of these in order:
1. App launches in Preppy Pastel by default (soft pastel colors, dot-grid texture faintly visible behind cards).
2. Tap the new Settings tab (palette icon) — see all three themes listed, "Preppy Pastel" showing the check mark.
3. Tap "Neon Synthwave" — the ENTIRE app (not just Settings) switches to the dark neon theme immediately: Home, Reader, Bookmarks, and Search all reflect it. Passage cards show the glowing grid-line decoration instead of the dot-grid.
4. Tap "Retro Arcade" — app switches to the cream/bold-primary-color theme with thick black card borders and a subtle scanline texture behind cards.
5. Switch back to "Preppy Pastel" — confirm it returns to the original look exactly (dot-grid decoration, original pastel colors).
6. Fully close and relaunch the app (stop it via `q` in the `flutter run` terminal or kill/relaunch) — confirm the last-selected theme (Preppy Pastel, from step 5) is still selected on relaunch, not reset to a default.
7. Re-select "Neon Synthwave," then exercise a few existing features under the new theme (toggle WEB/slang, bookmark a passage, search) to confirm nothing else broke visually or functionally when the theme changed.

- [ ] **Step 3: Record the outcome**

If every step in Step 2 behaves as described, this feature is functionally complete. If anything deviates, note which step failed and fix the relevant task's code before considering the plan done — do not claim completion without having actually walked through all 7 steps above.

- [ ] **Step 4: Verify and move on**

No commit. (iOS not verified — no Mac/Xcode available in this environment, consistent with the original app plan's noted gap.)

---

## Self-Review Notes

- **Spec coverage:** three themes with distinct colors → Tasks 1-3; distinct decorative motifs per theme → Tasks 4-6 + dispatcher in Task 6; persisted, live-switching selection state → Task 7; actually visible in the UI (not built-and-unused, addressing the original pastel decoration's dormant state) → Task 8; Settings screen → Task 9; app-wide wiring + 5th tab → Task 10; manual end-to-end confirmation → Task 11. All spec sections have a corresponding task.
- **Type consistency:** `AppThemeId`, `buildTheme`, `PastelColors`/`NeonColors`/`RetroColors`, `buildPastelTheme`/`buildNeonTheme`/`buildRetroTheme`, `MemphisDotGrid`/`NeonGridLines`/`RetroScanlines`, `decorationForTheme`, `ThemeNotifier`/`themeProvider` are each defined once and referenced identically by name across every later task that uses them.
- **Existing-test protection:** Task 8 explicitly requires the 5 pre-existing `PassageCard` test cases to keep passing unmodified alongside the 2 new ones — this is called out so the implementer doesn't accidentally weaken existing coverage while restructuring the widget tree.
- **iOS:** consistent with the original app plan, this can only be verified on Android in the current (Linux) environment; Task 11 flags this as a known, carried-over gap rather than skipping it silently.
