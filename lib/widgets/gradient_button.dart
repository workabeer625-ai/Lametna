import 'dart:ui';

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// The primary call-to-action: gradient fill, coloured glow and a
/// slow light sweep across the surface.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.colors,
    this.height = 58,
    this.expand = true,
    this.shine = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final List<Color>? colors;
  final double height;
  final bool expand;
  final bool shine;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.shine) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = AppScope.of(context).accent;
    final List<Color> colors =
        widget.colors ?? <Color>[accent, AppColors.deepen(accent, 0.22)];
    final bool enabled = widget.onTap != null;
    final BorderRadius br = BorderRadius.circular(widget.height / 2);

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Pressable(
        onTap: widget.onTap,
        scale: 0.965,
        child: Container(
          height: widget.height,
          width: widget.expand ? double.infinity : null,
          decoration: BoxDecoration(
            borderRadius: br,
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: colors,
            ),
            boxShadow: enabled
                ? AppTheme.glow(colors.first, opacity: 0.45, blur: 30, y: 14)
                : null,
          ),
          child: ClipRRect(
            borderRadius: br,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                if (widget.shine)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (BuildContext context, Widget? _) {
                        return FractionallySizedBox(
                          widthFactor: 0.45,
                          alignment: Alignment(-1.6 + _c.value * 3.2, 0),
                          child: Transform.rotate(
                            angle: 0.35,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    Colors.white.op(0),
                                    Colors.white.op(0.22),
                                    Colors.white.op(0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: br,
                      border: Border.all(color: Colors.white.op(0.22)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Colors.white.op(0.16), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (widget.icon != null) ...<Widget>[
                        Icon(widget.icon, size: 20, color: Colors.white),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Quieter secondary action rendered as a frosted outline button.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.height = 54,
    this.expand = true,
    this.color,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final double height;
  final bool expand;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? AppColors.inkSoft;
    final BorderRadius br = BorderRadius.circular(height / 2);
    return Pressable(
      onTap: onTap,
      scale: 0.965,
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: height,
            width: expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: br,
              color: Colors.white.op(0.06),
              border: Border.all(color: Colors.white.op(0.16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 19, color: c),
                  const SizedBox(width: 9),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
