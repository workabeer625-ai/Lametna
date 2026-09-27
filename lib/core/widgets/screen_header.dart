import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import 'glass.dart';

/// ترويسة موحّدة لكل الشاشات الداخلية — بديل أنيق عن [AppBar].
///
/// تُستعمل داخل `AuroraBackground` + `SafeArea`:
/// ```dart
/// ScreenHeader(title: l10n.t('settings'), onBack: () => context.pop())
/// ```
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const <Widget>[],
    this.accent,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 0),
    this.backIcon = Icons.arrow_back,
    this.centerTitle = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final IconData backIcon;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;
    final Color tone = accent ?? AppColors.gold;

    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          if (onBack != null) ...<Widget>[
            GlassIconButton(icon: backIcon, onTap: onBack),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 22,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (actions.isNotEmpty) const SizedBox(width: 10),
          ...actions,
        ],
      ),
    )
        // خط ذهبي رفيع أسفل الترويسة يمنح إحساسًا «فخمًا» بلا ضجيج.
        .withUnderline(tone);
  }
}

extension _HeaderX on Widget {
  Widget withUnderline(Color tone) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          this,
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    tone.op(0.0),
                    tone.op(0.42),
                    tone.op(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}
