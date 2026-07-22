import 'package:flutter/material.dart';

import 'neon_theme.dart';

class NeonGridLinesPainter extends CustomPainter {
  final Color color;
  final double spacing;

  const NeonGridLinesPainter({
    this.color = NeonColors.cyan,
    this.spacing = 24,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant NeonGridLinesPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.spacing != spacing;
}

/// A glowing grid-line background evoking the synthwave/neon aesthetic.
class NeonGridLines extends StatelessWidget {
  final double spacing;

  const NeonGridLines({super.key, this.spacing = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: NeonGridLinesPainter(spacing: spacing));
  }
}
