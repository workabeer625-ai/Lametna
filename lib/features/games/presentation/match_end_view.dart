import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/room_provider.dart';

/// نهاية المباراة: الترتيب النهائي، الفائزون، وإعادة اللعب.
class MatchEndView extends ConsumerWidget {
  const MatchEndView({
    super.key,
    required this.roomId,
    required this.state,
    required this.controller,
    required this.isHost,
  });

  final String roomId;
  final RoomState state;
  final RoomController controller;
  final bool isHost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final GameSession? session = state.session;
    final List<Map<String, dynamic>> standings = session?.standings ?? <Map<String, dynamic>>[];
    final List<String> winners = session?.winners ?? <String>[];
    final bool iWon = winners.contains(controller.myId);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
        await ref.read(profileProvider.notifier).refresh();
      } catch (e) {
        if (context.mounted) {
          context.showSnack(ErrorMapper.map(e).localized(l10n.languageCode), error: true);
        }
      }
    }

    return SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Center(
                  child: Column(
                    children: <Widget>[
                      Text(iWon ? '🏆' : '🎉', style: const TextStyle(fontSize: 72)),
                      const SizedBox(height: 8),
                      Text(l10n.t('match_over'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (session?.result?['reason'] == 'mafia_mafia')
                        Text(l10n.t('mafia_wins'),
                            style: Theme.of(context).textTheme.titleMedium)
                      else if (session?.result?['reason'] == 'mafia_citizens')
                        Text(l10n.t('citizens_wins'),
                            style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(l10n.t('final_results'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (standings.isEmpty)
                  Text(l10n.t('empty'))
                else
                  ...standings.asMap().entries.map((MapEntry<int, Map<String, dynamic>> e) {
                    final Map<String, dynamic> row = e.value;
                    final bool isWinner = winners.contains(row['user_id']);
                    return Card(
                      color: isWinner
                          ? Theme.of(context).colorScheme.tertiaryContainer
                          : null,
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(
                              width: 24,
                              child: Text('${e.key + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            AppAvatar(avatarKey: row['avatar_key'] as String?, size: 36),
                          ],
                        ),
                        title: Text('${row['nickname']}'),
                        trailing: Text('${row['score']} ${l10n.t('points')}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await controller.leave();
                      if (context.mounted) context.go('/home');
                    },
                    icon: const Icon(Icons.home_outlined),
                    label: Text(l10n.t('home')),
                  ),
                ),
                if (isHost) ...<Widget>[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => run(controller.playAgain),
                      icon: const Icon(Icons.replay),
                      label: Text(l10n.t('play_again')),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
