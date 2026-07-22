import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/app_theme.dart';
import 'package:slang_bible/ui/theme/pastel_theme.dart';

void main() {
  group('buildTheme', () {
    test('pastel id returns the pastel theme', () {
      final theme = buildTheme(AppThemeId.pastel);
      expect(theme.scaffoldBackgroundColor, PastelColors.background);
    });

    test('each AppThemeId value produces a distinct scaffoldBackgroundColor', () {
      final colors = AppThemeId.values.map((id) => buildTheme(id).scaffoldBackgroundColor).toSet();
      expect(colors.length, AppThemeId.values.length);
    });
  });
}
