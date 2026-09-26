enum PlayerState { connected, disconnected, ready, notReady, alive, dead, spectator, banned }

PlayerState playerStateFrom(String? value) {
  switch (value) {
    case 'connected': return PlayerState.connected;
    case 'disconnected': return PlayerState.disconnected;
    case 'ready': return PlayerState.ready;
    case 'not_ready': return PlayerState.notReady;
    case 'alive': return PlayerState.alive;
    case 'dead': return PlayerState.dead;
    case 'spectator': return PlayerState.spectator;
    case 'banned': return PlayerState.banned;
    default: return PlayerState.connected;
  }
}

class RoomPlayer {
  const RoomPlayer({
    required this.roomId,
    required this.userId,
    required this.nickname,
    this.avatarKey,
    this.countryCode,
    this.state = PlayerState.connected,
    this.isReady = false,
    this.isSpectator = false,
    this.isMuted = false,
    this.isAlive = true,
    this.seat,
    this.score = 0,
    this.joinedAt,
    this.lastSeenAt,
    this.leftAt,
  });

  final String roomId;
  final String userId;
  final String nickname;
  final String? avatarKey;
  final String? countryCode;
  final PlayerState state;
  final bool isReady;
  final bool isSpectator;
  final bool isMuted;
  final bool isAlive;
  final int? seat;
  final int score;
  final DateTime? joinedAt;
  final DateTime? lastSeenAt;
  final DateTime? leftAt;

  bool get isPresent => leftAt == null;
  bool get isDisconnected => state == PlayerState.disconnected;

  factory RoomPlayer.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? p = map['profiles'] is Map
        ? Map<String, dynamic>.from(map['profiles'] as Map<dynamic, dynamic>)
        : null;
    return RoomPlayer(
      roomId: (map['room_id'] ?? '') as String,
      userId: (map['user_id'] ?? '') as String,
      nickname: (p?['nickname'] ?? map['nickname'] ?? '—') as String,
      avatarKey: (p?['avatar_key'] ?? map['avatar_key']) as String?,
      countryCode: (p?['show_country'] == true
          ? p?['country_code']
          : map['country_code']) as String?,
      state: playerStateFrom(map['state'] as String?),
      isReady: (map['is_ready'] ?? false) as bool,
      isSpectator: (map['is_spectator'] ?? false) as bool,
      isMuted: (map['is_muted'] ?? false) as bool,
      isAlive: (map['is_alive'] ?? true) as bool,
      seat: map['seat'] as int?,
      score: (map['score'] ?? 0) as int,
      joinedAt: map['joined_at'] == null ? null : DateTime.parse(map['joined_at'] as String),
      lastSeenAt: map['last_seen_at'] == null ? null : DateTime.parse(map['last_seen_at'] as String),
      leftAt: map['left_at'] == null ? null : DateTime.parse(map['left_at'] as String),
    );
  }
}
