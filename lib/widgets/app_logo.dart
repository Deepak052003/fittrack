import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// App logo: a coral dumbbell on navy (same as the PWA icons).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C2541), obsidian],
          ),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          boxShadow: [
            BoxShadow(
              color: coral.withValues(alpha: 0.25),
              blurRadius: size * 0.3,
            ),
          ],
        ),
        child: CustomPaint(painter: _DumbbellPainter()),
      ),
    );
  }
}

class _DumbbellPainter extends CustomPainter {
  // x, y, width, height, corner radius on a 100×100 grid.
  // Keep in sync with tool/generate_icons.ps1.
  static const _parts = [
    [30.0, 46.5, 40.0, 7.0, 3.5], // bar
    [24.0, 29.0, 9.0, 42.0, 4.5], // inner plates
    [67.0, 29.0, 9.0, 42.0, 4.5],
    [15.5, 36.0, 7.0, 28.0, 3.5], // outer plates
    [77.5, 36.0, 7.0, 28.0, 3.5],
    [11.0, 46.5, 5.5, 7.0, 2.5], // end caps
    [83.5, 46.5, 5.5, 7.0, 2.5],
  ];
  static const _glyphScale = 0.84;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width * _glyphScale / 100;
    canvas
      ..save()
      ..translate(
        size.width * (1 - _glyphScale) / 2,
        size.height * (1 - _glyphScale) / 2,
      )
      ..scale(scale)
      ..translate(50, 50)
      ..rotate(-35 * pi / 180)
      ..translate(-50, -50);
    final paint = Paint()
      ..shader = coralGradient.createShader(
        const Rect.fromLTWH(0, 0, 100, 100),
      );
    for (final [x, y, w, h, r] in _parts) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DumbbellPainter oldDelegate) => false;
}
