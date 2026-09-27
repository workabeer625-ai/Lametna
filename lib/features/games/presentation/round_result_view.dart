import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/design_kit.dart';
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Widget? custom = definition.buildRoundResult(context, ctx);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow:
                      AppTheme.glow(AppColors.gold, opacity: 0.3, blur: 14, y: 5),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    size: 18, color: AppColors.espresso),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${l10n.t('round_results')} — ${l10n.t('round')} '
                  '${ctx.state.round?.index ?? 0}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: ink,
                  ),
                ),
              ),
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                  backgroundColor: AppColors.gold.op(0.18),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: custom ?? _ScoreBoard(ctx: ctx)),
        SizedBox(height: 104, child: _MiniScores(ctx: ctx)),
      ],
    );
  }
}

class _ScoreBoard extends StatelessWidget {
  const _ScoreBoard({required this.ctx});
  final GameRoundContext ctx;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;

    final List<RoomPlayer> players = <RoomPlayer>[...ctx.state.activePlayers]
      ..sort((RoomPlayer a, RoomPlayer b) => b.score.compareTo(a.score));

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      children: List<Widget>.generate(players.length, (int i) {
        final RoomPlayer p = players[i];
        final bool top = i == 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FadeInUp(
            delay: Duration(milliseconds: 40 * (i < 8 ? i : 8)),
            offset: 10,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 11, 16, 11),
              decoration: BoxDecoration(
                color: top
                    ? AppColors.gold.op(isDark ? 0.16 : 0.12)
                    : (isDark ? AppColors.white.op(0.05) : AppColors.white.op(0.62)),
                borderRadius: BorderRadius.circular(AppTheme.rMd),
                border: Border.all(
                  color: top
                      ? AppColors.gold.op(0.42)
                      : (isDark ? AppColors.white : AppColors.coffee).op(0.10),
                ),
              ),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${i + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: top
                            ? AppColors.gold
                            : (isDark
                                ? AppColors.mutedLight
                                : AppColors.mutedDark),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AppAvatar(avatarKey: p.avatarKey, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800, color: ink),
                    ),
                  ),
                  Text(
                    '${p.score}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: top ? AppColors.gold : ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _MiniScores extends StatelessWidget {
  const _MiniScores({required this.ctx});
  final GameRoundContext ctx;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    final List<RoomPlayer> players = <RoomPlayer>[...ctx.state.activePlayers]
      ..sort((RoomPlayer a, RoomPlayer b) => b.score.compareTo(a.score));

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: (isDark ? AppColors.white : AppColors.coffee).op(0.10)),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        itemCount: players.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, int i) {
          final RoomPlayer p = players[i];
          final bool top = i == 0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: top
                      ? AppGradients.gold
                      : AppGradients.from(AppColors.forSeed(p.userId)),
                  shape: BoxShape.circle,
                  boxShadow: top
                      ? AppTheme.glow(AppColors.gold,
                          opacity: 0.34, blur: 16, y: 5)
                      : null,
                ),
                child: Text(
                  '${p.score}',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: top ? AppColors.espresso : AppColors.white,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: 64,
                child: Text(
                  p.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10.5, fontWeight: FontWeight.w700, color: muted),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
