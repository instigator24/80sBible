import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/neon_decorations.dart';

void main() {
  testWidgets('NeonGridLines renders without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 200, height: 100, child: NeonGridLines()),
      ),
    );

    expect(find.byType(NeonGridLines), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('NeonGridLinesPainter.shouldRepaint', () {
    test('returns true when spacing changes', () {
      const a = NeonGridLinesPainter(spacing: 24);
      const b = NeonGridLinesPainter(spacing: 32);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('returns false when nothing changes', () {
      const a = NeonGridLinesPainter();
      const b = NeonGridLinesPainter();
      expect(a.shouldRepaint(b), isFalse);
    });
  });
}
