# Daily Streak Feature — Design

## Problem

The app has no mechanic to encourage daily return visits. We want a simple
"reading streak" — a running count of consecutive days the app has been
opened — to give users a habit hook, similar to Duolingo/Snapchat-style
streaks.

## Goals

- Track a current streak (consecutive days opened) and a longest streak
  (all-time record).
- A day counts as "read" simply by opening the app (the Home screen's
  existing Verse of the Day is visible immediately on open, so no separate
  in-app action is required).
- Any missed day resets the current streak to 0 (strict, no grace period).
- Show the current streak on the Home screen and in a persistent app-wide
  indicator.
- Celebrate streak milestones (3, 7, 14, 30, 60, 100, 365 days) with a
  themed animated overlay.

## Non-Goals

- No calendar/history view of past reading days.
- No server sync — purely local, per-device state via `SharedPreferences`.
- No grace days / weekly leniency — a missed day is a reset, full stop.
- No per-theme bespoke celebration art — the overlay adapts via
  `Theme.of(context)` colors rather than needing 4 custom designs (one per
  app theme).

## Data Model & Persistence

`StreakState`:
```dart
class StreakState {
  final int current;
  final int longest;
  final DateTime? lastReadDate; // date-only, no time component
}
```

Persisted in `SharedPreferences` under three keys:
- `streak_current` (int)
- `streak_longest` (int)
- `streak_last_date` (String, `yyyy-MM-dd`)

## `StreakNotifier`

A Riverpod `Notifier<StreakState>`, following the same shape as the
existing `BookmarksNotifier` (`lib/logic/bookmarks_provider.dart`):

- `build()` reads the three persisted values and returns the initial
  `StreakState`.
- `recordAppOpen(DateTime now)` — called exactly once per app launch, from
  `RootShell.initState`. Logic:
  1. Normalize `now` to date-only (drop time-of-day).
  2. If `lastReadDate == today`: no-op; return `null` (already recorded
     today, e.g. hot restart during dev).
  3. If `lastReadDate == yesterday`: `current += 1`.
  4. Otherwise (no prior date, or any gap other than exactly one day —
     including a clock going backwards): `current = 1`.
  5. `longest = max(longest, current)`.
  6. Persist all three values; set `lastReadDate = today`.
  7. If this call changed the streak (i.e. wasn't the same-day no-op from
     step 2) and the new `current` is one of `{3, 7, 14, 30, 60, 100,
     365}`, return that milestone number; otherwise return `null`.

Because `recordAppOpen` only runs once at startup rather than on every
rebuild, a returned milestone is naturally a one-shot signal for that
session — no separate "already celebrated" flag is needed.

`RootShell` gains an optional `today` constructor parameter (mirroring the
pattern `HomeScreen` already uses) so tests can drive specific date
sequences without mocking `DateTime.now()`.

## UI

**`StreakBadge`** — a small reusable widget (`🔥 {n}-day streak`) that reads
`streakProvider`. Used in two places:
- `HomeScreen`: placed between the "Verse of the Day" heading and its card.
  `HomeScreen` becomes a `ConsumerWidget` to read the provider.
- `RootShell`'s `AppBar`: added to `actions`, visible on every tab
  regardless of which screen is active.

Both call sites read the same `streakProvider` — no duplicated streak
logic, just two presentational usages of one small widget.

**`StreakMilestoneOverlay`** — shown via `showGeneralDialog` (full-screen,
barrier-dismissible) when `recordAppOpen` returns a non-null milestone.
Content: large `"🔥 {n}-Day Streak!"` text plus a lightweight
particle/confetti burst built with `AnimatedBuilder` and a handful of
animated `Positioned` icons — no external animation package, consistent
with the rest of the app's dependency footprint. Colors come from
`Theme.of(context)` so it adapts to whichever of the four themes
(neon/pastel/retro/arcade) is active. Auto-dismisses after ~3 seconds or on
tap.

Triggering: `RootShell.initState` calls
`ref.read(streakProvider.notifier).recordAppOpen(...)`. If it returns a
milestone, the overlay is scheduled via
`WidgetsBinding.instance.addPostFrameCallback` so it displays after the
first frame (avoiding showing a dialog mid-`initState`).

## Testing

- `streak_provider_test.dart`: unit tests on `StreakNotifier.recordAppOpen`
  using `SharedPreferences.setMockInitialValues` and fixed `DateTime`
  values. Covers: first-ever open (→ 1, no milestone), consecutive-day
  open (→ increment), same-day repeat (no-op), a gap of 2+ days (→ reset to
  1), longest-streak surviving a reset, and each milestone value returned
  exactly on its triggering call.
- Widget tests for `StreakBadge` (renders the count from a given state)
  and `StreakMilestoneOverlay` (shows the right text, dismisses on tap).
- A `RootShell` widget test drives a multi-day sequence via the injected
  `today` param and asserts the milestone overlay appears exactly once at
  the right threshold.

## Edge Cases

- **Clock rollback / bad device clock:** a `lastReadDate` that's in the
  future relative to "now", or any gap other than exactly +1 day, falls
  into the reset branch — no special-casing needed since reset is already
  the safe default for any non-consecutive-day delta.
- **Timezone changes:** normalizing to date-only from local
  `DateTime.now()` means someone crossing timezones could see a doubled or
  skipped day. Not worth solving given the scope of this feature.
- **App reinstall / cleared storage:** `SharedPreferences` empty →
  `lastReadDate == null` → treated as a first-ever open (`current = 1`).
