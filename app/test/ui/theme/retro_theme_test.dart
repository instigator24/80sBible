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

    test(
        'navigation bar label text has an explicit compact font size '
        '(regression: omitting fontSize made the 6-tab bar overflow)', () {
      final theme = buildRetroTheme();
      final selectedStyle = theme.navigationBarTheme.labelTextStyle!
          .resolve({WidgetState.selected})!;
      final unselectedStyle =
          theme.navigationBarTheme.labelTextStyle!.resolve({})!;

      expect(selectedStyle.fontSize, isNotNull);
      expect(selectedStyle.fontSize, lessThanOrEqualTo(12));
      expect(unselectedStyle.fontSize, isNotNull);
      expect(unselectedStyle.fontSize, lessThanOrEqualTo(12));
    });
  });
}
