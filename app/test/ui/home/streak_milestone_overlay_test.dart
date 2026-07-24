import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/home/streak_milestone_overlay.dart';

void main() {
  Future<void> pumpAndOpen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showStreakMilestoneOverlay(context, 7),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the milestone day count', (tester) async {
    await pumpAndOpen(tester);
    expect(find.text('🔥 7-Day Streak!'), findsOneWidget);
  });

  testWidgets('dismisses on tap', (tester) async {
    await pumpAndOpen(tester);
    expect(find.byKey(const Key('streak-milestone-overlay')), findsOneWidget);

    await tester.tap(find.byKey(const Key('streak-milestone-overlay')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('streak-milestone-overlay')), findsNothing);
  });

  testWidgets('auto-dismisses after 3 seconds', (tester) async {
    await pumpAndOpen(tester);
    expect(find.byKey(const Key('streak-milestone-overlay')), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('streak-milestone-overlay')), findsNothing);
  });
}
