import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// Frosted-glass surface with a hairline gradient border and optional glow.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = AppTheme.rLg,
    this.blur = 22,
    this.tint,
    this.tintOpacity = 0.10,
    this.borderOpacity = 0.14,
    this.glowColor,
    this.onTap,
    this.width,
    this.height,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blur;
  final Color? tint;
  final double tintOpacity;
  final double borderOpacity;
  final Color? glowColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final Color t = tint ?? Colors.white;
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
              colors: <Color>[t.op(tintOpacity), t.op(tintOpacity * 0.32)],
            ),
            border: Border.all(color: Colors.white.op(borderOpacity), width: 1),
          ),
          child: child,
        ),
      ),
    );

    if (glowColor != null) {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: AppTheme.glow(glowColor!, opacity: 0.28, blur: 34, y: 16),
        ),
        child: surface,
      );
    }

    if (margin != null) {
      surface = Padding(padding: margin!, child: surface);
    }

    return onTap == null ? surface : Pressable(onTap: onTap, child: surface);
  }
}

/// Circular frosted icon button used in headers.
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
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.op(0.08),
                    border: Border.all(color: Colors.white.op(0.16)),
                  ),
                  child: Icon(icon, size: iconSize, color: color ?? AppColors.inkSoft),
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
                    color: AppColors.coral,
                    boxShadow: AppTheme.glow(AppColors.coral, opacity: 0.8, blur: 10, y: 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small frosted label: icon + text.
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
    final Color c = color ?? AppColors.inkSoft;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 9 : 12, vertical: dense ? 5 : 7),
      decoration: BoxDecoration(
        color: c.op(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: c.op(0.22)),
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
