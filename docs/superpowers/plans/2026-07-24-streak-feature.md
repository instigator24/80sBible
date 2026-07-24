# Daily Streak Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a daily reading streak (current + longest, persisted locally) with a Home screen badge, an app-wide AppBar indicator, and an animated milestone celebration at 3/7/14/30/60/100/365 days.

**Architecture:** A `StreakNotifier` (Riverpod `Notifier`, same shape as the existing `BookmarksNotifier`) persists `current`/`longest`/`lastReadDate` via `SharedPreferences` and exposes `recordAppOpen(DateTime now)`, called once per launch from `RootShell.initState`. A shared `StreakBadge` widget reads the provider and is used both on `HomeScreen` and in `RootShell`'s `AppBar`. A `StreakMilestoneOverlay`, shown via `showGeneralDialog`, celebrates milestone days.

**Tech Stack:** Flutter (Dart), Riverpod, `shared_preferences` (all already in `pubspec.yaml` — no new dependencies).

**Reference spec:** `docs/superpowers/specs/2026-07-24-streak-feature-design.md`

---

### Task 1: `StreakNotifier` / `streakProvider`

**Files:**
- Create: `app/lib/logic/streak_provider.dart`
- Test: `app/test/logic/streak_provider_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/logic/streak_provider.dart';

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

  group('streakProvider', () {
    test('starts at 0/0 with no stored streak', () async {
      final container = await makeContainer();
      final state = container.read(streakProvider);
      expect(state.current, 0);
      expect(state.longest, 0);
      expect(state.lastReadDate, isNull);
    });

    test('first-ever open sets current to 1, no milestone', () async {
      final container = await makeContainer();
      final milestone = await container
          .read(streakProvider.notifier)
          .recordAppOpen(DateTime(2026, 7, 1));

      expect(milestone, isNull);
      final state = container.read(streakProvider);
      expect(state.current, 1);
      expect(state.longest, 1);
      expect(state.lastReadDate, DateTime(2026, 7, 1));
    });

    test('opening again the same day is a no-op', () async {
      final container = await makeContainer();
      final notifier = container.read(streakProvider.notifier);
      await notifier.recordAppOpen(DateTime(2026, 7, 1));
      final milestone = await notifier.recordAppOpen(DateTime(2026, 7, 1, 22));

      expect(milestone, isNull);
      expect(container.read(streakProvider).current, 1);
    });

    test('opening the next day increments the streak', () async {
      final container = await makeContainer();
      final notifier = container.read(streakProvider.notifier);
      await notifier.recordAppOpen(DateTime(2026, 7, 1));
      await notifier.recordAppOpen(DateTime(2026, 7, 2));

      expect(container.read(streakProvider).current, 2);
      expect(container.read(streakProvider).longest, 2);
    });

    test('missing a day resets current but keeps the longest', () async {
      final container = await makeContainer();
      final notifier = container.read(streakProvider.notifier);
      await notifier.recordAppOpen(DateTime(2026, 7, 1));
      await notifier.recordAppOpen(DateTime(2026, 7, 2));
      await notifier.recordAppOpen(DateTime(2026, 7, 2));
      await notifier.recordAppOpen(DateTime(2026, 7, 5));

      final state = container.read(streakProvider);
      expect(state.current, 1);
      expect(state.longest, 2);
    });

    test('persists across container rebuilds', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container1 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      await container1
          .read(streakProvider.notifier)
          .recordAppOpen(DateTime(2026, 7, 1));
      container1.dispose();

      final container2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container2.dispose);
      expect(container2.read(streakProvider).current, 1);
    });

    for (final day in kStreakMilestones) {
      test('returns milestone $day on the day the streak reaches it', () async {
        final container = await makeContainer();
        final notifier = container.read(streakProvider.notifier);
        int? lastMilestone;
        for (var i = 0; i < day; i++) {
          lastMilestone =
              await notifier.recordAppOpen(DateTime(2026, 1, 1 + i));
        }
        expect(lastMilestone, day);
        expect(container.read(streakProvider).current, day);
      });
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd app && flutter test test/logic/streak_provider_test.dart`
Expected: FAIL — `Error: Error when reading 'lib/logic/streak_provider.dart': No such file or directory` (or `Type 'streakProvider' not found`)

- [ ] **Step 3: Write the provider**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bookmarks_provider.dart' show sharedPreferencesProvider;

const _currentKey = 'streak_current';
const _longestKey = 'streak_longest';
const _lastDateKey = 'streak_last_date';

const kStreakMilestones = [3, 7, 14, 30, 60, 100, 365];

class StreakState {
  final int current;
  final int longest;
  final DateTime? lastReadDate;

  const StreakState({
    required this.current,
    required this.longest,
    required this.lastReadDate,
  });
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

String _formatDate(DateTime dt) {
  final d = _dateOnly(dt);
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

class StreakNotifier extends Notifier<StreakState> {
  @override
  StreakState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final rawDate = prefs.getString(_lastDateKey);
    return StreakState(
      current: prefs.getInt(_currentKey) ?? 0,
      longest: prefs.getInt(_longestKey) ?? 0,
      lastReadDate: rawDate == null ? null : DateTime.parse(rawDate),
    );
  }

  /// Records that the app was opened at [now]. Returns the milestone day
  /// count if this open just reached one of [kStreakMilestones], else null.
  Future<int?> recordAppOpen(DateTime now) async {
    final today = _dateOnly(now);
    final last = state.lastReadDate;

    if (last != null && last == today) {
      return null;
    }

    final isConsecutive = last != null && today.difference(last).inDays == 1;
    final nextCurrent = isConsecutive ? state.current + 1 : 1;
    final nextLongest = nextCurrent > state.longest ? nextCurrent : state.longest;

    state = StreakState(
      current: nextCurrent,
      longest: nextLongest,
      lastReadDate: today,
    );

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_currentKey, nextCurrent);
    await prefs.setInt(_longestKey, nextLongest);
    await prefs.setString(_lastDateKey, _formatDate(today));

    return kStreakMilestones.contains(nextCurrent) ? nextCurrent : null;
  }
}

final streakProvider = NotifierProvider<StreakNotifier, StreakState>(
  StreakNotifier.new,
);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd app && flutter test test/logic/streak_provider_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add app/lib/logic/streak_provider.dart app/test/logic/streak_provider_test.dart
git commit -m "Add StreakNotifier for daily reading streak tracking"
```

---

### Task 2: `StreakBadge` widget

**Files:**
- Create: `app/lib/ui/home/streak_badge.dart`
- Test: `app/test/ui/home/streak_badge_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/ui/home/streak_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester, {int current = 0}) async {
    SharedPreferences.setMockInitialValues({'streak_current': current});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          home: Scaffold(body: StreakBadge(key: Key('badge'))),
        ),
      ),
    );
  }

  testWidgets('shows the current streak count', (tester) async {
    await pump(tester, current: 5);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('shows 0 when there is no stored streak', (tester) async {
    await pump(tester, current: 0);
    expect(find.text('0'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd app && flutter test test/ui/home/streak_badge_test.dart`
Expected: FAIL — `Error: Error when reading 'lib/ui/home/streak_badge.dart'` (file doesn't exist yet)

- [ ] **Step 3: Write the widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/streak_provider.dart';

/// Shows the current reading streak as a flame + day count. Used both on
/// [HomeScreen] (full size) and in `RootShell`'s AppBar ([compact]).
class StreakBadge extends ConsumerWidget {
  final bool compact;

  const StreakBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final style = compact
        ? Theme.of(context).textTheme.bodyMedium
        : Theme.of(context).textTheme.titleMedium;

    return Semantics(
      label: '${streak.current} day streak',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥'),
          const SizedBox(width: 4),
          Text('${streak.current}', style: style),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd app && flutter test test/ui/home/streak_badge_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add app/lib/ui/home/streak_badge.dart app/test/ui/home/streak_badge_test.dart
git commit -m "Add StreakBadge widget"
```

---

### Task 3: `StreakMilestoneOverlay`

**Files:**
- Create: `app/lib/ui/home/streak_milestone_overlay.dart`
- Test: `app/test/ui/home/streak_milestone_overlay_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/home/streak_milestone_overlay.dart';

void main() {
  Future<void> pumpAndOpen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showStreakMilestoneOverlay(context, 7),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the milestone day count', (tester) async {
    await pumpAndOpen(tester);
    expect(find.text('🔥 7-Day Streak!'), findsOneWidget);
  });

  testWidgets('dismisses on tap', (tester) async {
    await pumpAndOpen(tester);
    expect(find.byKey(const Key('streak-milestone-overlay')), findsOneWidget);

    await tester.tap(find.byKey(const Key('streak-milestone-overlay')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('streak-milestone-overlay')), findsNothing);
  });

  testWidgets('auto-dismisses after 3 seconds', (tester) async {
    await pumpAndOpen(tester);
    expect(find.byKey(const Key('streak-milestone-overlay')), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('streak-milestone-overlay')), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd app && flutter test test/ui/home/streak_milestone_overlay_test.dart`
Expected: FAIL — `Error: Error when reading 'lib/ui/home/streak_milestone_overlay.dart'` (file doesn't exist yet)

- [ ] **Step 3: Write the widget**

```dart
import 'dart:math';

import 'package:flutter/material.dart';

/// Shows a full-screen celebration overlay for a streak milestone. Auto-
/// dismisses after 3 seconds, or immediately on tap.
Future<void> showStreakMilestoneOverlay(BuildContext context, int days) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Streak milestone',
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (context, _, _) => StreakMilestoneOverlay(days: days),
  );
}

class StreakMilestoneOverlay extends StatefulWidget {
  final int days;

  const StreakMilestoneOverlay({super.key, required this.days});

  @override
  State<StreakMilestoneOverlay> createState() =>
      _StreakMilestoneOverlayState();
}

class _StreakMilestoneOverlayState extends State<StreakMilestoneOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildParticle(ThemeData theme, int index) {
    const particleCount = 8;
    final angle = (pi * 2 / particleCount) * index;
    final distance = 80.0 * _controller.value;
    return Transform.translate(
      offset: Offset(cos(angle) * distance, sin(angle) * distance),
      child: Opacity(
        opacity: 1 - _controller.value,
        child: Icon(Icons.star, color: theme.colorScheme.primary, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      key: const Key('streak-milestone-overlay'),
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Material(
        color: theme.colorScheme.scrim.withValues(alpha: 0.85),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Stack(
              alignment: Alignment.center,
              children: [
                for (var i = 0; i < 8; i++) _buildParticle(theme, i),
                Opacity(
                  opacity: _controller.value,
                  child: Text(
                    '🔥 ${widget.days}-Day Streak!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd app && flutter test test/ui/home/streak_milestone_overlay_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add app/lib/ui/home/streak_milestone_overlay.dart app/test/ui/home/streak_milestone_overlay_test.dart
git commit -m "Add StreakMilestoneOverlay celebration widget"
```

---

### Task 4: Wire `StreakBadge` into `HomeScreen`

**Files:**
- Modify: `app/lib/ui/home/home_screen.dart`
- Modify: `app/test/ui/home/home_screen_test.dart`

- [ ] **Step 1: Update the test's `pump` helper to accept initial prefs, add a failing test**

Replace the whole `home_screen_test.dart` file:

```dart
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

  Future<void> pump(
    WidgetTester tester, {
    String? Function(String, int)? onOpen,
    Map<String, Object> initialPrefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              repository: repo,
              today: DateTime.utc(2026, 7, 22),
              onOpenPassage: onOpen ?? (_, _) {},
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

  testWidgets('shows the current streak badge', (tester) async {
    await pump(tester, initialPrefs: {'streak_current': 4});
    expect(find.byKey(const Key('home-streak-badge')), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('tapping the verse of the day card calls onOpenPassage', (tester) async {
    String? openedBook;
    int? openedChapter;

    await pump(
      tester,
      onOpen: (book, chapter) {
        openedBook = book;
        openedChapter = chapter;
        return null;
      },
    );

    await tester.tap(find.byKey(const Key('verse-of-the-day-card')));
    await tester.pump();

    expect(openedBook, 'John');
    expect(openedChapter, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd app && flutter test test/ui/home/home_screen_test.dart`
Expected: FAIL on the new "shows the current streak badge" test — `key 'home-streak-badge' not found`

- [ ] **Step 3: Add the badge to `HomeScreen`**

In `app/lib/ui/home/home_screen.dart`, add the import:

```dart
import 'package:flutter/material.dart';

import '../../data/passage_repository.dart';
import '../../logic/verse_of_the_day.dart';
import '../reader/passage_card.dart';
import 'streak_badge.dart';
import 'support_card.dart';
```

Change the `Column`'s `children` from:

```dart
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
          const SupportCard(),
        ],
```

to:

```dart
        children: [
          Text(
            'Verse of the Day',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const StreakBadge(key: Key('home-streak-badge')),
          const SizedBox(height: 12),
          GestureDetector(
            key: const Key('verse-of-the-day-card'),
            onTap: () => onOpenPassage(verse.book, verse.chapter),
            child: PassageCard(passage: verse),
          ),
          const SupportCard(),
        ],
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd app && flutter test test/ui/home/home_screen_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add app/lib/ui/home/home_screen.dart app/test/ui/home/home_screen_test.dart
git commit -m "Show StreakBadge on the Home screen"
```

---

### Task 5: Wire streak recording + AppBar indicator + milestone overlay into `RootShell`

**Files:**
- Modify: `app/lib/main.dart`
- Test: `app/test/root_shell_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/data/passage_repository.dart';
import 'package:slang_bible/data/story_repository.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('records a streak day on open and shows it in the AppBar',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: RootShell(
            repository: PassageRepository.fromJsonList([]),
            storyRepository: StoryRepository.fromJsonList([]),
            today: DateTime(2026, 7, 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appbar-streak-badge')), findsOneWidget);
    // Scoped to the AppBar badge specifically: RootShell's IndexedStack keeps
    // every tab (including Home, which has its own StreakBadge) mounted at
    // once, so an unscoped find.text('1') would match both.
    expect(
      find.descendant(
        of: find.byKey(const Key('appbar-streak-badge')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the milestone overlay on the 3rd consecutive day',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'streak_current': 2,
      'streak_longest': 2,
      'streak_last_date': '2026-07-01',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: RootShell(
            repository: PassageRepository.fromJsonList([]),
            storyRepository: StoryRepository.fromJsonList([]),
            today: DateTime(2026, 7, 2),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('streak-milestone-overlay')), findsOneWidget);
    expect(find.text('🔥 3-Day Streak!'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd app && flutter test test/root_shell_test.dart`
Expected: FAIL — `The named parameter 'today' isn't defined` (or the AppBar/overlay finders fail)

- [ ] **Step 3: Update `RootShell` in `main.dart`**

Add the imports (alongside the existing ones):

```dart
import 'logic/streak_provider.dart';
import 'ui/home/streak_badge.dart';
import 'ui/home/streak_milestone_overlay.dart';
```

Change the `RootShell` class from:

```dart
class RootShell extends ConsumerStatefulWidget {
  final PassageRepository repository;
  final StoryRepository storyRepository;

  const RootShell({
    super.key,
    required this.repository,
    required this.storyRepository,
  });

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}
```

to:

```dart
class RootShell extends ConsumerStatefulWidget {
  final PassageRepository repository;
  final StoryRepository storyRepository;
  final DateTime? today;

  const RootShell({
    super.key,
    required this.repository,
    required this.storyRepository,
    this.today,
  });

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}
```

Add `initState` and a `_recordAppOpen` helper to `_RootShellState`, right after the `_tabIndex`/`_pendingBook`/`_pendingChapter`/`_navSeq` field declarations:

```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordAppOpen());
  }

  Future<void> _recordAppOpen() async {
    final milestone = await ref
        .read(streakProvider.notifier)
        .recordAppOpen(widget.today ?? DateTime.now());
    if (milestone != null && mounted) {
      await showStreakMilestoneOverlay(context, milestone);
    }
  }
```

Change the `Scaffold`'s `appBar` from:

```dart
      appBar: AppBar(title: const Text("80's Bible")),
```

to:

```dart
      appBar: AppBar(
        title: const Text("80's Bible"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: StreakBadge(
                key: Key('appbar-streak-badge'),
                compact: true,
              ),
            ),
          ),
        ],
      ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd app && flutter test test/root_shell_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add app/lib/main.dart app/test/root_shell_test.dart
git commit -m "Record streak on app open, add AppBar indicator and milestone overlay"
```

---

### Task 6: Full verification

**Files:** none (verification only)

- [ ] **Step 1: Run the full test suite**

Run: `cd app && flutter test`
Expected: `All tests passed!` (no failures; the one pre-existing skipped share-image test is expected, per `test/ui/reader/passage_card_test.dart`'s documented `skipShareImageTest` flag)

- [ ] **Step 2: Run `flutter analyze`**

Run: `cd app && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Manually verify in a running app (emulator or device)**

Launch the app and confirm:
- The Home screen shows a `🔥` streak badge below "Verse of the Day".
- The AppBar shows a smaller streak badge on every tab.
- Force-quitting and relaunching the app on a later date increments the streak (can simulate by editing the device clock, or trust the unit-tested logic from Task 1).
- The milestone overlay is not expected to appear on a fresh install (streak starts at 1, first milestone is day 3) — this is fine, it's already covered by the `root_shell_test.dart` widget test.

- [ ] **Step 4: Commit** (only if Step 3 uncovered fixes; otherwise this task has no commit)
