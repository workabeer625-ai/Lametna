import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/app_avatar.dart';
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
  const MafiaGame();

  @override
  String get key => GameKeys.mafia;

  @override
  bool get hasSecretRoles => true;

  @override
  Widget buildRound(BuildContext context, GameRoundContext ctx) => _MafiaRoundView(ctx: ctx);

  @override
  Widget? buildRoundResult(BuildContext context, GameRoundContext ctx) =>
      _MafiaResultView(ctx: ctx);
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
        color: isNight ? AppColors.night : AppColors.day,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(isNight ? '🌙' : '☀️', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(
              isNight ? context.l10n.t('night_phase') : context.l10n.t('day_phase'),
              style: TextStyle(
                color: isNight ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
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
    return Card(
      color: isMafia
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(isMafia ? Icons.masks : Icons.shield_outlined),
                const SizedBox(width: 8),
                Text('${l10n.t('your_role')}: ${l10n.mafiaRole(role.role.name)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            Text(l10n.t('role_${role.role.name}_desc'),
                style: Theme.of(context).textTheme.bodySmall),
            if (role.partners.isNotEmpty) ...<Widget>[
              const Divider(height: 18),
              Text(l10n.t('mafia_partners'),
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: role.partners
                    .map((MafiaPartner p) => Chip(
                          label: Text(p.nickname),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
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
                  const SizedBox(height: 10),
                  Text(l10n.t('night_hint'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium),
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
              padding: const EdgeInsets.all(16),
              child: Card(
                color: investigation
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.secondaryContainer,
                child: ListTile(
                  leading: Icon(investigation ? Icons.warning_amber : Icons.verified_outlined),
                  title: Text(l10n.t('investigation_result')),
                  subtitle: Text(investigation ? l10n.t('is_mafia') : l10n.t('is_not_mafia'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        MyRoleCard(role: role),
        const SizedBox(height: 12),
        Text(l10n.t('choose_target'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...targets.map((RoomPlayer p) => Card(
              child: ListTile(
                leading: AppAvatar(avatarKey: p.avatarKey, size: 40),
                title: Text(p.nickname),
                trailing: FilledButton(
                  onPressed: () => _act(context, p.userId),
                  child: Text(l10n.t('confirm')),
                ),
              ),
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

    if (!role.isAlive) {
      return _DeadNotice(message: l10n.t('you_are_dead'));
    }

    final List<RoomPlayer> targets = ctx.state.alivePlayers
        .where((RoomPlayer p) => p.userId != ctx.myUserId)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        MyRoleCard(role: role),
        const SizedBox(height: 12),
        Text(l10n.t('vote_now'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...targets.map((RoomPlayer p) => Card(
              child: ListTile(
                leading: AppAvatar(avatarKey: p.avatarKey, size: 40),
                title: Text(p.nickname),
                trailing: OutlinedButton.icon(
                  onPressed: () async {
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
                  icon: const Icon(Icons.how_to_vote_outlined, size: 18),
                  label: Text(l10n.t('vote')),
                ),
              ),
            )),
      ],
    );
  }
}

class _DeadNotice extends StatelessWidget {
  const _DeadNotice({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('💀', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      );
}

class _MafiaResultView extends StatelessWidget {
  const _MafiaResultView({required this.ctx});
  final GameRoundContext ctx;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(subtitle, style: Theme.of(context).textTheme.titleMedium),
              ),
            if (winningSide != null) ...<Widget>[
              const SizedBox(height: 24),
              Text(
                winningSide == 'mafia' ? l10n.t('mafia_wins') : l10n.t('citizens_wins'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
