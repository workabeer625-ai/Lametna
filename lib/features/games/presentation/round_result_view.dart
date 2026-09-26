import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../models/models.dart';
import '../engine/game_definition.dart';

/// نتيجة الجولة — كل لعبة قد تعرضها بطريقتها، وإلا نعرض لوحة نقاط عامة.
class RoundResultView extends StatelessWidget {
  const RoundResultView({super.key, required this.ctx, required this.definition});

  final GameRoundContext ctx;
  final GameDefinition definition;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Widget? custom = definition.buildRoundResult(context, ctx);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: <Widget>[
              const Icon(Icons.emoji_events_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l10n.t('round_results')} — ${l10n.t('round')} ${ctx.state.round?.index ?? 0}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
        Expanded(child: custom ?? _ScoreBoard(ctx: ctx)),
        const Divider(height: 1),
        SizedBox(
          height: 96,
          child: _MiniScores(ctx: ctx),
        ),
      ],
    );
  }
}

class _ScoreBoard extends StatelessWidget {
  const _ScoreBoard({required this.ctx});
  final GameRoundContext ctx;

  @override
  Widget build(BuildContext context) {
    final List<RoomPlayer> players = <RoomPlayer>[...ctx.state.activePlayers]
      ..sort((RoomPlayer a, RoomPlayer b) => b.score.compareTo(a.score));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: players
          .map((RoomPlayer p) => Card(
                child: ListTile(
                  title: Text(p.nickname),
                  trailing: Text('${p.score}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ))
          .toList(),
    );
  }
}

class _MiniScores extends StatelessWidget {
  const _MiniScores({required this.ctx});
  final GameRoundContext ctx;

  @override
  Widget build(BuildContext context) {
    final List<RoomPlayer> players = <RoomPlayer>[...ctx.state.activePlayers]
      ..sort((RoomPlayer a, RoomPlayer b) => b.score.compareTo(a.score));

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: players.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, int i) {
        final RoomPlayer p = players[i];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: 20,
              backgroundColor: i == 0
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text('${p.score}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(p.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall),
            ),
          ],
        );
      },
    );
  }
}
