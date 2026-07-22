import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/retro_theme.dart';

void main() {
  group('buildRetroTheme', () {
    test('uses a dark arcade-floor background and magenta primary color', () {
      final theme = buildRetroTheme();
      expect(theme.scaffoldBackgroundColor, RetroColors.arcadeFloor);
      expect(theme.colorScheme.primary, RetroColors.magenta);
      expect(theme.colorScheme.secondary, RetroColors.teal);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('card theme has a chunky ink border', () {
      final theme = buildRetroTheme();
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.side.width, 4);
      expect(shape.side.color, RetroColors.ink);
    });
  });
}
