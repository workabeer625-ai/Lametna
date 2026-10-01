import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import 'pressable.dart';

/// سطح زجاجي مصنفر بحافة شعرية وتوهّج اختياري — أساس التصميم الجديد.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.radius = AppTheme.rLg,
    this.blur = 20,
    this.tint,
    this.tintOpacity,
    this.borderOpacity,
    this.glowColor,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blur;
  final Color? tint;
  final double? tintOpacity;
  final double? borderOpacity;
  final Color? glowColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color t = tint ?? AppColors.white;
    final double to = tintOpacity ?? (isDark ? 0.08 : 0.72);
    final double bo = borderOpacity ?? (isDark ? 0.12 : 0.55);
    final Color borderColor =
        isDark ? Colors.white.op(bo) : AppColors.white.op(bo);
    final BorderRadius br = BorderRadius.circular(radius);

    Widget surface = ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: br,
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: <Color>[t.op(to), t.op(to * (isDark ? 0.35 : 0.72))],
            ),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: child,
        ),
      ),
    );

    surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: glowColor != null
            ? AppTheme.glow(glowColor!, opacity: isDark ? 0.26 : 0.20, blur: 32, y: 14)
            : AppTheme.lift(isDark),
      ),
      child: surface,
    );

    if (margin != null) surface = Padding(padding: margin!, child: surface);

    return onTap == null ? surface : Pressable(onTap: onTap, child: surface);
  }
}

/// زر أيقونة دائري زجاجي — يستعمل في رؤوس الشاشات.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 46,
    this.iconSize = 21,
    this.color,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? color;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = color ??
        (isDark ? AppColors.inkLight : AppColors.coffee);

    return Pressable(
      onTap: onTap,
      scale: 0.9,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.white.op(0.07) : AppColors.white.op(0.8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.op(0.14)
                          : AppColors.coffee.op(0.10),
                    ),
                  ),
                  child: Icon(icon, size: iconSize, color: fg),
                ),
              ),
            ),
            if (badge)
              Positioned(
                top: 2,
                left: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.rose,
                    boxShadow: AppTheme.glow(AppColors.rose,
                        opacity: 0.8, blur: 10, y: 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// شارة صغيرة: أيقونة + نص.
class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 9 : 12,
        vertical: dense ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: c.op(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: c.op(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 12 : 14, color: c),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontBody,
              fontSize: dense ? 11 : 12.5,
              fontWeight: FontWeight.w700,
              color: c,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
