import 'package:flutter/material.dart';

import 'neon_theme.dart';
import 'pastel_theme.dart';
import 'retro_theme.dart';

enum AppThemeId { pastel, neon, retroArcade }

ThemeData buildTheme(AppThemeId id) {
  switch (id) {
    case AppThemeId.pastel:
      return buildPastelTheme();
    case AppThemeId.neon:
      return buildNeonTheme();
    case AppThemeId.retroArcade:
      return buildRetroTheme();
  }
}
