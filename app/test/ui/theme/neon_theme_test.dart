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
