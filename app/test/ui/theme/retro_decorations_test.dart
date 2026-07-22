import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/retro_decorations.dart';

void main() {
  testWidgets('RetroScanlines renders without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 200, height: 100, child: RetroScanlines()),
      ),
    );

    expect(find.byType(RetroScanlines), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('RetroScanlinesPainter.shouldRepaint', () {
    test('returns true when lineSpacing changes', () {
      const a = RetroScanlinesPainter(lineSpacing: 6);
      const b = RetroScanlinesPainter(lineSpacing: 10);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('returns false when nothing changes', () {
      const a = RetroScanlinesPainter();
      const b = RetroScanlinesPainter();
      expect(a.shouldRepaint(b), isFalse);
    });
  });

  testWidgets('RetroCheckerboard renders without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 200, height: 100, child: RetroCheckerboard()),
      ),
    );

    expect(find.byType(RetroCheckerboard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('RetroCheckerboardPainter.shouldRepaint', () {
    test('returns true when squareSize changes', () {
      const a = RetroCheckerboardPainter(squareSize: 24);
      const b = RetroCheckerboardPainter(squareSize: 32);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('returns false when nothing changes', () {
      const a = RetroCheckerboardPainter();
      const b = RetroCheckerboardPainter();
      expect(a.shouldRepaint(b), isFalse);
    });
  });
}
