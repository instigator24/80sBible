import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_bible/ui/theme/memphis_decorations.dart';

void main() {
  testWidgets('MemphisDotGrid renders without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 200,
          height: 100,
          child: MemphisDotGrid(),
        ),
      ),
    );

    expect(find.byType(MemphisDotGrid), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('MemphisDotGridPainter.shouldRepaint', () {
    test('returns true when spacing changes', () {
      const a = MemphisDotGridPainter(spacing: 16);
      const b = MemphisDotGridPainter(spacing: 24);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('returns false when nothing changes', () {
      const a = MemphisDotGridPainter();
      const b = MemphisDotGridPainter();
      expect(a.shouldRepaint(b), isFalse);
    });
  });
}
