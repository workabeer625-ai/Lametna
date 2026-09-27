import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import 'pressable.dart';

/// زر الإجراء الأساسي: تدرّج ذهبي/بنّي + توهّج + وميض ضوئي يمرّ على السطح.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.colors,
    this.height = 56,
    this.expand = true,
    this.shine = true,
    this.loading = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final List<Color>? colors;
  final double height;
  final bool expand;
  final bool shine;
  final bool loading;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Color> colors = widget.colors ??
        <Color>[AppColors.lighten(scheme.primary, 0.08), AppColors.deepen(scheme.primary, 0.12)];
    final bool enabled = widget.onTap != null && !widget.loading;
    final BorderRadius br = BorderRadius.circular(widget.height / 2);
    // لون النص يُحسب من إضاءة التدرّج حتى يبقى التباين مضموناً مع أي لون.
    final Color fg = colors.first.computeLuminance() > 0.55
        ? AppColors.espresso
        : AppColors.white;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Pressable(
        onTap: enabled ? widget.onTap : null,
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
                ? AppTheme.glow(colors.first, opacity: 0.42, blur: 28, y: 12)
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
                          widthFactor: 0.42,
                          alignment: Alignment(-1.6 + _c.value * 3.2, 0),
                          child: Transform.rotate(
                            angle: 0.35,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    Colors.white.op(0),
                                    Colors.white.op(0.20),
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
                      border: Border.all(color: Colors.white.op(0.20)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Colors.white.op(0.16), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: widget.loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(fg),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (widget.icon != null) ...<Widget>[
                              Icon(widget.icon, size: 20, color: fg),
                              const SizedBox(width: 9),
                            ],
                            Flexible(
                              child: Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontBody,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: fg,
                                  height: 1.1,
                                ),
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

/// إجراء ثانوي بهيئة زجاجية هادئة.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.height = 52,
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool disabled = onTap == null;
    final Color base = color ?? (isDark ? AppColors.inkLight : AppColors.coffee);
    final Color c = disabled ? base.op(0.45) : base;
    final BorderRadius br = BorderRadius.circular(height / 2);

    return Pressable(
      onTap: onTap,
      scale: 0.965,
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: height,
            width: expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              borderRadius: br,
              color: isDark ? Colors.white.op(0.06) : AppColors.white.op(0.7),
              border: Border.all(
                color: isDark ? Colors.white.op(0.14) : AppColors.coffee.op(0.16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 19, color: c),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontBody,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c,
                      height: 1.1,
                    ),
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
