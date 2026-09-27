import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/design_kit.dart';
import '../../../models/models.dart';
import '../engine/game_definition.dart';
import '../shared/game_scaffold.dart';

/// المافيا.
///
/// ملاحظات أمنية (كلها مفروضة على الخادم، وهذه الواجهة تعكسها فقط):
///  • الأدوار تُوزَّع في `start_game` داخل Postgres ولا تُرسل إلا لصاحبها (RLS).
///  • الأفعال الليلية تمرّ عبر `submit_mafia_action` الذي يتحقق من الدور والحياة.
///  • نتيجة التحقيق تُعاد للمحقق وحده ولا تُخزَّن في مكان عام.
///  • الميت لا يصوّت ولا ينفّذ أفعالًا ولا يكتب في الدردشة العامة.
///  • التصويت والقتل والفوز تُحسم في `resolve_round`.
class MafiaGame extends GameDefinition {
  const MafiaGame({this.gameKey = GameKeys.mafia});

  /// يسمح لـ«الغمزة» بإعادة استخدام المحرك نفسه بدور واحد فقط.
  final String gameKey;

  @override
  String get key => gameKey;

  @override
  bool get hasSecretRoles => true;

  @override
  Widget buildRound(BuildContext context, GameRoundContext ctx) => _MafiaRoundView(ctx: ctx);

  @override
  Widget? buildRoundResult(BuildContext context, GameRoundContext ctx) =>
      _MafiaResultView(ctx: ctx);
}

/// الغمزة — مافيا مبسّطة: غمّاز واحد، بلا طبيب ولا محقق.
class WinkGame extends MafiaGame {
  const WinkGame() : super(gameKey: GameKeys.wink);
}

class _MafiaRoundView extends StatelessWidget {
  const _MafiaRoundView({required this.ctx});
  final GameRoundContext ctx;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final GameRound round = ctx.state.round!;
    final MyMafiaRole? role = ctx.state.myRole;
    final bool isNight = round.isMafiaNight;

    return Column(
      children: <Widget>[
        _PhaseBanner(isNight: isNight),
        Expanded(
          child: GameRoundScaffold(
            round: round,
            title: isNight ? l10n.t('night_phase') : l10n.t('day_phase'),
            subtitle: isNight ? l10n.t('night_hint') : l10n.t('day_hint'),
            accent: isNight ? AppColors.plum : AppColors.amber,
            child: role == null
                ? const Center(child: CircularProgressIndicator())
                : (isNight
                    ? _NightView(ctx: ctx, role: role)
                    : _DayVoteView(ctx: ctx, role: role)),
          ),
        ),
      ],
    );
  }
}

class _PhaseBanner extends StatelessWidget {
  const _PhaseBanner({required this.isNight});
  final bool isNight;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: isNight
                ? <Color>[AppColors.night, AppColors.plum]
                : <Color>[AppColors.goldLight, AppColors.amber],
          ),
          boxShadow: AppTheme.glow(
            isNight ? AppColors.plum : AppColors.amber,
            opacity: 0.32,
            blur: 22,
            y: 6,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(isNight ? '🌙' : '☀️', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(
              isNight ? context.l10n.t('night_phase') : context.l10n.t('day_phase'),
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                color: isNight ? AppColors.white : AppColors.espresso,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
}

/// بطاقة الدور — تظهر لصاحبها فقط.
class MyRoleCard extends StatelessWidget {
  const MyRoleCard({super.key, required this.role});
  final MyMafiaRole role;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool isMafia = role.isMafia;
    final Color tone = isMafia ? AppColors.danger : AppColors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.from(tone),
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        boxShadow: AppTheme.glow(tone, opacity: 0.32, blur: 24, y: 10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white.op(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(isMafia ? Icons.masks_rounded : Icons.shield_rounded,
                    size: 21, color: AppColors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.t('your_role'),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white.op(0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.mafiaRole(role.role.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.t('role_${role.role.name}_desc'),
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.white.op(0.9),
            ),
          ),
          if (role.partners.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.white.op(0.2)),
            const SizedBox(height: 10),
            Text(
              l10n.t('mafia_partners'),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.white.op(0.85),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: role.partners
                  .map((MafiaPartner p) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.white.op(0.2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          p.nickname,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// صف لاعب قابل للاستهداف (قتل / إنقاذ / تحقيق / إعدام).
class _TargetTile extends StatelessWidget {
  const _TargetTile({
    required this.player,
    required this.actionLabel,
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  final RoomPlayer player;
  final String actionLabel;
  final IconData icon;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.white.op(0.05) : AppColors.white.op(0.66),
          borderRadius: BorderRadius.circular(AppTheme.rMd),
          border: Border.all(
              color: (isDark ? AppColors.white : AppColors.coffee).op(0.10)),
        ),
        child: Row(
          children: <Widget>[
            AppAvatar(avatarKey: player.avatarKey, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                player.nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w800, color: ink),
              ),
            ),
            Pressable(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: AppGradients.from(tone),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: AppTheme.glow(tone, opacity: 0.28, blur: 14, y: 5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(icon, size: 15, color: AppColors.white),
                    const SizedBox(width: 6),
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NightView extends StatelessWidget {
  const _NightView({required this.ctx, required this.role});
  final GameRoundContext ctx;
  final MyMafiaRole role;

  Future<void> _act(BuildContext context, String targetId) async {
    try {
      await ctx.controller.submitMafiaAction(role.nightAction!, targetId);
      if (context.mounted) context.showSnack(context.l10n.t('action_sent'));
    } catch (e) {
      if (context.mounted) {
        context.showSnack(
            ErrorMapper.map(e).localized(context.l10n.languageCode), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    if (!role.isAlive) {
      return _DeadNotice(message: l10n.t('you_are_dead'));
    }

    if (!role.canActAtNight) {
      return Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MyRoleCard(role: role),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('😴', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    l10n.t('night_hint'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600, color: muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (ctx.state.actionSent) {
      final bool? investigation = ctx.state.lastInvestigation;
      return Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MyRoleCard(role: role),
          ),
          if (investigation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (investigation ? AppColors.danger : AppColors.green)
                      .op(isDark ? 0.18 : 0.14),
                  borderRadius: BorderRadius.circular(AppTheme.rMd),
                  border: Border.all(
                      color: (investigation ? AppColors.danger : AppColors.green)
                          .op(0.4)),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      investigation
                          ? Icons.warning_amber_rounded
                          : Icons.verified_rounded,
                      size: 22,
                      color: investigation ? AppColors.danger : AppColors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l10n.t('investigation_result'),
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: muted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            investigation
                                ? l10n.t('is_mafia')
                                : l10n.t('is_not_mafia'),
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Expanded(child: WaitingForOthers()),
        ],
      );
    }

    final List<RoomPlayer> targets = ctx.state.alivePlayers
        .where((RoomPlayer p) =>
            role.role != MafiaRole.detective || p.userId != ctx.myUserId)
        .where((RoomPlayer p) => role.role != MafiaRole.mafia || p.userId != ctx.myUserId)
        .toList();

    final Color tone = switch (role.role) {
      MafiaRole.mafia => AppColors.danger,
      MafiaRole.doctor => AppColors.green,
      MafiaRole.detective => AppColors.teal,
      _ => AppColors.gold,
    };
    final IconData icon = switch (role.role) {
      MafiaRole.mafia => Icons.dangerous_rounded,
      MafiaRole.doctor => Icons.healing_rounded,
      MafiaRole.detective => Icons.search_rounded,
      _ => Icons.check_rounded,
    };

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: <Widget>[
        MyRoleCard(role: role),
        const SizedBox(height: 16),
        Text(
          l10n.t('choose_target'),
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: ink,
          ),
        ),
        const SizedBox(height: 12),
        ...targets.map((RoomPlayer p) => _TargetTile(
              player: p,
              actionLabel: l10n.t('confirm'),
              icon: icon,
              tone: tone,
              onTap: () => _act(context, p.userId),
            )),
      ],
    );
  }
}

class _DayVoteView extends StatelessWidget {
  const _DayVoteView({required this.ctx, required this.role});
  final GameRoundContext ctx;
  final MyMafiaRole role;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;

    if (!role.isAlive) {
      return _DeadNotice(message: l10n.t('you_are_dead'));
    }

    final List<RoomPlayer> targets = ctx.state.alivePlayers
        .where((RoomPlayer p) => p.userId != ctx.myUserId)
        .toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: <Widget>[
        MyRoleCard(role: role),
        const SizedBox(height: 16),
        Text(
          l10n.t('vote_now'),
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: ink,
          ),
        ),
        const SizedBox(height: 12),
        ...targets.map((RoomPlayer p) => _TargetTile(
              player: p,
              actionLabel: l10n.t('vote'),
              icon: Icons.how_to_vote_rounded,
              tone: AppColors.rose,
              onTap: () async {
                try {
                  await ctx.controller.castVote(kind: 'lynch', targetUser: p.userId);
                  if (context.mounted) context.showSnack(l10n.t('your_vote'));
                } catch (e) {
                  if (context.mounted) {
                    context.showSnack(
                        ErrorMapper.map(e).localized(l10n.languageCode), error: true);
                  }
                }
              },
            )),
      ],
    );
  }
}

class _DeadNotice extends StatelessWidget {
  const _DeadNotice({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('💀', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MafiaResultView extends StatelessWidget {
  const _MafiaResultView({required this.ctx});
  final GameRoundContext ctx;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;

    final Map<String, dynamic> result = ctx.state.round?.result ?? <String, dynamic>{};
    final String stage = '${result['stage'] ?? ''}';

    String emoji;
    String title;
    String subtitle;

    if (stage == 'night_result') {
      final bool saved = (result['saved'] ?? false) as bool;
      final String? killed = result['killed_nickname'] as String?;
      if (killed == null) {
        emoji = saved ? '🚑' : '🌅';
        title = l10n.t('nobody_died');
        subtitle = saved ? l10n.t('saved_by_doctor') : '';
      } else {
        emoji = '💀';
        title = '${l10n.t('killed_tonight')}: $killed';
        subtitle = '';
      }
    } else {
      final String? lynched = result['lynched_nickname'] as String?;
      if (lynched == null) {
        emoji = '🤝';
        title = l10n.t('no_lynch');
        subtitle = '';
      } else {
        emoji = '⚖️';
        title = '$lynched — ${l10n.t('lynched')}';
        final String? roleName = result['lynched_role'] as String?;
        subtitle = roleName == null ? '' : l10n.mafiaRole(roleName);
      }
    }

    final String? winningSide = result['winning_side'] as String?;

    return Stack(
      children: <Widget>[
        Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: FadeInUp(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(emoji, style: const TextStyle(fontSize: 72)),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 22,
                      height: 1.35,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: GlassPill(label: subtitle, color: AppColors.gold),
                    ),
                  if (winningSide != null) ...<Widget>[
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppGradients.from(winningSide == 'mafia'
                            ? AppColors.danger
                            : AppColors.green),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: AppTheme.glow(
                          winningSide == 'mafia'
                              ? AppColors.danger
                              : AppColors.green,
                          opacity: 0.36,
                          blur: 26,
                          y: 10,
                        ),
                      ),
                      child: Text(
                        winningSide == 'mafia'
                            ? l10n.t('mafia_wins')
                            : l10n.t('citizens_wins'),
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (winningSide == 'citizens')
          const IgnorePointer(child: ConfettiOverlay(count: 80)),
      ],
    );
  }
}
