import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/logic/theme_provider.dart';
import 'package:slang_bible/ui/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer(
      {Map<String, Object> initial = const {}}) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('themeProvider', () {
    test('defaults to pastel when nothing is stored', () async {
      final container = await makeContainer();
      expect(container.read(themeProvider), AppThemeId.pastel);
    });

    test('hydrates from a previously stored theme id', () async {
      final container = await makeContainer(initial: {'app_theme_id': 'neon'});
      expect(container.read(themeProvider), AppThemeId.neon);
    });

    test('falls back to pastel on an unrecognized stored value', () async {
      final container =
          await makeContainer(initial: {'app_theme_id': 'not_a_real_theme'});
      expect(container.read(themeProvider), AppThemeId.pastel);
    });

    test('select() updates state and persists the choice', () async {
      final container = await makeContainer();
      await container.read(themeProvider.notifier).select(AppThemeId.retroArcade);

      expect(container.read(themeProvider), AppThemeId.retroArcade);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_id'), 'retroArcade');
    });
  });
}
