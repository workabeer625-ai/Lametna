import 'package:flutter/material.dart';

/// Staggered entrance animation: fade + slide (+ a touch of scale).
class FadeInUp extends StatefulWidget {
  const FadeInUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 560),
    this.offset = 26,
    this.scaleFrom = 0.98,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;
  final double scaleFrom;

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (BuildContext context, Widget? child) {
        final double v = _curve.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - v)),
            child: Transform.scale(
              scale: widget.scaleFrom + (1 - widget.scaleFrom) * v,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
