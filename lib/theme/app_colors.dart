import 'package:flutter/material.dart';

/// Readability helper around [Color.withValues].
extension ColorAlphaX on Color {
  Color op(double opacity) => withValues(alpha: opacity);
}

/// The Lametna palette.
///
/// Everything is anchored on the original deep-purple seed so the brand
/// colour system of the project stays intact — we only modernise it.
class AppColors {
  const AppColors._();

  /// Original project seed (Colors.deepPurple).
  static const Color seed = Color(0xFF673AB7);

  // ── Violet core ────────────────────────────────────────────────
  static const Color violet = Color(0xFF8B5CF6);
  static const Color violetLight = Color(0xFFA78BFA);
  static const Color violetDeep = Color(0xFF6D28D9);
  static const Color violetSoft = Color(0xFFC4B5FD);
  static const Color indigo = Color(0xFF4C1D95);

  // ── Support accents (tuned to sit beside violet) ───────────────
  static const Color cyan = Color(0xFF22D3EE);
  static const Color pink = Color(0xFFF472B6);
  static const Color magenta = Color(0xFFD946EF);
  static const Color amber = Color(0xFFFBBF24);
  static const Color mint = Color(0xFF34D399);
  static const Color coral = Color(0xFFFB7185);
  static const Color blue = Color(0xFF60A5FA);

  // ── Canvas ─────────────────────────────────────────────────────
  static const Color bg = Color(0xFF080312);
  static const Color bgAlt = Color(0xFF12071F);
  static const Color card = Color(0xFF1A0E2E);

  // ── Ink ────────────────────────────────────────────────────────
  static const Color ink = Color(0xFFF6F3FF);
  static const Color inkSoft = Color(0xFFCFC6E8);
  static const Color inkMuted = Color(0xFF9B90BC);

  /// Accents the player can pick from in the settings screen.
  static const List<Color> accentChoices = <Color>[
    violet,
    cyan,
    pink,
    amber,
    mint,
    coral,
  ];

  /// Palette used to colour player avatars.
  static const List<Color> avatarColors = <Color>[
    violet,
    cyan,
    pink,
    amber,
    mint,
    coral,
    blue,
    magenta,
  ];

  /// A darker sibling of [c], used to build two-stop gradients.
  static Color deepen(Color c, [double amount = 0.28]) {
    final HSLColor hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.05).clamp(0.0, 1.0))
        .toColor();
  }
}

class AppGradients {
  const AppGradients._();

  static const LinearGradient violet = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: <Color>[AppColors.violetLight, AppColors.violetDeep],
  );

  static const LinearGradient night = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFF16082A), Color(0xFF080312)],
  );

  /// Builds a soft two-stop gradient from any accent colour.
  static LinearGradient from(Color c) => LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: <Color>[c, AppColors.deepen(c)],
      );

  static LinearGradient glass(double a, double b) => LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: <Color>[Colors.white.op(a), Colors.white.op(b)],
      );
}
