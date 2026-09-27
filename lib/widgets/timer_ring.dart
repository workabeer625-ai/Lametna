import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular countdown ring with a glowing gradient sweep and tick marks.
class TimerRing extends StatelessWidget {
  const TimerRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 260,
    this.child,
  });

  /// 1.0 → full time remaining, 0.0 → finished.
  final double progress;
  final Color color;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(progress: progress.clamp(0.0, 1.0), color: color),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double r = size.width / 2 - 18;
    const double stroke = 14;

    // Tick marks around the dial.
    final Paint tick = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    for (int i = 0; i < 60; i++) {
      final double a = (i / 60) * math.pi * 2 - math.pi / 2;
      final bool major = i % 5 == 0;
      final double inner = r + 8;
      final double outer = inner + (major ? 7 : 4);
      tick.color = Colors.white.op(major ? 0.22 : 0.10);
      canvas.drawLine(
        center + Offset(math.cos(a) * inner, math.sin(a) * inner),
        center + Offset(math.cos(a) * outer, math.sin(a) * outer),
        tick,
      );
    }

    // Track.
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.op(0.07),
    );

    final Rect rect = Rect.fromCircle(center: center, radius: r);
    final double sweep = math.pi * 2 * progress;

    // Glow underlay.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 6
        ..strokeCap = StrokeCap.round
        ..color = color.op(0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Main sweep.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: <Color>[
            color.op(0.55),
            color,
            Colors.white,
          ],
          stops: const <double>[0.0, 0.55, 1.0],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );

    // Head dot.
    if (progress > 0.001) {
      final double a = -math.pi / 2 + sweep;
      final Offset head = center + Offset(math.cos(a) * r, math.sin(a) * r);
      canvas.drawCircle(head, 9, Paint()..color = Colors.white);
      canvas.drawCircle(
        head,
        14,
        Paint()
          ..color = color.op(0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
