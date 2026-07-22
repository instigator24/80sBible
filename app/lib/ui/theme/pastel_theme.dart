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
