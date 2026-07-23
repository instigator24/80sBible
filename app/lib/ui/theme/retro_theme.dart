import 'package:flutter/material.dart';

/// Retro arcade/VHS palette: bold primary colors and a dark
/// checkerboard-floor background evoking an early-80s mall arcade, with
/// thick black borders on cards and cabinets.
class RetroColors {
  static const red = Color(0xFFFF3B30);
  static const blue = Color(0xFF0A84FF);
  static const yellow = Color(0xFFFFD60A);
  static const green = Color(0xFF34C759);
  static const magenta = Color(0xFFC4145A);
  static const teal = Color(0xFF14B8B0);
  static const cream = Color(0xFFFDF6E3);
  static const ink = Color(0xFF1C1C1E);
  static const arcadeFloor = Color(0xFF17181C);
}

ThemeData buildRetroTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: RetroColors.arcadeFloor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: RetroColors.magenta,
      brightness: Brightness.dark,
    ).copyWith(
      primary: RetroColors.magenta,
      secondary: RetroColors.teal,
      tertiary: RetroColors.yellow,
      surface: RetroColors.cream,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w900,
        color: RetroColors.yellow,
      ),
      bodyLarge: TextStyle(color: RetroColors.cream, height: 1.4),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: RetroColors.ink, width: 4),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: RetroColors.magenta,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: RetroColors.magenta,
      indicatorColor: RetroColors.teal,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? RetroColors.ink
              : Colors.white,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          color: states.contains(WidgetState.selected)
              ? RetroColors.ink
              : Colors.white,
        ),
      ),
    ),
  );
}
