import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/pastel_theme.dart';

void main() {
  group('buildPastelTheme', () {
    test('uses the pastel background and lavender primary color', () {
      final theme = buildPastelTheme();
      expect(theme.scaffoldBackgroundColor, PastelColors.background);
      expect(theme.colorScheme.primary, PastelColors.lavender);
      expect(theme.colorScheme.secondary, PastelColors.mint);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('card theme has rounded corners and an ink border', () {
      final theme = buildPastelTheme();
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(20));
      expect((shape.side.color), PastelColors.ink);
    });
  });
}
