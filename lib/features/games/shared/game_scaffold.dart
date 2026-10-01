import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/countdown_bar.dart';
import '../../../core/widgets/design_kit.dart';
import '../../../models/models.dart';

/// هيكل موحّد لشاشة الجولة: مؤقت الخادم + عنوان + محتوى.
class GameRoundScaffold extends StatelessWidget {
  const GameRoundScaffold({
    super.key,
    required this.round,
    required this.title,
    required this.child,
    this.subtitle,
    this.totalSeconds,
    this.footer,
    this.accent,
    this.badge,
  });

  final GameRound round;
  final String title;
  final String? subtitle;
  final Widget child;
  final int? totalSeconds;
  final Widget? footer;
  final Color? accent;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;
    final Color tone = accent ?? AppColors.gold;

    final int total = totalSeconds ??
        (round.startsAt == null
            ? 60
            : round.endsAt.difference(round.startsAt!).inSeconds);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: CountdownBar(
            endsAt: round.endsAt,
            totalSeconds: total <= 0 ? 60 : total,
            label: '${l10n.t('round')} ${round.index}',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FadeInUp(
            offset: 10,
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              glowColor: tone,
              child: Column(
                children: <Widget>[
                  if (badge != null) ...<Widget>[
                    GlassPill(label: badge!, color: tone, dense: true),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 20,
                      height: 1.4,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: muted),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: child),
        if (footer != null) footer!,
      ],
    );
  }
}

class WaitingForOthers extends StatelessWidget {
  const WaitingForOthers({super.key, this.submittedCount, this.totalCount});

  final int? submittedCount;
  final int? totalCount;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    final double? progress = (submittedCount != null &&
            totalCount != null &&
            totalCount! > 0)
        ? (submittedCount! / totalCount!).clamp(0.0, 1.0)
        : null;

    return Center(
      child: FadeInUp(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TimerRing(
              progress: progress ?? 1,
              color: AppColors.green,
              size: 104,
              child: const Icon(Icons.check_rounded,
                  size: 44, color: AppColors.green),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.t('submitted'),
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.t('waiting_others'),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: muted),
            ),
            if (submittedCount != null && totalCount != null) ...<Widget>[
              const SizedBox(height: 14),
              GlassPill(
                icon: Icons.groups_2_outlined,
                label: '$submittedCount / $totalCount',
                color: AppColors.gold,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
