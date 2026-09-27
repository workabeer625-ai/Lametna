import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/connection_banner.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/models.dart';
import '../../../providers/room_provider.dart';
import '../../games/engine/game_definition.dart';
import '../../games/presentation/match_end_view.dart';
import '../../games/presentation/round_result_view.dart';
import 'widgets/chat_panel.dart';
import 'widgets/player_actions_sheet.dart';
import 'widgets/player_tile.dart';

/// شاشة الغرفة — تتبدّل تلقائيًا حسب حالة الغرفة القادمة من Realtime:
/// انتظار → لعب → نتيجة جولة → نهاية المباراة.
class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key, required this.roomId});
  final String roomId;

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  Future<void> _confirmLeave() async {
    final AppLocalizations l10n = context.l10n;
    final bool leave = await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: Text(l10n.t('leave_room')),
            content: Text(l10n.t('leave_confirm')),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('cancel'))),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.t('confirm'))),
            ],
          ),
        ) ??
        false;
    if (!leave) return;
    try {
      await ref.read(roomControllerProvider(widget.roomId).notifier).leave();
    } catch (_) {
      // حتى لو فشل النداء، نخرج من الشاشة؛ الخادم ينظّف الغرف الخاملة تلقائيًا
    }
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<RoomState> async = ref.watch(roomControllerProvider(widget.roomId));
    final RoomController controller =
        ref.read(roomControllerProvider(widget.roomId).notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        body: async.when(
          loading: () => const LoadingView(),
          error: (Object e, _) => Scaffold(
            appBar: AppBar(),
            body: ErrorView(error: e, onRetry: controller.hardRefresh),
          ),
          data: (RoomState state) {
            final Room? room = state.room;
            if (room == null) {
              return Scaffold(
                appBar: AppBar(),
                body: EmptyView(message: l10n.t('not_found')),
              );
            }
            final bool isHost = room.isHost(controller.myId);

            return Column(
              children: <Widget>[
                ConnectionBanner(realtimeStatus: state.realtime),
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _confirmLeave,
                        tooltip: l10n.t('leave_room'),
                      ),
                      title: Column(
                        children: <Widget>[
                          Text(room.title.isEmpty ? l10n.t('room') : room.title,
                              style: const TextStyle(fontSize: 16)),
                          Text('#${room.code}',
                              style: const TextStyle(fontSize: 12, letterSpacing: 2)),
                        ],
                      ),
                      actions: <Widget>[
                        IconButton(
                          tooltip: l10n.t('copy'),
                          icon: const Icon(Icons.copy_all_outlined),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: room.code));
                            if (context.mounted) context.showSnack(l10n.t('copied'));
                          },
                        ),
                        if (isHost && room.status == RoomStatus.playing)
                          IconButton(
                            tooltip: l10n.t('abort_game'),
                            icon: const Icon(Icons.stop_circle_outlined),
                            onPressed: () => _run(controller.abortGame),
                          ),
                      ],
                    ),
                    body: _RoomBody(
                      roomId: widget.roomId,
                      state: state,
                      controller: controller,
                      isHost: isHost,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        context.showSnack(ErrorMapper.map(e).localized(context.l10n.languageCode), error: true);
      }
    }
  }
}

class _RoomBody extends ConsumerWidget {
  const _RoomBody({
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
    final Room room = state.room!;

    switch (room.status) {
      case RoomStatus.waiting:
      case RoomStatus.starting:
        return WaitingRoomView(
            roomId: roomId, state: state, controller: controller, isHost: isHost);
      case RoomStatus.playing:
      case RoomStatus.paused:
        return _PlayingView(
            roomId: roomId, state: state, controller: controller, isHost: isHost);
      case RoomStatus.finished:
      case RoomStatus.cancelled:
        return MatchEndView(
            roomId: roomId, state: state, controller: controller, isHost: isHost);
    }
  }
}

/// غرفة الانتظار: قائمة اللاعبين + الجاهزية + الدردشة + بدء المباراة.
class WaitingRoomView extends ConsumerWidget {
  const WaitingRoomView({
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
    final Room room = state.room!;
    final List<RoomPlayer> players = state.activePlayers;
    final RoomPlayer? me = state.playerById(controller.myId);
    final bool canStart = state.canStart;

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        if (context.mounted) {
          context.showSnack(ErrorMapper.map(e).localized(l10n.languageCode), error: true);
        }
      }
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: <Widget>[
                Text(l10n.t('share_code_hint'),
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(room.code,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 10,
                          color: Theme.of(context).colorScheme.primary,
                        )),
                const SizedBox(height: 6),
                Text('${players.length}/${room.maxPlayers} ${l10n.t('players')}  •  '
                    '${l10n.t('host')}: ${state.playerById(room.hostId)?.nickname ?? '—'}'),
              ],
            ),
          ),
          TabBar(tabs: <Widget>[
            Tab(text: '${l10n.t('players')} (${players.length})'),
            Tab(text: l10n.t('chat')),
          ]),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                ListView(
                  children: <Widget>[
                    ...players.map((RoomPlayer p) => PlayerTile(
                          player: p,
                          isHost: p.userId == room.hostId,
                          isMe: p.userId == controller.myId,
                          onTap: p.userId == controller.myId
                              ? null
                              : () => showPlayerActionsSheet(
                                    context: context,
                                    ref: ref,
                                    roomId: roomId,
                                    userId: p.userId,
                                    nickname: p.nickname,
                                    isHost: isHost,
                                    isMuted: p.isMuted,
                                  ),
                        )),
                    if (state.spectators.isNotEmpty) ...<Widget>[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(l10n.t('spectators'),
                            style: Theme.of(context).textTheme.labelLarge),
                      ),
                      ...state.spectators.map((RoomPlayer p) => PlayerTile(
                            player: p,
                            isHost: false,
                            isMe: p.userId == controller.myId,
                            showReady: false,
                          )),
                    ],
                  ],
                ),
                ChatPanel(roomId: roomId, state: state),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  if (me != null && !me.isSpectator)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => run(() => controller.setReady(!me.isReady)),
                        icon: Icon(me.isReady ? Icons.close : Icons.check),
                        label: Text(me.isReady ? l10n.t('cancel_ready') : l10n.t('im_ready')),
                      ),
                    ),
                  if (isHost) ...<Widget>[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            canStart ? () => run(() => controller.startGame()) : null,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.t('start_game')),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!isHost)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l10n.t('waiting_for_host'),
                  style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// أثناء اللعب: واجهة اللعبة + النتائج + دردشة جانبية.
class _PlayingView extends ConsumerWidget {
  const _PlayingView({
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
    final GameRound? round = state.round;
    final GameDefinition? definition = GameRegistry.of(state.session?.gameKey ?? '');

    if (round == null || definition == null) {
      return const LoadingView();
    }

    final GameRoundContext ctx = GameRoundContext(
      roomId: roomId,
      state: state,
      controller: controller,
      myUserId: controller.myId,
    );

    final RoomPlayer? me = state.playerById(controller.myId);
    final bool isDead = me != null && !me.isAlive;
    final bool isSpectator = me?.isSpectator ?? false;

    final Widget gameArea = round.isResolved
        ? RoundResultView(ctx: ctx, definition: definition)
        : (isSpectator
            ? _SpectatorView(state: state)
            : definition.buildRound(context, ctx));

    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          TabBar(tabs: <Widget>[
            Tab(text: l10n.t('round')),
            Tab(text: l10n.t('chat')),
          ]),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                gameArea,
                ChatPanel(
                  roomId: roomId,
                  state: state,
                  channel: (state.myRole?.isMafia ?? false) && round.isMafiaNight
                      ? 'mafia'
                      : 'public',
                  enabled: !isDead && !isSpectator,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpectatorView extends StatelessWidget {
  const _SpectatorView({required this.state});
  final RoomState state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Center(
          child: Text(l10n.t('spectators'),
              style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 16),
        ...state.activePlayers.map((RoomPlayer p) => PlayerTile(
              player: p,
              isHost: p.userId == state.room?.hostId,
              showReady: false,
            )),
      ],
    );
  }
}
