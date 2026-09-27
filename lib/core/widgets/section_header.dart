import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'pressable.dart';

/// عنوان قسم بشريط لوني + إجراء اختياري على اليسار.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accent,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color c = accent ?? theme.colorScheme.primary;

    return Row(
      children: <Widget>[
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[c, c.op(0.12)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(title, style: theme.textTheme.titleLarge),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!, style: theme.textTheme.labelSmall),
                ),
            ],
          ),
        ),
        if (actionLabel != null)
          Pressable(
            onTap: onAction,
            child: Row(
              children: <Widget>[
                Text(
                  actionLabel!,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c),
                ),
                const SizedBox(width: 2),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 18,
                  color: c,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
