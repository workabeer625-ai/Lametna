import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors/error_mapper.dart';
import '../core/network/env.dart';
import '../models/models.dart';

/// كل نداءات الخادم في مكان واحد.
///
/// قاعدة ثابتة: العمليات الحساسة (إنشاء غرفة، بدء مباراة، توزيع الأدوار،
/// احتساب النقاط، التصويت) تُنفَّذ عبر RPC آمنة على الخادم فقط.
class SupabaseService {
  SupabaseService(this._client);

  final SupabaseClient _client;

  SupabaseClient get client => _client;
  GoTrueClient get auth => _client.auth;
  String? get currentUserId => _client.auth.currentUser?.id;
  bool get isSignedIn => _client.auth.currentUser != null;

  /// هل الجلسة الحالية لضيف (دخول مجهول) لم يربط بريدًا بعد؟
  bool get isGuestSession => _client.auth.currentUser?.isAnonymous ?? false;

  static Future<void> initialize() async {
    if (!Env.isConfigured) {
      throw StateError(Env.missingConfigMessage);
    }
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.error,
      ),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  // ==================== المصادقة ====================

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? nickname,
    String locale = 'ar',
  }) =>
      _guard(() => _client.auth.signUp(
            email: email.trim(),
            password: password,
            data: <String, dynamic>{
              if (nickname != null && nickname.trim().isNotEmpty) 'nickname': nickname.trim(),
              'locale': locale,
              'is_guest': false,
            },
          ));

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _guard(() => _client.auth.signInWithPassword(
            email: email.trim(),
            password: password,
          ));

  /// الدخول كضيف — يستخدم Anonymous Sign-in المجاني في Supabase.
  Future<AuthResponse> signInAsGuest({String? nickname, String locale = 'ar'}) =>
      _guard(() => _client.auth.signInAnonymously(
            data: <String, dynamic>{
              if (nickname != null && nickname.trim().isNotEmpty) 'nickname': nickname.trim(),
              'locale': locale,
              'is_guest': true,
            },
          ));

  /// ترقية حساب الضيف: يربط بريدًا وكلمة مرور بنفس الحساب،
  /// فيحتفظ اللاعب بنقاطه وسجلّه ومعرّفه.
  Future<void> linkEmailToGuest({
    required String email,
    required String password,
    String? nickname,
  }) =>
      _guard(() async {
        await _client.auth.updateUser(UserAttributes(
          email: email.trim(),
          password: password,
          data: <String, dynamic>{
            if (nickname != null && nickname.trim().isNotEmpty)
              'nickname': nickname.trim(),
            'is_guest': false,
          },
        ));
        // تحديث الجلسة حتى تختفي صفة «مجهول» من الرمز المميّز.
        try {
          await _client.auth.refreshSession();
        } catch (_) {
          // غير حرج: ستتحدّث الجلسة تلقائيًا لاحقًا.
        }
        // إنزال علم is_guest في جدول profiles (يتطلب ترحيل 20240101000015).
        try {
          await _client.rpc<void>('link_guest_account');
        } catch (_) {
          // الترحيل غير مطبّق بعد — لا يؤثر على عمل التطبيق.
        }
      });

  Future<void> sendPasswordReset(String email) =>
      _guard(() => _client.auth.resetPasswordForEmail(email.trim()));

  Future<void> signOut() => _guard(() => _client.auth.signOut());

  // ==================== الملف الشخصي ====================

  Future<Profile?> fetchProfile([String? userId]) => _guard(() async {
        final String? id = userId ?? currentUserId;
        if (id == null) return null;
        final Map<String, dynamic>? data =
            await _client.from('profiles').select().eq('id', id).maybeSingle();
        return data == null ? null : Profile.fromMap(data);
      });

  Future<Profile> updateProfile(Profile profile) => _guard(() async {
        final Map<String, dynamic> data = await _client
            .from('profiles')
            .update(profile.toUpdateMap())
            .eq('id', profile.id)
            .select()
            .single();
        return Profile.fromMap(data);
      });

  Future<void> deleteAccount() => _guard(() => _client.rpc<void>('delete_my_account'));

  // ==================== بيانات مرجعية ====================

  Future<List<GameDef>> fetchGames() => _guard(() async {
        final List<dynamic> rows =
            await _client.from('games').select().eq('is_active', true).order('sort_order');
        return rows
            .map((dynamic e) => GameDef.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
            .toList();
      });

  Future<List<Country>> fetchCountries() => _guard(() async {
        final List<dynamic> rows = await _client.from('countries').select().order('name_ar');
        return rows
            .map((dynamic e) => Country.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
            .toList();
      });

  Future<List<AvatarOption>> fetchAvatars() => _guard(() async {
        final List<dynamic> rows = await _client
            .from('avatars')
            .select()
            .eq('is_active', true)
            .order('sort_order');
        return rows
            .map((dynamic e) =>
                AvatarOption.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
            .toList();
      });

  Future<List<Achievement>> fetchAchievements(String userId) => _guard(() async {
        final List<dynamic> all = await _client.from('achievements').select().eq('is_active', true);
        final List<dynamic> mine = await _client
            .from('user_achievements')
            .select('achievement_key, awarded_at')
            .eq('user_id', userId);
        final Map<String, DateTime> awarded = <String, DateTime>{
          for (final dynamic row in mine)
            (row as Map<dynamic, dynamic>)['achievement_key'] as String:
                DateTime.parse(row['awarded_at'] as String),
        };
        return all
            .map((dynamic e) {
              final Map<String, dynamic> m = Map<String, dynamic>.from(e as Map<dynamic, dynamic>);
              return Achievement.fromMap(m, awardedAt: awarded[m['key']]);
            })
            .toList();
      });

  // ==================== الغرف ====================

  Future<Room> createRoom({
    required String gameKey,
    bool isPublic = true,
    String? password,
    String title = '',
    int? maxPlayers,
    Map<String, dynamic> settings = const <String, dynamic>{},
    String locale = 'ar',
  }) =>
      _guard(() async {
        final dynamic data = await _client.rpc<dynamic>('create_room', params: <String, dynamic>{
          'p_game_key': gameKey,
          'p_is_public': isPublic,
          'p_password': (password == null || password.isEmpty) ? null : password,
          'p_title': title,
          'p_max_players': maxPlayers,
          'p_settings': settings,
          'p_locale': locale,
        });
        return Room.fromMap(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
      });

  Future<Room> joinRoom({
    required String code,
    String? password,
    bool asSpectator = false,
  }) =>
      _guard(() async {
        final dynamic data = await _client.rpc<dynamic>('join_room', params: <String, dynamic>{
          'p_code': code.toUpperCase(),
          'p_password': password,
          'p_as_spectator': asSpectator,
        });
        return Room.fromMap(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
      });

  Future<void> leaveRoom(String roomId) =>
      _guard(() => _client.rpc<void>('leave_room', params: <String, dynamic>{'p_room': roomId}));

  Future<void> heartbeat(String roomId) =>
      _guard(() => _client.rpc<void>('heartbeat', params: <String, dynamic>{'p_room': roomId}));

  Future<void> setReady(String roomId, bool ready) => _guard(() => _client
      .rpc<void>('set_ready', params: <String, dynamic>{'p_room': roomId, 'p_ready': ready}));

  Future<void> transferHost(String roomId, String newHost) => _guard(() => _client.rpc<void>(
      'transfer_host',
      params: <String, dynamic>{'p_room': roomId, 'p_new_host': newHost}));

  Future<void> kickPlayer(String roomId, String userId) => _guard(() => _client
      .rpc<void>('kick_player', params: <String, dynamic>{'p_room': roomId, 'p_user': userId}));

  Future<void> banPlayer(String roomId, String userId, {String reason = ''}) =>
      _guard(() => _client.rpc<void>('ban_player',
          params: <String, dynamic>{'p_room': roomId, 'p_user': userId, 'p_reason': reason}));

  Future<void> mutePlayer(String roomId, String userId, bool muted) =>
      _guard(() => _client.rpc<void>('mute_player',
          params: <String, dynamic>{'p_room': roomId, 'p_user': userId, 'p_muted': muted}));

  Future<void> blockUser(String userId, {bool blocked = true}) => _guard(() => _client
      .rpc<void>('block_user', params: <String, dynamic>{'p_user': userId, 'p_blocked': blocked}));

  Future<List<Room>> fetchPublicRooms({String? gameKey}) => _guard(() async {
        final dynamic rows = await _client.rpc<dynamic>('list_public_rooms',
            params: <String, dynamic>{'p_game_key': gameKey, 'p_limit': 30});
        return (rows as List<dynamic>)
            .map((dynamic e) => Room.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
            .toList();
      });

  Future<Room?> fetchRoom(String roomId) => _guard(() async {
        final Map<String, dynamic>? data =
            await _client.from('rooms').select().eq('id', roomId).maybeSingle();
        return data == null ? null : Room.fromMap(data);
      });

  Future<List<RoomPlayer>> fetchRoomPlayers(String roomId) => _guard(() async {
        final List<dynamic> rows = await _client
            .from('room_players')
            .select('*, profiles!inner(nickname, avatar_key, country_code, show_country)')
            .eq('room_id', roomId)
            .filter('left_at', 'is', null)
            .order('seat', nullsFirst: false);
        return rows
            .map((dynamic e) =>
                RoomPlayer.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
            .toList();
      });

  // ==================== الدردشة ====================

  Future<List<ChatMessage>> fetchMessages(String roomId, {int limit = 60}) =>
      _guard(() async {
        final List<dynamic> rows = await _client
            .from('messages')
            .select('*, profiles(nickname, avatar_key)')
            .eq('room_id', roomId)
            .order('created_at', ascending: false)
            .limit(limit);
        return rows
            .map((dynamic e) =>
                ChatMessage.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
            .toList()
            .reversed
            .toList();
      });

  Future<ChatMessage> sendMessage(String roomId, String body, {String channel = 'public'}) =>
      _guard(() async {
        final dynamic data = await _client.rpc<dynamic>('send_message',
            params: <String, dynamic>{'p_room': roomId, 'p_body': body, 'p_channel': channel});
        return ChatMessage.fromMap(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
      });

  // ==================== اللعب ====================

  Future<GameSession> startGame(String roomId,
          {int? rounds, Map<String, dynamic> config = const <String, dynamic>{}}) =>
      _guard(() async {
        final dynamic data = await _client.rpc<dynamic>('start_game', params: <String, dynamic>{
          'p_room': roomId,
          'p_rounds': rounds,
          'p_config': config,
        });
        return GameSession.fromMap(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
      });

  Future<GameSession?> fetchActiveSession(String roomId) => _guard(() async {
        final Map<String, dynamic>? data = await _client
            .from('game_sessions')
            .select()
            .eq('room_id', roomId)
            .order('started_at', ascending: false)
            .limit(1)
            .maybeSingle();
        return data == null ? null : GameSession.fromMap(data);
      });

  Future<GameRound?> fetchCurrentRound(String sessionId) => _guard(() async {
        final Map<String, dynamic>? data = await _client
            .from('rounds')
            .select('id, session_id, round_index, phase, prompt, starts_at, ends_at, resolved_at, result')
            .eq('session_id', sessionId)
            .order('round_index', ascending: false)
            .limit(1)
            .maybeSingle();
        return data == null ? null : GameRound.fromMap(data);
      });

  Future<void> submitAnswer(String roundId, Map<String, dynamic> payload) =>
      _guard(() => _client.rpc<void>('submit_answer',
          params: <String, dynamic>{'p_round': roundId, 'p_payload': payload}));

  Future<bool> hasSubmitted(String roundId) => _guard(() async {
        final Map<String, dynamic>? row = await _client
            .from('answers')
            .select('id')
            .eq('round_id', roundId)
            .eq('user_id', currentUserId ?? '')
            .maybeSingle();
        return row != null;
      });

  Future<void> castVote(String roundId,
          {required String kind, String? targetUser, String? targetKey, bool? value}) =>
      _guard(() => _client.rpc<void>('cast_vote', params: <String, dynamic>{
            'p_round': roundId,
            'p_kind': kind,
            'p_target_user': targetUser,
            'p_target_key': targetKey,
            'p_value': value,
          }));

  Future<Map<String, dynamic>> submitMafiaAction(
          String roundId, String action, String targetId) =>
      _guard(() async {
        final dynamic data =
            await _client.rpc<dynamic>('submit_mafia_action', params: <String, dynamic>{
          'p_round': roundId,
          'p_action': action,
          'p_target': targetId,
        });
        return data == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(data as Map<dynamic, dynamic>);
      });

  /// الكلمة السرية الخاصة بي في هذه الجولة (الكذاب / من أنا).
  /// الخادم يعيد شريحة اللاعب فقط من `rounds.secret_data`.
  Future<String?> fetchMyRoundSecretWord(String roundId) => _guard(() async {
        final dynamic data = await _client
            .rpc<dynamic>('my_round_secret', params: <String, dynamic>{'p_round': roundId});
        if (data == null) return null;
        return Map<String, dynamic>.from(data as Map<dynamic, dynamic>)['word'] as String?;
      });

  Future<MyMafiaRole?> fetchMyMafiaRole(String roomId) => _guard(() async {
        final dynamic data =
            await _client.rpc<dynamic>('my_mafia_role', params: <String, dynamic>{'p_room': roomId});
        if (data == null) return null;
        return MyMafiaRole.fromMap(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
      });

  /// طلب حسم الجولة — الخادم وحده يقرر إن كان الوقت انتهى فعلًا.
  Future<Map<String, dynamic>> resolveRound(String roundId) => _guard(() async {
        final dynamic data =
            await _client.rpc<dynamic>('resolve_round', params: <String, dynamic>{'p_round': roundId});
        return data == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(data as Map<dynamic, dynamic>);
      });

  Future<void> playAgain(String roomId) =>
      _guard(() => _client.rpc<void>('play_again', params: <String, dynamic>{'p_room': roomId}));

  Future<void> abortGame(String roomId) =>
      _guard(() => _client.rpc<void>('abort_game', params: <String, dynamic>{'p_room': roomId}));

  Future<List<Map<String, dynamic>>> fetchRoundAnswers(String roundId) => _guard(() async {
        final List<dynamic> rows = await _client
            .from('answers')
            .select('user_id, payload, points, elapsed_ms, profiles(nickname, avatar_key)')
            .eq('round_id', roundId);
        return rows
            .map((dynamic e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
            .toList();
      });

  // ==================== المتصدرون ====================

  Future<List<LeaderboardEntry>> fetchLeaderboard({
    String scope = 'global',
    String period = 'all',
    String? gameKey,
  }) =>
      _guard(() async {
        final dynamic rows = await _client.rpc<dynamic>('leaderboard', params: <String, dynamic>{
          'p_scope': scope,
          'p_period': period,
          'p_game_key': gameKey,
          'p_limit': 50,
        });
        return (rows as List<dynamic>)
            .map((dynamic e) =>
                LeaderboardEntry.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
            .toList();
      });

  // ==================== الإبلاغ ====================

  Future<void> reportUser({
    required String reportedId,
    required String reason,
    String? roomId,
    int? messageId,
    String? details,
  }) =>
      _guard(() => _client.rpc<void>('report_user', params: <String, dynamic>{
            'p_reported': reportedId,
            'p_reason': reason,
            'p_room': roomId,
            'p_message_id': messageId,
            'p_details': details,
          }));
}
