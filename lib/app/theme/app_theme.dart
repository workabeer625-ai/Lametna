import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// ثيم Material 3 بالعربية والإنجليزية، فاتح وداكن.
class AppTheme {
  const AppTheme._();

  static const double radius = 18;

  static ThemeData light(String locale) => _build(Brightness.light, locale);
  static ThemeData dark(String locale) => _build(Brightness.dark, locale);

  static TextTheme _fonts(TextTheme base, String locale) {
    // Cairo للعربية، Tajawal بديل — يمكن تضمين الخطوط محليًا لاحقًا
    // (انظر tool/fetch_fonts.sh) للعمل دون إنترنت في أول تشغيل.
    try {
      return locale == 'en'
          ? GoogleFonts.cairoTextTheme(base)
          : GoogleFonts.cairoTextTheme(base);
    } catch (_) {
      return base;
    }
  }

  static ThemeData _build(Brightness brightness, String locale) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.coffee,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? AppColors.gold : AppColors.coffee,
      onPrimary: isDark ? AppColors.textGrey : AppColors.white,
      secondary: AppColors.green,
      onSecondary: AppColors.white,
      tertiary: AppColors.gold,
      surface: isDark ? AppColors.darkSurface : AppColors.white,
      error: AppColors.danger,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? AppColors.darkBackground : AppColors.beige,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return base.copyWith(
      textTheme: _fonts(base.textTheme, locale).apply(
        bodyColor: isDark ? AppColors.beige : AppColors.textGrey,
        displayColor: isDark ? AppColors.beige : AppColors.textGrey,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.beige,
        foregroundColor: isDark ? AppColors.beige : AppColors.coffee,
        titleTextStyle: _fonts(base.textTheme, locale).titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.beige : AppColors.coffee,
            ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.darkCard : AppColors.white,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color: isDark ? Colors.white10 : AppColors.coffee.withValues(alpha: 0.10),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.coffee.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.coffee.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: AppColors.coffee.withValues(alpha: 0.15)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
