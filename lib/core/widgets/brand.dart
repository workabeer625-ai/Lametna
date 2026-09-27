import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

/// علامة «لمّتنا»: ثلاث هالات دافئة تدور حول مركز واحد — رمز اللمّة.
class BrandMark extends StatefulWidget {
  const BrandMark({super.key, this.size = 64, this.animate = true});

  final double size;
  final bool animate;

  @override
  State<BrandMark> createState() => _BrandMarkState();
}

class _BrandMarkState extends State<BrandMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 10));

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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? _) {
          return CustomPaint(painter: _MarkPainter(_c.value, isDark));
        },
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.t, this.isDark);

  final double t;
  final bool isDark;

  static const List<Color> _orbs = <Color>[
    AppColors.gold,
    AppColors.green,
    AppColors.latte,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double r = size.shortestSide * 0.21;
    final double orbit = size.shortestSide * 0.20;

    canvas.drawCircle(
      center,
      size.shortestSide * 0.44,
      Paint()
        ..color = AppColors.gold.op(isDark ? 0.26 : 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.shortestSide * 0.16),
    );

    for (int i = 0; i < 3; i++) {
      final double a = t * math.pi * 2 + i * (math.pi * 2 / 3);
      final Offset p = center + Offset(math.cos(a) * orbit, math.sin(a) * orbit);
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..color = _orbs[i].op(isDark ? 0.92 : 0.85)
          ..blendMode = isDark ? BlendMode.plus : BlendMode.multiply,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) =>
      old.t != t || old.isDark != isDark;
}

/// اسم التطبيق بتدرّج ذهبي.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.fontSize = 26, this.text = 'لمّتنا'});

  final double fontSize;
  final String text;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ShaderMask(
      shaderCallback: (Rect bounds) => LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: isDark
            ? const <Color>[AppColors.cream, AppColors.goldLight, AppColors.gold]
            : const <Color>[AppColors.coffee, AppColors.goldDeep, AppColors.green],
      ).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTheme.fontDisplay,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.25,
        ),
      ),
    );
  }
}
