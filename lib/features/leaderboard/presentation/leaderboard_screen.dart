import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/leaderboard_provider.dart';

const List<String> _scopes = <String>['global', 'arab', 'yemen'];
const List<String> _periods = <String>['week', 'month', 'all'];

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final LeaderboardQuery query = ref.watch(leaderboardQueryProvider);
    final AsyncValue<List<LeaderboardEntry>> async = ref.watch(leaderboardProvider);
    final String? myId = ref.watch(profileProvider).valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('leaderboard'))),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: <Widget>[
                SegmentedButton<String>(
                  segments: _scopes
                      .map((String s) => ButtonSegment<String>(
                          value: s, label: Text(l10n.t('scope_$s'))))
                      .toList(),
                  selected: <String>{query.scope},
                  onSelectionChanged: (Set<String> v) => ref
                      .read(leaderboardQueryProvider.notifier)
                      .state = query.copyWith(scope: v.first),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: _periods
                      .map((String p) => ButtonSegment<String>(
                          value: p, label: Text(l10n.t('period_$p'))))
                      .toList(),
                  selected: <String>{query.period},
                  onSelectionChanged: (Set<String> v) => ref
                      .read(leaderboardQueryProvider.notifier)
                      .state = query.copyWith(period: v.first),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingView(),
              error: (Object e, _) =>
                  ErrorView(error: e, onRetry: () => ref.invalidate(leaderboardProvider)),
              data: (List<LeaderboardEntry> list) {
                if (list.isEmpty) {
                  return EmptyView(
                      icon: Icons.leaderboard_outlined, message: l10n.t('no_leaderboard'));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(leaderboardProvider),
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, int i) {
                      final LeaderboardEntry e = list[i];
                      final bool isMe = e.userId == myId;
                      return Card(
                        color: isMe
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: SizedBox(
                            width: 62,
                            child: Row(
                              children: <Widget>[
                                SizedBox(
                                  width: 24,
                                  child: Text(_medal(e.rank),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                                AppAvatar(avatarKey: e.avatarKey, size: 34),
                              ],
                            ),
                          ),
                          title: Text(e.nickname,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${l10n.t('level')} ${e.level} • '
                              '${e.wins}/${e.games} ${l10n.t('games_won')}'),
                          trailing: Text('${e.points}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _medal(int rank) => switch (rank) {
        1 => '🥇',
        2 => '🥈',
        3 => '🥉',
        _ => '$rank',
      };
}
