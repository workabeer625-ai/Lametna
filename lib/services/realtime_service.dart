import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';

enum RealtimeStatus { connecting, subscribed, disconnected, error }

/// اشتراك Realtime واحد لكل غرفة، مع إعادة اتصال تلقائية تصاعدية.
///
/// ملاحظة أمنية: Realtime يحترم سياسات RLS، لذا لا يستقبل اللاعب
/// إلا الصفوف المسموح له بقراءتها (مثلًا لا يرى أدوار المافيا).
class RoomRealtimeChannel {
  RoomRealtimeChannel({
    required SupabaseClient client,
    required this.roomId,
    required this.onRoomChanged,
    required this.onPlayersChanged,
    required this.onMessage,
    required this.onRoundChanged,
    required this.onSessionChanged,
    this.onStatus,
  }) : _client = client;

  final SupabaseClient _client;
  final String roomId;

  final void Function(Map<String, dynamic> room) onRoomChanged;
  final void Function() onPlayersChanged;
  final void Function(Map<String, dynamic> message) onMessage;
  final void Function(Map<String, dynamic> round) onRoundChanged;
  final void Function(Map<String, dynamic> session) onSessionChanged;
  final void Function(RealtimeStatus status)? onStatus;

  RealtimeChannel? _channel;
  Timer? _retryTimer;
  int _attempt = 0;
  bool _disposed = false;

  RealtimeStatus _status = RealtimeStatus.connecting;
  RealtimeStatus get status => _status;

  void _setStatus(RealtimeStatus s) {
    if (_status == s) return;
    _status = s;
    onStatus?.call(s);
  }

  Future<void> subscribe() async {
    if (_disposed) return;
    await _teardown();
    _setStatus(RealtimeStatus.connecting);

    final RealtimeChannel channel = _client.channel('room:$roomId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'rooms',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, column: 'id', value: roomId),
          callback: (PostgresChangePayload payload) => onRoomChanged(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_players',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
          callback: (_) => onPlayersChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
          callback: (PostgresChangePayload payload) => onMessage(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'game_sessions',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
          callback: (PostgresChangePayload payload) => onSessionChanged(payload.newRecord),
        )
        // الجولات لا يمكن فلترتها بـ room_id مباشرة، لذا نستقبل كل التغييرات
        // التي تسمح بها RLS (وهي حكمًا جولات غرفنا فقط) ونفلترها محليًا.
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rounds',
          callback: (PostgresChangePayload payload) => onRoundChanged(payload.newRecord),
        );

    channel.subscribe((RealtimeSubscribeStatus status, Object? error) {
      switch (status) {
        case RealtimeSubscribeStatus.subscribed:
          _attempt = 0;
          _setStatus(RealtimeStatus.subscribed);
        case RealtimeSubscribeStatus.closed:
          _setStatus(RealtimeStatus.disconnected);
          _scheduleRetry();
        case RealtimeSubscribeStatus.channelError:
        case RealtimeSubscribeStatus.timedOut:
          _setStatus(RealtimeStatus.error);
          _scheduleRetry();
      }
    });

    _channel = channel;
  }

  void _scheduleRetry() {
    if (_disposed) return;
    _retryTimer?.cancel();
    _attempt = (_attempt + 1).clamp(1, 6);
    // تصاعد أسي محدود: 2، 4، 8، 16، 32، 64 ثانية
    final Duration delay = AppConstants.realtimeRetryBase * (1 << (_attempt - 1));
    _retryTimer = Timer(delay, subscribe);
  }

  /// إعادة اتصال فورية (تُستدعى عند عودة الشبكة أو عودة التطبيق للمقدمة).
  Future<void> reconnectNow() async {
    _retryTimer?.cancel();
    _attempt = 0;
    await subscribe();
  }

  Future<void> _teardown() async {
    final RealtimeChannel? c = _channel;
    _channel = null;
    if (c != null) {
      await _client.removeChannel(c);
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _retryTimer?.cancel();
    await _teardown();
  }
}
