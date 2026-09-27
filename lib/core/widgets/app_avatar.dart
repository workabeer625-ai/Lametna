import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// صورة رمزية مضمّنة داخل التطبيق. لا رفع صور شخصية إطلاقًا.
/// إن لم يوجد ملف الصورة، نعرض رمزًا تعبيريًا مكافئًا (لا تنكسر الواجهة).
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.avatarKey,
    this.size = 44,
    this.badge,
    this.dimmed = false,
  });

  final String? avatarKey;
  final double size;
  final Widget? badge;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Widget circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primaryContainer,
        border: Border.all(color: colors.primary.withValues(alpha: 0.25), width: 1.5),
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: Image.asset(
          'assets/avatars/${avatarKey ?? 'star'}.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text(
            BuiltInAvatars.emojiFor(avatarKey),
            style: TextStyle(fontSize: size * 0.5),
          ),
        ),
      ),
    );

    final Widget content = dimmed
        ? Opacity(opacity: 0.4, child: circle)
        : circle;

    if (badge == null) return content;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        content,
        Positioned(bottom: -2, right: -2, child: badge!),
      ],
    );
  }
}
