import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The Lametna mark: three orbs orbiting a centre — a gathering (لمّة).
class BrandMark extends StatefulWidget {
  const BrandMark({super.key, this.size = 64, this.animate = true});

  final double size;
  final bool animate;

  @override
  State<BrandMark> createState() => _BrandMarkState();
}

class _BrandMarkState extends State<BrandMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 9));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? _) {
          return CustomPaint(painter: _MarkPainter(_c.value));
        },
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.t);
  final double t;

  static const List<Color> _orbs = <Color>[
    AppColors.violetLight,
    AppColors.cyan,
    AppColors.pink,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double r = size.shortestSide * 0.21;
    final double orbit = size.shortestSide * 0.20;

    // Soft halo.
    canvas.drawCircle(
      center,
      size.shortestSide * 0.42,
      Paint()
        ..color = AppColors.violet.op(0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.shortestSide * 0.16),
    );

    for (int i = 0; i < 3; i++) {
      final double a = t * math.pi * 2 + i * (math.pi * 2 / 3);
      final Offset p = center + Offset(math.cos(a) * orbit, math.sin(a) * orbit);
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..color = _orbs[i].op(0.92)
          ..blendMode = BlendMode.plus,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.t != t;
}

/// Gradient wordmark "لمتنا".
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.fontSize = 26});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) => const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: <Color>[Colors.white, AppColors.violetSoft, AppColors.cyan],
      ).createShader(bounds),
      child: Text(
        'لمتنا',
        style: TextStyle(
          fontFamily: AppTheme.fontDisplay,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.2,
        ),
      ),
    );
  }
}
