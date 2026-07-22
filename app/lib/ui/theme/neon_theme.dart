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
