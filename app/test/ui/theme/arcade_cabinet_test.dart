import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/arcade_cabinet.dart';

void main() {
  testWidgets('ArcadeMarquee shows the passed text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ArcadeMarquee(text: 'John 1:1-4')),
    );

    expect(find.text('John 1:1-4'), findsOneWidget);
  });

  testWidgets('ArcadeScreen renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ArcadeScreen(child: Text('verse text')),
      ),
    );

    expect(find.text('verse text'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ArcadeButton fires onPressed when tapped', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArcadeButton(
            key: const Key('test-arcade-button'),
            icon: Icons.star,
            color: Colors.red,
            tooltip: 'Test',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('test-arcade-button')));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('ArcadeCabinet composes marquee, screen, and controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArcadeCabinet(
            title: 'John 1:1-4',
            screenChild: const Text('verse text'),
            controls: [
              ArcadeButton(
                icon: Icons.star,
                color: Colors.red,
                tooltip: 'Test',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('John 1:1-4'), findsOneWidget);
    expect(find.text('verse text'), findsOneWidget);
    expect(find.byType(ArcadeButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
