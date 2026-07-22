import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/logic/theme_provider.dart';
import 'package:slang_bible/ui/settings/settings_screen.dart';
import 'package:slang_bible/ui/theme/app_theme.dart';

Future<ProviderContainer> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
    ),
  );

  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('lists all three themes with the current one checked',
      (tester) async {
    await _pump(tester);

    expect(find.text('Preppy Pastel'), findsOneWidget);
    expect(find.text('Neon Synthwave'), findsOneWidget);
    expect(find.text('Retro Arcade'), findsOneWidget);
    expect(find.byKey(const Key('theme-selected-check')), findsOneWidget);
  });

  testWidgets('tapping a theme updates themeProvider', (tester) async {
    final container = await _pump(tester);

    await tester.tap(find.byKey(const Key('theme-option-neon')));
    await tester.pump();

    expect(container.read(themeProvider), AppThemeId.neon);
  });

  testWidgets('shows a color swatch preview for each theme', (tester) async {
    await _pump(tester);

    expect(find.byKey(const Key('theme-swatch-pastel')), findsOneWidget);
    expect(find.byKey(const Key('theme-swatch-neon')), findsOneWidget);
    expect(find.byKey(const Key('theme-swatch-retroArcade')), findsOneWidget);
  });
}
