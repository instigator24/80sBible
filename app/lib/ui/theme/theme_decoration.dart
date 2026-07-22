import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'memphis_decorations.dart';
import 'neon_decorations.dart';
import 'retro_decorations.dart';

/// Returns the decorative background widget for the given theme, so each
/// theme carries a distinct visual motif (not just distinct colors). Used
/// behind individual cards.
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

/// Returns the decorative background widget used behind entire screens
/// (the root app shell), so each theme's whole-page background carries the
/// same motif as its cards, not just a flat color.
Widget rootBackgroundForTheme(AppThemeId id) {
  switch (id) {
    case AppThemeId.pastel:
      return const MemphisDotGrid();
    case AppThemeId.neon:
      return const NeonGridLines();
    case AppThemeId.retroArcade:
      return const RetroCheckerboard();
  }
}
