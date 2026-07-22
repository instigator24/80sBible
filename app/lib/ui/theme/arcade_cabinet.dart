import 'package:flutter/material.dart';

import 'retro_decorations.dart';
import 'retro_theme.dart';

/// Cream marquee panel showing the passage reference atop the cabinet.
class ArcadeMarquee extends StatelessWidget {
  final String text;

  const ArcadeMarquee({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: const BoxDecoration(
        color: RetroColors.cream,
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 3),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: RetroColors.ink,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// The CRT-style screen showing verse text, bezel included, with a subtle
/// scanline overlay.
class ArcadeScreen extends StatelessWidget {
  final Widget child;

  const ArcadeScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3C),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: const Color(0xFF101820),
              child: child,
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: RetroScanlines(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round arcade-style push button used in the control deck.
class ArcadeButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const ArcadeButton({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Icon(icon, color: RetroColors.ink, size: 20),
        ),
      ),
    );
  }
}

/// Decorative joystick, purely visual (not wired to any action). Built as a
/// bottom-anchored stack of overlapping shapes (base, stick, ball) so each
/// piece visibly connects to the next rather than floating apart.
class ArcadeJoystick extends StatelessWidget {
  const ArcadeJoystick({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 38,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 24,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.black,
                border: Border.all(color: const Color(0xFF444444), width: 2),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            child: Container(width: 5, height: 20, color: const Color(0xFF888888)),
          ),
          Positioned(
            bottom: 20,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: RetroColors.red,
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dark control-deck panel holding the decorative joystick and the
/// row of arcade buttons.
class ArcadeControlDeck extends StatelessWidget {
  final List<Widget> children;

  const ArcadeControlDeck({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3C),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const ArcadeJoystick(),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: children,
          ),
        ],
      ),
    );
  }
}

/// The full cabinet shell wrapping a marquee, screen, and control deck.
class ArcadeCabinet extends StatelessWidget {
  final String title;
  final Widget screenChild;
  final List<Widget> controls;

  const ArcadeCabinet({
    super.key,
    required this.title,
    required this.screenChild,
    required this.controls,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RetroColors.yellow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RetroColors.red, width: 4),
      ),
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(7),
            ),
            child: ArcadeMarquee(text: title),
          ),
          const SizedBox(height: 8),
          ArcadeScreen(child: screenChild),
          const SizedBox(height: 10),
          ArcadeControlDeck(children: controls),
        ],
      ),
    );
  }
}
