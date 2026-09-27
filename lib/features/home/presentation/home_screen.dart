import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/section_card.dart';
import '../../../models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/catalog_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final Profile? profile = ref.watch(profileProvider).valueOrNull;
    final List<GameDef> games = ref.watch(gamesProvider).valueOrNull ?? <GameDef>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('app_name')),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.t('settings'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gamesProvider);
          await ref.read(profileProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: <Widget>[
            _GreetingCard(profile: profile),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _ActionTile(
                    icon: Icons.add_circle_outline,
                    label: l10n.t('create_room'),
                    color: AppColors.green,
                    onTap: () => context.push('/create-room'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.vpn_key_outlined,
                    label: l10n.t('join_by_code'),
                    color: AppColors.gold,
                    onTap: () => context.push('/join'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.public,
              label: l10n.t('public_rooms'),
              color: AppColors.coffee,
              wide: true,
              onTap: () => context.push('/public-rooms'),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(l10n.t('games'),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => context.go('/games'),
                  child: Text(l10n.t('all_games')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (games.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else
              ...games.take(4).map((GameDef g) => _GameRow(game: g)),
          ],
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({this.profile});
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return SectionCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: <Widget>[
          AppAvatar(avatarKey: profile?.avatarKey, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${l10n.t('welcome_back')}، ${profile?.nickname ?? '—'}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '${l10n.t('level')} ${profile?.level ?? 1}  •  '
                  '${profile?.totalPoints ?? 0} ${l10n.t('points')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) => Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            child: wide
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(icon, color: color),
                      const SizedBox(width: 10),
                      Text(label,
                          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    ],
                  )
                : Column(
                    children: <Widget>[
                      Icon(icon, color: color, size: 28),
                      const SizedBox(height: 8),
                      Text(label,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ),
      );
}

class _GameRow extends ConsumerWidget {
  const _GameRow({required this.game});
  final GameDef game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String locale = context.l10n.languageCode;
    return Card(
      child: ListTile(
        leading: Text(game.icon, style: const TextStyle(fontSize: 30)),
        title: Text(game.name(locale),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(game.description(locale), maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/create-room?game=${game.key}'),
      ),
    );
  }
}
