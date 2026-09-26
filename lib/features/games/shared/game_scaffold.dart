import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/widgets/countdown_bar.dart';
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
  });

  final GameRound round;
  final String title;
  final String? subtitle;
  final Widget child;
  final int? totalSeconds;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final int total = totalSeconds ??
        (round.startsAt == null
            ? 60
            : round.endsAt.difference(round.startsAt!).inSeconds);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: CountdownBar(
            endsAt: round.endsAt,
            totalSeconds: total <= 0 ? 60 : total,
            label: '${l10n.t('round')} ${round.index}',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: <Widget>[
              Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(subtitle!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.check_circle, size: 56, color: Colors.green),
            const SizedBox(height: 12),
            Text(context.l10n.t('submitted'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(context.l10n.t('waiting_others'),
                style: Theme.of(context).textTheme.bodySmall),
            if (submittedCount != null && totalCount != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('$submittedCount / $totalCount',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            const SizedBox(height: 16),
            const SizedBox(
                width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      );
}
