import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/models.dart';
import '../../../providers/catalog_provider.dart';

const List<String> _categories = <String>[
  'yemeni', 'arabic', 'global', 'family', 'fast', 'competitive',
];

class GamesListScreen extends ConsumerWidget {
  const GamesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<GameDef>> async = ref.watch(gamesProvider);
    final String? filter = ref.watch(gameCategoryFilterProvider);
    final List<GameDef> games = ref.watch(filteredGamesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('games'))),
      body: async.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(gamesProvider)),
        data: (_) => Column(
          children: <Widget>[
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: FilterChip(
                      label: Text(l10n.t('all_games')),
                      selected: filter == null,
                      onSelected: (_) =>
                          ref.read(gameCategoryFilterProvider.notifier).state = null,
                    ),
                  ),
                  ..._categories.map((String c) => Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: FilterChip(
                          label: Text(l10n.category(c)),
                          selected: filter == c,
                          onSelected: (bool v) => ref
                              .read(gameCategoryFilterProvider.notifier)
                              .state = v ? c : null,
                        ),
                      )),
                ],
              ),
            ),
            Expanded(
              child: games.isEmpty
                  ? EmptyView(message: l10n.t('empty'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: games.length,
                      itemBuilder: (_, int i) => _GameCard(game: games[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});
  final GameDef game;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String locale = l10n.languageCode;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(game.icon, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(game.name(locale),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(game.description(locale), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                _Pill(icon: Icons.group_outlined,
                    text: '${game.minPlayers}–${game.maxPlayers}'),
                _Pill(icon: Icons.timer_outlined,
                    text: '${game.roundSeconds}${l10n.t('seconds')}'),
                ...game.categories.map((String c) => Chip(
                      label: Text(l10n.category(c)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push('/create-room?game=${game.key}'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.t('create_room')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/public-rooms?game=${game.key}'),
                    icon: const Icon(Icons.public),
                    label: Text(l10n.t('public_rooms')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(text, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      );
}
