import 'package:flutter/material.dart';

import 'pastel_theme.dart';

class MemphisDotGridPainter extends CustomPainter {
  final Color color;
  final double dotRadius;
  final double spacing;

  const MemphisDotGridPainter({
    this.color = PastelColors.ink,
    this.dotRadius = 2,
    this.spacing = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.35);
    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MemphisDotGridPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dotRadius != dotRadius ||
      oldDelegate.spacing != spacing;
}

/// A decorative dot-grid background, used behind cards/headers to add the
/// Memphis-design texture called for in the 80s theme.
class MemphisDotGrid extends StatelessWidget {
  final double dotRadius;
  final double spacing;

  const MemphisDotGrid({super.key, this.dotRadius = 2, this.spacing = 16});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MemphisDotGridPainter(dotRadius: dotRadius, spacing: spacing),
    );
  }
}
