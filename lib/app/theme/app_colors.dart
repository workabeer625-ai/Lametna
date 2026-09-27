import 'package:flutter/material.dart';

/// اختصار مقروء لـ [Color.withValues] — يستخدَم في كل نظام التصميم.
extension ColorAlphaX on Color {
  Color op(double opacity) => withValues(alpha: opacity);
}

/// لوحة ألوان «لمّتنا» — مستوحاة من القهوة اليمنية.
///
/// الهوية الأصلية محفوظة كما هي (coffee / green / gold / beige …) وأضيفت
/// عليها درجات ومشتقات حديثة يستعملها نظام التصميم الجديد.
class AppColors {
  const AppColors._();

  // ── الهوية الأساسية (كما كانت) ───────────────────────────────
  static const Color coffee = Color(0xFF6F4E37); // بني القهوة
  static const Color green = Color(0xFF1F6F5B); // أخضر داكن
  static const Color gold = Color(0xFFD9A441); // ذهبي
  static const Color beige = Color(0xFFF7F0E5); // بيج
  static const Color white = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF343434);

  static const Color darkSurface = Color(0xFF1C1713);
  static const Color darkBackground = Color(0xFF121010);
  static const Color darkCard = Color(0xFF261F19);

  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFB3261E);
  static const Color warning = Color(0xFFE08A00);
  static const Color info = Color(0xFF1F6F5B);

  static const Color night = Color(0xFF1A237E);
  static const Color day = Color(0xFFFFC107);

  // ── درجات القهوة (جديدة) ─────────────────────────────────────
  static const Color espresso = Color(0xFF2A1C12);
  static const Color mocha = Color(0xFF4A3426);
  static const Color latte = Color(0xFFB08968);
  static const Color cream = Color(0xFFFFFBF3);
  static const Color sand = Color(0xFFEADFCB);

  // ── درجات الذهبي والأخضر (جديدة) ─────────────────────────────
  static const Color goldLight = Color(0xFFF2C879);
  static const Color goldDeep = Color(0xFFB27E23);
  static const Color greenLight = Color(0xFF3E9E85);
  static const Color greenDeep = Color(0xFF12483B);

  // ── ألوان مساعدة للّعب (جديدة) ───────────────────────────────
  static const Color rose = Color(0xFFE0796B);
  static const Color plum = Color(0xFF8C5A7A);
  static const Color teal = Color(0xFF2E8B87);
  static const Color amber = Color(0xFFE9A83C);

  // ── الحبر (نصوص) ─────────────────────────────────────────────
  static const Color inkDark = Color(0xFF2A211B); // على الخلفيات الفاتحة
  static const Color inkLight = Color(0xFFF6EFE3); // على الخلفيات الداكنة
  static const Color mutedDark = Color(0xFF7A6A5C);
  static const Color mutedLight = Color(0xFFB7A793);

  /// ألوان الأفاتار / بطاقات الألعاب.
  static const List<Color> playful = <Color>[
    gold,
    green,
    coffee,
    rose,
    plum,
    teal,
    amber,
    latte,
  ];

  /// نسخة أغمق من اللون — لبناء تدرّجات من لون واحد.
  static Color deepen(Color c, [double amount = 0.16]) {
    final HSLColor hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  /// نسخة أفتح من اللون.
  static Color lighten(Color c, [double amount = 0.14]) {
    final HSLColor hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  /// لون مميّز ثابت لكل عنصر حسب معرّفه (لعبة، لاعب…).
  static Color forSeed(String seed) {
    if (seed.isEmpty) return gold;
    int hash = 0;
    for (int i = 0; i < seed.length; i++) {
      hash = (hash * 31 + seed.codeUnitAt(i)) & 0x7fffffff;
    }
    return playful[hash % playful.length];
  }
}

/// التدرّجات المعتمدة في التطبيق.
class AppGradients {
  const AppGradients._();

  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: <Color>[AppColors.goldLight, AppColors.goldDeep],
  );

  static const LinearGradient coffee = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: <Color>[AppColors.latte, AppColors.coffee],
  );

  static const LinearGradient green = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: <Color>[AppColors.greenLight, AppColors.greenDeep],
  );

  /// خلفية ليلية دافئة (الوضع الداكن).
  static const LinearGradient night = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFF1E1610), AppColors.darkBackground],
  );

  /// خلفية نهارية (الوضع الفاتح).
  static const LinearGradient dayLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[AppColors.cream, AppColors.beige],
  );

  /// تدرّج من أي لون واحد.
  static LinearGradient from(Color c) => LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: <Color>[AppColors.lighten(c, 0.08), AppColors.deepen(c, 0.14)],
      );
}
