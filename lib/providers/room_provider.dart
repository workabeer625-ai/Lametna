import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/server_clock.dart';
import '../models/models.dart';
import '../services/realtime_service.dart';
import '../services/supabase_service.dart';
import 'core_providers.dart';

@immutable
class RoomState {
  const RoomState({
    this.room,
    this.players = const <RoomPlayer>[],
    this.messages = const <ChatMessage>[],
    this.session,
    this.round,
    this.myRole,
    this.roundAnswers = const <Map<String, dynamic>>[],
    this.realtime = RealtimeStatus.connecting,
    this.hasSubmitted = false,
    this.hasVoted = false,
    this.lastInvestigation,
    this.actionSent = false,
  });

  final Room? room;
  final List<RoomPlayer> players;
  final List<ChatMessage> messages;
  final GameSession? session;
  final GameRound? round;
  final MyMafiaRole? myRole;
  final List<Map<String, dynamic>> roundAnswers;
  final RealtimeStatus realtime;
  final bool hasSubmitted;
  final bool hasVoted;
  final bool? lastInvestigation;
  final bool actionSent;

  List<RoomPlayer> get activePlayers =>
      players.where((RoomPlayer p) => p.isPresent && !p.isSpectator).toList();

  List<RoomPlayer> get spectators =>
      players.where((RoomPlayer p) => p.isPresent && p.isSpectator).toList();

  List<RoomPlayer> get alivePlayers =>
      activePlayers.where((RoomPlayer p) => p.isAlive).toList();

  bool get allReady =>
      activePlayers.isNotEmpty &&
      activePlayers.every((RoomPlayer p) => p.isReady || p.userId == room?.hostId);

  bool get canStart =>
      room != null && activePlayers.length >= room!.minPlayers && allReady;

  RoomPlayer? playerById(String? id) {
    if (id == null) return null;
    for (final RoomPlayer p in players) {
      if (p.userId == id) return p;
    }
    return null;
  }

  RoomState copyWith({
    Room? room,
    List<RoomPlayer>? players,
    List<ChatMessage>? messages,
    GameSession? session,
    GameRound? round,
    MyMafiaRole? myRole,
    List<Map<String, dynamic>>? roundAnswers,
    RealtimeStatus? realtime,
    bool? hasSubmitted,
    bool? hasVoted,
    bool? lastInvestigation,
    bool? actionSent,
    bool clearRound = false,
    bool clearInvestigation = false,
  }) =>
      RoomState(
        room: room ?? this.room,
        players: players ?? this.players,
        messages: messages ?? this.messages,
        session: session ?? this.session,
        round: clearRound ? null : (round ?? this.round),
        myRole: myRole ?? this.myRole,
        roundAnswers: roundAnswers ?? this.roundAnswers,
        realtime: realtime ?? this.realtime,
        hasSubmitted: hasSubmitted ?? this.hasSubmitted,
        hasVoted: hasVoted ?? this.hasVoted,
        lastInvestigation:
            clearInvestigation ? null : (lastInvestigation ?? this.lastInvestigation),
        actionSent: actionSent ?? this.actionSent,
      );
}

/// وحدة التحكم بالغرفة: تحميل أولي + Realtime + نبض + حسم الجولات.
class RoomController extends AutoDisposeFamilyAsyncNotifier<RoomState, String> {
  RoomRealtimeChannel? _channel;
  Timer? _heartbeat;
  Timer? _resolveWatchdog;
  String? _resolvingRoundId;

  SupabaseService get _service => ref.read(supabaseServiceProvider);
  ServerClock get _clock => ref.read(serverClockProvider);
  String get _roomId => arg;
  String? get myId => _service.currentUserId;

  @override
  Future<RoomState> build(String roomId) async {
    ref.onDispose(_cleanup);

    // إعادة اتصال فورية عند عودة الشبكة
    ref.listen<bool>(isOnlineProvider, (bool? previous, bool next) {
      if (next && previous == false) {
        unawaited(_channel?.reconnectNow());
        unawaited(hardRefresh());
      }
    });

    final RoomState initial = await _loadAll();
    await _subscribe();
    _startHeartbeat();
    _startResolveWatchdog();
    return initial;
  }

  // ---------------------------------------------------------------
  Future<RoomState> _loadAll() async {
    final Room? room = await _service.fetchRoom(_roomId);
    final List<RoomPlayer> players = await _service.fetchRoomPlayers(_roomId);
    final List<ChatMessage> messages =
        await _service.fetchMessages(_roomId, limit: AppConstants.chatHistoryLimit);
    final GameSession? session = await _service.fetchActiveSession(_roomId);

    GameRound? round;
    MyMafiaRole? myRole;
    bool submitted = false;
    List<Map<String, dynamic>> answers = const <Map<String, dynamic>>[];

    if (session != null && session.isRunning) {
      round = await _service.fetchCurrentRound(session.id);
      if (round != null) {
        submitted = await _service.hasSubmitted(round.id);
        if (round.isResolved) {
          answers = await _service.fetchRoundAnswers(round.id);
        }
      }
      if (session.gameKey == GameKeys.mafia) {
        myRole = await _service.fetchMyMafiaRole(_roomId);
      }
    }

    return RoomState(
      room: room,
      players: players,
      messages: messages,
      session: session,
      round: round,
      myRole: myRole,
      hasSubmitted: submitted,
      roundAnswers: answers,
      realtime: _channel?.status ?? RealtimeStatus.connecting,
    );
  }

  Future<void> hardRefresh() async {
    try {
      final RoomState fresh = await _loadAll();
      state = AsyncValue<RoomState>.data(fresh);
    } catch (e, st) {
      state = AsyncValue<RoomState>.error(e, st);
    }
  }

  // ---------------------------------------------------------------
  Future<void> _subscribe() async {
    _channel = RoomRealtimeChannel(
      client: ref.read(supabaseClientProvider),
      roomId: _roomId,
      onStatus: (RealtimeStatus s) => _update((RoomState st) => st.copyWith(realtime: s)),
      onRoomChanged: (Map<String, dynamic> raw) {
        try {
          _update((RoomState st) => st.copyWith(room: Room.fromMap(raw)));
        } catch (_) {
          unawaited(_refreshRoom());
        }
      },
      onPlayersChanged: () => unawaited(_refreshPlayers()),
      onMessage: (_) => unawaited(_refreshMessages()),
      onSessionChanged: (_) => unawaited(_refreshSession()),
      onRoundChanged: (Map<String, dynamic> raw) => unawaited(_onRoundChanged(raw)),
    );
    await _channel!.subscribe();
  }

  Future<void> _refreshRoom() async {
    final Room? room = await _service.fetchRoom(_roomId);
    if (room != null) _update((RoomState st) => st.copyWith(room: room));
  }

  Future<void> _refreshPlayers() async {
    final List<RoomPlayer> players = await _service.fetchRoomPlayers(_roomId);
    _update((RoomState st) => st.copyWith(players: players));
  }

  Future<void> _refreshMessages() async {
    final List<ChatMessage> messages =
        await _service.fetchMessages(_roomId, limit: AppConstants.chatHistoryLimit);
    _update((RoomState st) => st.copyWith(messages: messages));
  }

  Future<void> _refreshSession() async {
    final GameSession? session = await _service.fetchActiveSession(_roomId);
    if (session == null) return;

    MyMafiaRole? role = state.valueOrNull?.myRole;
    if (session.gameKey == GameKeys.mafia && session.isRunning) {
      role = await _service.fetchMyMafiaRole(_roomId) ?? role;
    }
    GameRound? round;
    if (session.isRunning) {
      round = await _service.fetchCurrentRound(session.id);
    }
    _update((RoomState st) => st.copyWith(
          session: session,
          round: round ?? st.round,
          myRole: role,
        ));
    await _refreshPlayers();
  }

  Future<void> _onRoundChanged(Map<String, dynamic> raw) async {
    final RoomState? current = state.valueOrNull;
    if (current?.session == null) return;
    if (raw['session_id'] != current!.session!.id) return;

    GameRound round;
    try {
      round = GameRound.fromMap(raw);
    } catch (_) {
      return;
    }

    final bool isNewRound = current.round?.id != round.id;
    List<Map<String, dynamic>> answers = current.roundAnswers;
    if (round.isResolved) {
      answers = await _service.fetchRoundAnswers(round.id);
      await _refreshPlayers();
    }

    _update((RoomState st) => st.copyWith(
          round: round,
          roundAnswers: answers,
          hasSubmitted: isNewRound ? false : st.hasSubmitted,
          hasVoted: isNewRound ? false : st.hasVoted,
          actionSent: isNewRound ? false : st.actionSent,
          clearInvestigation: isNewRound,
        ));

    if (isNewRound && current.session!.gameKey == GameKeys.mafia) {
      final MyMafiaRole? role = await _service.fetchMyMafiaRole(_roomId);
      if (role != null) _update((RoomState st) => st.copyWith(myRole: role));
    }
  }

  void _update(RoomState Function(RoomState) transform) {
    final RoomState? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue<RoomState>.data(transform(current));
  }

  // ---------------------------------------------------------------
  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(AppConstants.heartbeatInterval, (_) async {
      try {
        await _service.heartbeat(_roomId);
      } catch (_) {
        // تجاهل: النبض ليس حرجًا، وستعالج إعادة الاتصال الأمر
      }
    });
  }

  /// حارس المؤقت: عندما تنتهي مدة الجولة بحسب ساعة الخادم ولم تُحسم بعد،
  /// نطلب من الخادم حسمها. الخادم هو من يقرر فعلًا (الدالة idempotent)،
  /// وهناك أيضًا مهمة مجدولة `tick-rounds` كشبكة أمان إن خرج الجميع.
  void _startResolveWatchdog() {
    _resolveWatchdog?.cancel();
    _resolveWatchdog = Timer.periodic(const Duration(seconds: 2), (_) async {
      final RoomState? st = state.valueOrNull;
      final GameRound? round = st?.round;
      if (round == null || round.isResolved) return;
      if (!_clock.hasEnded(round.endsAt)) return;
      if (_resolvingRoundId == round.id) return;

      _resolvingRoundId = round.id;
      try {
        await _service.resolveRound(round.id);
      } catch (_) {
        // لاعب آخر أو المهمة المجدولة قد سبقتنا — لا مشكلة
      } finally {
        Future<void>.delayed(const Duration(seconds: 3), () => _resolvingRoundId = null);
      }
    });
  }

  Future<void> _cleanup() async {
    _heartbeat?.cancel();
    _resolveWatchdog?.cancel();
    await _channel?.dispose();
  }

  // =============== إجراءات اللاعب ===============

  Future<void> setReady(bool ready) async {
    await _service.setReady(_roomId, ready);
    await _refreshPlayers();
  }

  Future<void> startGame({int? rounds, Map<String, dynamic> config = const <String, dynamic>{}}) async {
    await _service.startGame(_roomId, rounds: rounds, config: config);
    await _refreshSession();
  }

  Future<void> sendMessage(String body, {String channel = 'public'}) async {
    await _service.sendMessage(_roomId, body, channel: channel);
    await _refreshMessages();
  }

  Future<void> submitAnswer(Map<String, dynamic> payload) async {
    final GameRound? round = state.valueOrNull?.round;
    if (round == null) return;
    await _service.submitAnswer(round.id, payload);
    _update((RoomState st) => st.copyWith(hasSubmitted: true));
    await _tryEarlyResolve();
  }

  Future<void> castVote({
    required String kind,
    String? targetUser,
    String? targetKey,
    bool? value,
  }) async {
    final GameRound? round = state.valueOrNull?.round;
    if (round == null) return;
    await _service.castVote(round.id,
        kind: kind, targetUser: targetUser, targetKey: targetKey, value: value);
    _update((RoomState st) => st.copyWith(hasVoted: true));
    await _tryEarlyResolve();
  }

  Future<void> submitMafiaAction(String action, String targetId) async {
    final GameRound? round = state.valueOrNull?.round;
    if (round == null) return;
    final Map<String, dynamic> result =
        await _service.submitMafiaAction(round.id, action, targetId);
    _update((RoomState st) => st.copyWith(
          actionSent: true,
          lastInvestigation: result['is_mafia'] as bool?,
        ));
    await _tryEarlyResolve();
  }

  /// محاولة حسم مبكر عندما يُنهي الجميع — الخادم يرفض إن لم يكتمل العدد.
  Future<void> _tryEarlyResolve() async {
    final GameRound? round = state.valueOrNull?.round;
    if (round == null || round.isResolved) return;
    try {
      await _service.resolveRound(round.id);
    } catch (_) {
      // الخادم أعاد "pending" أو رفض — طبيعي تمامًا
    }
  }

  Future<void> playAgain() async {
    await _service.playAgain(_roomId);
    await hardRefresh();
  }

  Future<void> abortGame() async {
    await _service.abortGame(_roomId);
    await hardRefresh();
  }

  Future<void> transferHost(String userId) async {
    await _service.transferHost(_roomId, userId);
    await _refreshRoom();
  }

  Future<void> kick(String userId) async {
    await _service.kickPlayer(_roomId, userId);
    await _refreshPlayers();
  }

  Future<void> ban(String userId) async {
    await _service.banPlayer(_roomId, userId);
    await _refreshPlayers();
  }

  Future<void> mute(String userId, bool muted) async {
    await _service.mutePlayer(_roomId, userId, muted);
    await _refreshPlayers();
  }

  Future<void> block(String userId) async {
    await _service.blockUser(userId);
    await _refreshMessages();
  }

  Future<void> report({
    required String userId,
    required String reason,
    String? details,
  }) =>
      _service.reportUser(
          reportedId: userId, reason: reason, roomId: _roomId, details: details);

  Future<void> leave() async {
    await _service.leaveRoom(_roomId);
    await _cleanup();
  }
}

final AutoDisposeAsyncNotifierProviderFamily<RoomController, RoomState, String>
    roomControllerProvider =
    AsyncNotifierProvider.autoDispose.family<RoomController, RoomState, String>(
  RoomController.new,
);
