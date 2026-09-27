import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/connection_banner.dart';
import '../../../core/widgets/design_kit.dart';
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
        backgroundColor: Colors.transparent,
        body: AuroraBackground(
          intensity: 0.85,
          child: SafeArea(
            bottom: false,
            child: async.when(
              loading: () => const LoadingView(),
              error: (Object e, _) => Column(
                children: <Widget>[
                  ScreenHeader(title: l10n.t('room'), onBack: _confirmLeave),
                  Expanded(child: ErrorView(error: e, onRetry: controller.hardRefresh)),
                ],
              ),
              data: (RoomState state) {
                final Room? room = state.room;
                if (room == null) {
                  return Column(
                    children: <Widget>[
                      ScreenHeader(title: l10n.t('room'), onBack: _confirmLeave),
                      Expanded(child: EmptyView(message: l10n.t('not_found'))),
                    ],
                  );
                }
                final bool isHost = room.isHost(controller.myId);

                return Column(
                  children: <Widget>[
                    ConnectionBanner(realtimeStatus: state.realtime),
                    ScreenHeader(
                      title: room.title.isEmpty ? l10n.t('room') : room.title,
                      subtitle: '#${room.code}',
                      backIcon: Icons.close_rounded,
                      onBack: _confirmLeave,
                      actions: <Widget>[
                        GlassIconButton(
                          icon: Icons.copy_all_outlined,
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: room.code));
                            if (context.mounted) context.showSnack(l10n.t('copied'));
                          },
                        ),
                        if (isHost && room.status == RoomStatus.playing) ...<Widget>[
                          const SizedBox(width: 8),
                          GlassIconButton(
                            icon: Icons.stop_circle_outlined,
                            color: AppColors.danger,
                            onTap: () => _run(controller.abortGame),
                          ),
                        ],
                      ],
                    ),
                    Expanded(
                      child: _RoomBody(
                        roomId: widget.roomId,
                        state: state,
                        controller: controller,
                        isHost: isHost,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
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

/// شريط تبويب زجاجي بمؤشّر متدرّج — يحلّ محلّ [TabBar] الافتراضي.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.tabs, this.accent});

  final List<String> tabs;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color tone = accent ?? AppColors.gold;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.white.op(0.06) : AppColors.white.op(0.55),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
            color: (isDark ? AppColors.white : AppColors.coffee).op(0.12)),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        splashBorderRadius: BorderRadius.circular(100),
        indicator: BoxDecoration(
          gradient: AppGradients.from(tone),
          borderRadius: BorderRadius.circular(100),
          boxShadow: AppTheme.glow(tone, opacity: 0.34, blur: 16, y: 5),
        ),
        labelColor: AppColors.white,
        unselectedLabelColor: muted,
        labelStyle: const TextStyle(
            fontFamily: AppTheme.fontBody, fontSize: 13.5, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(
            fontFamily: AppTheme.fontBody, fontSize: 13.5, fontWeight: FontWeight.w700),
        tabs: tabs
            .map((String t) => Tab(
                  height: 38,
                  child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
      ),
    );
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    final Room room = state.room!;
    final List<RoomPlayer> players = state.activePlayers;
    final RoomPlayer? me = state.playerById(controller.myId);
    final bool canStart = state.canStart;
    final int readyCount = players.where((RoomPlayer p) => p.isReady).length;

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
          // ── بطاقة رمز الغرفة ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: FadeInUp(
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                glowColor: AppColors.gold,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: room.code));
                  if (context.mounted) context.showSnack(l10n.t('copied'));
                },
                child: Column(
                  children: <Widget>[
                    Text(
                      l10n.t('share_code_hint'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: muted),
                    ),
                    const SizedBox(height: 10),
                    ShaderMask(
                      shaderCallback: (Rect r) => AppGradients.gold.createShader(r),
                      child: Text(
                        room.code,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 40,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 10,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: <Widget>[
                        GlassPill(
                          dense: true,
                          icon: Icons.groups_2_outlined,
                          label: '${players.length}/${room.maxPlayers}',
                          color: AppColors.green,
                        ),
                        GlassPill(
                          dense: true,
                          icon: Icons.verified_outlined,
                          label: '$readyCount ${l10n.t('ready')}',
                          color: AppColors.gold,
                        ),
                        GlassPill(
                          dense: true,
                          icon: Icons.star_rounded,
                          label: state.playerById(room.hostId)?.nickname ?? '—',
                          color: AppColors.coffee,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          GlassTabBar(tabs: <String>[
            '${l10n.t('players')} (${players.length})',
            l10n.t('chat'),
          ]),

          Expanded(
            child: TabBarView(
              children: <Widget>[
                ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                        child: Text(
                          l10n.t('spectators'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: muted,
                          ),
                        ),
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

          // ── شريط الإجراءات ────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (me != null && !me.isSpectator)
                        Expanded(
                          child: me.isReady
                              ? GhostButton(
                                  label: l10n.t('cancel_ready'),
                                  icon: Icons.close_rounded,
                                  height: 54,
                                  onTap: () => run(() => controller.setReady(false)),
                                )
                              : GradientButton(
                                  label: l10n.t('im_ready'),
                                  icon: Icons.check_rounded,
                                  height: 54,
                                  colors: const <Color>[
                                    AppColors.greenLight,
                                    AppColors.greenDeep,
                                  ],
                                  onTap: () => run(() => controller.setReady(true)),
                                ),
                        ),
                      if (isHost) ...<Widget>[
                        if (me != null && !me.isSpectator) const SizedBox(width: 10),
                        Expanded(
                          child: canStart
                              ? GradientButton(
                                  label: l10n.t('start_game'),
                                  icon: Icons.play_arrow_rounded,
                                  height: 54,
                                  onTap: () => run(() => controller.startGame()),
                                )
                              : GhostButton(
                                  label: l10n.t('start_game'),
                                  icon: Icons.play_arrow_rounded,
                                  height: 54,
                                  onTap: null,
                                ),
                        ),
                      ],
                    ],
                  ),
                  if (!isHost)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.t('waiting_for_host'),
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: muted),
                      ),
                    ),
                ],
              ),
            ),
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
          GlassTabBar(
            accent: round.isMafiaNight ? AppColors.plum : AppColors.gold,
            tabs: <String>[l10n.t('round'), l10n.t('chat')],
          ),
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        Center(
          child: GlassPill(
            icon: Icons.visibility_outlined,
            label: l10n.t('spectators'),
            color: AppColors.plum,
          ),
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
