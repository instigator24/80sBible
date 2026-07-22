import 'package:flutter/material.dart';

import 'retro_theme.dart';

class RetroScanlinesPainter extends CustomPainter {
  final Color color;
  final double lineSpacing;
  final double lineThickness;

  const RetroScanlinesPainter({
    this.color = RetroColors.ink,
    this.lineSpacing = 6,
    this.lineThickness = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.2);
    for (double y = 0; y < size.height; y += lineSpacing) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, lineThickness), paint);
    }
  }

  @override
  bool shouldRepaint(covariant RetroScanlinesPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.lineSpacing != lineSpacing ||
      oldDelegate.lineThickness != lineThickness;
}

/// A horizontal scanline texture evoking a CRT/VHS look.
class RetroScanlines extends StatelessWidget {
  final Color color;
  final double lineSpacing;
  final double lineThickness;

  const RetroScanlines({
    super.key,
    this.color = RetroColors.ink,
    this.lineSpacing = 6,
    this.lineThickness = 1,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RetroScanlinesPainter(
        color: color,
        lineSpacing: lineSpacing,
        lineThickness: lineThickness,
      ),
    );
  }
}

class RetroCheckerboardPainter extends CustomPainter {
  final Color color;
  final double squareSize;

  const RetroCheckerboardPainter({
    this.color = Colors.white,
    this.squareSize = 24,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.06);
    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final col = (x / squareSize).floor();
        final row = (y / squareSize).floor();
        if ((col + row).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, squareSize, squareSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant RetroCheckerboardPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.squareSize != squareSize;
}

/// A dark checkerboard-floor texture evoking an early-80s mall arcade
/// entrance, used behind the app's retro-theme screens.
class RetroCheckerboard extends StatelessWidget {
  final Color color;
  final double squareSize;

  const RetroCheckerboard({
    super.key,
    this.color = Colors.white,
    this.squareSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RetroCheckerboardPainter(color: color, squareSize: squareSize),
    );
  }
}
