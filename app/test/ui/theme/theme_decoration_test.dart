import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/app_theme.dart';
import 'package:slang_bible/ui/theme/memphis_decorations.dart';
import 'package:slang_bible/ui/theme/neon_decorations.dart';
import 'package:slang_bible/ui/theme/retro_decorations.dart';
import 'package:slang_bible/ui/theme/theme_decoration.dart';

void main() {
  group('decorationForTheme', () {
    test('pastel maps to MemphisDotGrid', () {
      expect(decorationForTheme(AppThemeId.pastel), isA<MemphisDotGrid>());
    });

    test('neon maps to NeonGridLines', () {
      expect(decorationForTheme(AppThemeId.neon), isA<NeonGridLines>());
    });

    test('retroArcade maps to RetroScanlines', () {
      expect(decorationForTheme(AppThemeId.retroArcade), isA<RetroScanlines>());
    });
  });
}
