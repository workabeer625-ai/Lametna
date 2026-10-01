import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// بطاقة تنقلب ثلاثية الأبعاد بين وجهين — للأدوار السرّية.
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.onFlipped,
    this.enabled = true,
  });

  final Widget front;
  final Widget back;
  final ValueChanged<bool>? onFlipped;
  final bool enabled;

  @override
  State<FlipCard> createState() => FlipCardState();
}

class FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
  late final Animation<double> _anim =
      CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic);

  bool get isFlipped => _c.value > 0.5;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void flip() {
    if (!widget.enabled) return;
    HapticFeedback.mediumImpact();
    if (isFlipped) {
      _c.reverse();
      widget.onFlipped?.call(false);
    } else {
      _c.forward();
      widget.onFlipped?.call(true);
    }
  }

  void reset() => _c.value = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: flip,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (BuildContext context, Widget? _) {
          final double angle = _anim.value * math.pi;
          final bool showBack = angle > math.pi / 2;
          final Matrix4 m = Matrix4.identity()
            ..setEntry(3, 2, 0.0014)
            ..rotateY(angle);

          return Transform(
            alignment: Alignment.center,
            transform: m,
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: widget.back,
                  )
                : widget.front,
          );
        },
      ),
    );
  }
}
