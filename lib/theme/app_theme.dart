import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralised design tokens + the app's dark theme.
class AppTheme {
  const AppTheme._();

  static const String fontBody = 'Cairo';
  static const String fontDisplay = 'Baloo';

  // ── Radii ──────────────────────────────────────────────────────
  static const double rSm = 14;
  static const double rMd = 22;
  static const double rLg = 30;
  static const double rXl = 38;

  // ── Spacing ────────────────────────────────────────────────────
  static const double gutter = 20;

  // ── Motion ─────────────────────────────────────────────────────
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 340);
  static const Duration slow = Duration(milliseconds: 620);
  static const Curve ease = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;

  /// Soft coloured glow used under buttons, cards and the nav bar.
  static List<BoxShadow> glow(Color c, {double opacity = 0.42, double blur = 28, double y = 12}) {
    return <BoxShadow>[
      BoxShadow(color: c.op(opacity), blurRadius: blur, offset: Offset(0, y), spreadRadius: -6),
    ];
  }

  static List<BoxShadow> get lift => <BoxShadow>[
        BoxShadow(color: Colors.black.op(0.45), blurRadius: 30, offset: const Offset(0, 16), spreadRadius: -12),
      ];

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.violet,
      onPrimary: Colors.white,
      secondary: AppColors.cyan,
      surface: AppColors.card,
      onSurface: AppColors.ink,
    );

    const TextTheme text = TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontDisplay,
        fontSize: 42,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: AppColors.ink,
      ),
      displayMedium: TextStyle(
        fontFamily: fontDisplay,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: AppColors.ink,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontDisplay,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: AppColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: AppColors.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.7,
        color: AppColors.inkSoft,
      ),
      bodyMedium: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.65,
        color: AppColors.inkMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.ink,
      ),
      labelSmall: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.2,
        color: AppColors.inkMuted,
      ),
    );

    return ThemeData(
      colorScheme: scheme,
      fontFamily: fontBody,
      textTheme: text,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.ink,
      ),
      dividerTheme: DividerThemeData(color: Colors.white.op(0.07), space: 1, thickness: 1),
      iconTheme: const IconThemeData(color: AppColors.inkSoft, size: 22),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.violet,
        inactiveTrackColor: Colors.white.op(0.10),
        thumbColor: Colors.white,
        overlayColor: AppColors.violet.op(0.18),
        trackHeight: 6,
        valueIndicatorColor: AppColors.violetDeep,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.inkMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => s.contains(WidgetState.selected) ? AppColors.violet : Colors.white.op(0.10),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.card,
        contentTextStyle: const TextStyle(fontFamily: fontBody, color: AppColors.ink, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMd)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
