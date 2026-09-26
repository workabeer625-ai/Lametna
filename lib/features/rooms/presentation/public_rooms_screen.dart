import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/models.dart';
import '../../../providers/catalog_provider.dart';
import '../../../providers/rooms_provider.dart';

class PublicRoomsScreen extends ConsumerStatefulWidget {
  const PublicRoomsScreen({super.key, this.gameKey});
  final String? gameKey;

  @override
  ConsumerState<PublicRoomsScreen> createState() => _PublicRoomsScreenState();
}

class _PublicRoomsScreenState extends ConsumerState<PublicRoomsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.gameKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(publicRoomsFilterProvider.notifier).state = widget.gameKey;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<Room>> rooms = ref.watch(publicRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('public_rooms')),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(publicRoomsProvider),
          ),
        ],
      ),
      body: rooms.when(
        loading: () => const LoadingView(),
        error: (Object e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(publicRoomsProvider)),
        data: (List<Room> list) {
          if (list.isEmpty) {
            return EmptyView(
              icon: Icons.meeting_room_outlined,
              message: l10n.t('no_public_rooms'),
              action: FilledButton.icon(
                onPressed: () => context.push('/create-room'),
                icon: const Icon(Icons.add),
                label: Text(l10n.t('create_room')),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(publicRoomsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: list.length,
              itemBuilder: (_, int i) => _RoomCard(room: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _RoomCard extends ConsumerWidget {
  const _RoomCard({required this.room});
  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final GameDef? game = ref.watch(gameByKeyProvider(room.gameKey));
    final bool joinable = !room.isFull && room.status == RoomStatus.waiting;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Text(game?.icon ?? '🎮', style: const TextStyle(fontSize: 30)),
        title: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                room.title.isEmpty
                    ? (game?.name(l10n.languageCode) ?? room.gameKey)
                    : room.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (room.hasPassword) const Icon(Icons.lock, size: 15),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 10,
            children: <Widget>[
              Text('${room.playerCount}/${room.maxPlayers} ${l10n.t('players')}'),
              Text('#${room.code}',
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              if (room.status == RoomStatus.playing)
                Text(l10n.t('start_game'),
                    style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
            ],
          ),
        ),
        trailing: FilledButton(
          onPressed: () => context.push('/join?code=${room.code}'),
          child: Text(joinable ? l10n.t('join') : l10n.t('join_as_spectator')),
        ),
      ),
    );
  }
}
