import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ثيم «لمّتنا» الحديث — Material 3، عربي/إنجليزي، فاتح وداكن.
///
/// الخطوط مضمّنة محليًا (Cairo للنصوص، Baloo Bhaijaan 2 للعناوين) فلا يحتاج
/// التطبيق أي اتصال بالإنترنت لتحميل الخطوط عند أول تشغيل.
class AppTheme {
  const AppTheme._();

  // ── توكنز التصميم ────────────────────────────────────────────
  static const String fontBody = 'Cairo';
  static const String fontDisplay = 'Baloo';

  static const double radius = 18;
  static const double rSm = 14;
  static const double rMd = 22;
  static const double rLg = 28;
  static const double rXl = 36;

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 340);
  static const Duration slow = Duration(milliseconds: 620);
  static const Curve ease = Curves.easeOutCubic;

  /// توهّج ملوّن ناعم تحت الأزرار والبطاقات.
  static List<BoxShadow> glow(
    Color c, {
    double opacity = 0.38,
    double blur = 26,
    double y = 12,
  }) {
    return <BoxShadow>[
      BoxShadow(
        color: c.op(opacity),
        blurRadius: blur,
        offset: Offset(0, y),
        spreadRadius: -6,
      ),
    ];
  }

  /// ظل ارتفاع محايد.
  static List<BoxShadow> lift(bool isDark) => <BoxShadow>[
        BoxShadow(
          color: (isDark ? Colors.black : AppColors.coffee).op(isDark ? 0.45 : 0.14),
          blurRadius: 28,
          offset: const Offset(0, 14),
          spreadRadius: -10,
        ),
      ];

  static ThemeData light(String locale) => _build(Brightness.light, locale);
  static ThemeData dark(String locale) => _build(Brightness.dark, locale);

  // ── النصوص ───────────────────────────────────────────────────
  static TextTheme _text(Color ink, Color muted) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontDisplay,
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 1.22,
        color: ink,
      ),
      displayMedium: TextStyle(
        fontFamily: fontDisplay,
        fontSize: 31,
        fontWeight: FontWeight.w800,
        height: 1.26,
        color: ink,
      ),
      displaySmall: TextStyle(
        fontFamily: fontDisplay,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: ink,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontDisplay,
        fontSize: 23,
        fontWeight: FontWeight.w700,
        height: 1.32,
        color: ink,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontDisplay,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.42,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: ink,
      ),
      titleSmall: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: muted,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.72,
        color: ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.66,
        color: muted,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: muted,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: ink,
      ),
      labelMedium: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: muted,
      ),
      labelSmall: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.2,
        color: muted,
      ),
    );
  }

  static ThemeData _build(Brightness brightness, String locale) {
    final bool isDark = brightness == Brightness.dark;

    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;
    final Color surface = isDark ? AppColors.darkSurface : AppColors.white;
    final Color background = isDark ? AppColors.darkBackground : AppColors.beige;
    final Color outline = isDark ? Colors.white.op(0.10) : AppColors.coffee.op(0.12);

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.coffee,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? AppColors.gold : AppColors.coffee,
      onPrimary: isDark ? AppColors.espresso : AppColors.white,
      primaryContainer: isDark ? AppColors.mocha : AppColors.sand,
      onPrimaryContainer: ink,
      secondary: isDark ? AppColors.greenLight : AppColors.green,
      onSecondary: AppColors.white,
      tertiary: AppColors.gold,
      onTertiary: AppColors.espresso,
      surface: surface,
      onSurface: ink,
      surfaceContainerHighest: isDark ? AppColors.darkCard : AppColors.cream,
      outline: isDark ? AppColors.mutedLight.op(0.4) : AppColors.coffee.op(0.25),
      outlineVariant: outline,
      error: AppColors.danger,
    );

    final TextTheme textTheme = _text(ink, muted);

    return ThemeData(
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: fontBody,
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkRipple.splashFactory,
      highlightColor: scheme.primary.op(0.06),

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        titleTextStyle: textTheme.headlineSmall,
        iconTheme: IconThemeData(color: ink, size: 22),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.darkCard : AppColors.white,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rMd),
          side: BorderSide(color: outline),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: ink,
          side: BorderSide(color: isDark ? Colors.white.op(0.16) : AppColors.coffee.op(0.22)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.op(0.05) : AppColors.white,
        hintStyle: TextStyle(color: muted, fontSize: 14, fontWeight: FontWeight.w500),
        labelStyle: TextStyle(color: muted, fontSize: 14, fontWeight: FontWeight.w600),
        prefixIconColor: muted,
        suffixIconColor: muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rSm + 2),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rSm + 2),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rSm + 2),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rSm + 2),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? Colors.white.op(0.06) : AppColors.coffee.op(0.06),
        selectedColor: scheme.primary.op(0.16),
        side: BorderSide(color: outline),
        labelStyle: TextStyle(
          fontFamily: fontBody,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      dividerTheme: DividerThemeData(color: outline, space: 1, thickness: 1),

      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMd)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => s.contains(WidgetState.selected)
              ? AppColors.white
              : (isDark ? AppColors.mutedLight : AppColors.white),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => s.contains(WidgetState.selected)
              ? scheme.primary
              : (isDark ? Colors.white.op(0.12) : AppColors.coffee.op(0.14)),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: isDark ? Colors.white.op(0.10) : AppColors.coffee.op(0.12),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.op(0.14),
        trackHeight: 6,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: isDark ? Colors.white.op(0.08) : AppColors.coffee.op(0.10),
        circularTrackColor: isDark ? Colors.white.op(0.08) : AppColors.coffee.op(0.10),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: muted,
        indicatorColor: scheme.primary,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.op(0.16),
        elevation: 0,
        height: 70,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            fontFamily: fontBody,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => IconThemeData(
            size: 23,
            color: s.contains(WidgetState.selected) ? scheme.primary : muted,
          ),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        selectedItemColor: scheme.primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.espresso,
        contentTextStyle: const TextStyle(
          fontFamily: fontBody,
          color: AppColors.inkLight,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rSm)),
        insetPadding: const EdgeInsets.all(16),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rLg)),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyLarge,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: muted.op(0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.espresso.op(0.94),
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontFamily: fontBody,
          color: AppColors.inkLight,
          fontSize: 12,
        ),
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
