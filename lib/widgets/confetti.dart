import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Lightweight confetti burst — pure CustomPainter, no packages.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    this.count = 70,
    this.colors = const <Color>[
      AppColors.violet,
      AppColors.cyan,
      AppColors.pink,
      AppColors.amber,
      AppColors.mint,
    ],
    this.duration = const Duration(seconds: 6),
  });

  final int count;
  final List<Color> colors;
  final Duration duration;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)..forward();

  late final List<_Piece> _pieces = List<_Piece>.generate(
    widget.count,
    (int i) {
      final math.Random r = math.Random(i * 7919);
      return _Piece(
        x: r.nextDouble(),
        delay: r.nextDouble() * 0.35,
        speed: 0.55 + r.nextDouble() * 0.75,
        drift: (r.nextDouble() - 0.5) * 0.36,
        size: 6 + r.nextDouble() * 9,
        spin: (r.nextDouble() - 0.5) * 10,
        color: widget.colors[i % widget.colors.length],
        round: r.nextBool(),
      );
    },
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? _) {
            return CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(t: _c.value, pieces: _pieces),
            );
          },
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.size,
    required this.spin,
    required this.color,
    required this.round,
  });

  final double x;
  final double delay;
  final double speed;
  final double drift;
  final double size;
  final double spin;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.t, required this.pieces});

  final double t;
  final List<_Piece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    for (final _Piece p in pieces) {
      final double local = ((t - p.delay) * p.speed).clamp(0.0, 2.0);
      if (local <= 0) continue;

      final double y = -0.1 + local * 1.35;
      if (y > 1.15) continue;

      final double x = p.x + math.sin((local + p.x) * math.pi * 2) * p.drift;
      final double fade = (1 - (local - 0.75).clamp(0.0, 1.0) / 0.55).clamp(0.0, 1.0);

      final Offset c = Offset(x * size.width, y * size.height);
      final Paint paint = Paint()..color = p.color.op(0.92 * fade);

      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(local * p.spin);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2.4, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.52),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
