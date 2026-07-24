import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/ui/home/streak_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester, {int current = 0}) async {
    SharedPreferences.setMockInitialValues({'streak_current': current});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          home: Scaffold(body: StreakBadge(key: Key('badge'))),
        ),
      ),
    );
  }

  testWidgets('shows the current streak count', (tester) async {
    await pump(tester, current: 5);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('shows 0 when there is no stored streak', (tester) async {
    await pump(tester, current: 0);
    expect(find.text('0'), findsOneWidget);
  });
}
