import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The signature Lametna backdrop: a slow-moving aurora of blurred colour
/// blobs over a deep violet night gradient, finished with a vignette.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    required this.child,
    this.colors,
    this.intensity = 1.0,
    this.animate = true,
  });

  final Widget child;
  final List<Color>? colors;
  final double intensity;
  final bool animate;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant AuroraBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.animate && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> palette = widget.colors ??
        const <Color>[
          AppColors.violet,
          AppColors.indigo,
          AppColors.magenta,
          AppColors.cyan,
        ];

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.night),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (BuildContext context, Widget? _) {
                return CustomPaint(
                  painter: _AuroraPainter(
                    t: _c.value,
                    colors: palette,
                    intensity: widget.intensity,
                  ),
                );
              },
            ),
          ),
          const _GrainVignette(),
          widget.child,
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.t, required this.colors, required this.intensity});

  final double t;
  final List<Color> colors;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final double tau = math.pi * 2;
    final double unit = size.shortestSide;

    for (int i = 0; i < colors.length; i++) {
      final double phase = t * tau + i * (tau / colors.length);
      final double dx = 0.5 + 0.34 * math.sin(phase * (1 + i * 0.13));
      final double dy = 0.34 + 0.30 * math.cos(phase * (0.8 + i * 0.17)) + i * 0.12;
      final double radius = unit * (0.42 + 0.10 * math.sin(phase + i));

      final Paint paint = Paint()
        ..color = colors[i].op((0.30 - i * 0.03).clamp(0.10, 0.34) * intensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.22);

      canvas.drawCircle(
        Offset(size.width * dx, size.height * dy.clamp(-0.1, 1.1)),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.t != t || old.intensity != intensity || old.colors != colors;
}

/// Subtle top glare + bottom vignette that glues the blobs to the canvas.
class _GrainVignette extends StatelessWidget {
  const _GrainVignette();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.white.op(0.035),
              Colors.transparent,
              AppColors.bg.op(0.55),
              AppColors.bg.op(0.88),
            ],
            stops: const <double>[0.0, 0.32, 0.82, 1.0],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
