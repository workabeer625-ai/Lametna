enum RoomStatus { waiting, starting, playing, paused, finished, cancelled }

RoomStatus roomStatusFrom(String? value) => RoomStatus.values.firstWhere(
      (RoomStatus s) => s.name == value,
      orElse: () => RoomStatus.waiting,
    );

/// غرفة لعب. ملاحظة: `password_hash` لا يصل للعميل إطلاقًا (محجوب بصلاحيات الأعمدة).
class Room {
  const Room({
    required this.id,
    required this.code,
    required this.gameKey,
    required this.hostId,
    this.title = '',
    this.isPublic = true,
    this.hasPassword = false,
    this.status = RoomStatus.waiting,
    this.minPlayers = 3,
    this.maxPlayers = 12,
    this.playerCount = 0,
    this.settings = const <String, dynamic>{},
    this.locale = 'ar',
    this.hostNickname,
    this.createdAt,
    this.lastActivityAt,
  });

  final String id;
  final String code;
  final String gameKey;
  final String hostId;
  final String title;
  final bool isPublic;
  final bool hasPassword;
  final RoomStatus status;
  final int minPlayers;
  final int maxPlayers;
  final int playerCount;
  final Map<String, dynamic> settings;
  final String locale;
  final String? hostNickname;
  final DateTime? createdAt;
  final DateTime? lastActivityAt;

  bool get isFull => playerCount >= maxPlayers;
  bool get isJoinable =>
      status == RoomStatus.waiting || status == RoomStatus.playing;

  bool isHost(String? userId) => userId != null && userId == hostId;

  factory Room.fromMap(Map<String, dynamic> map) => Room(
        id: map['id'] as String,
        code: (map['code'] ?? '') as String,
        gameKey: (map['game_key'] ?? '') as String,
        hostId: (map['host_id'] ?? '') as String,
        title: (map['title'] ?? '') as String,
        isPublic: (map['is_public'] ?? true) as bool,
        hasPassword: (map['has_password'] ?? false) as bool,
        status: roomStatusFrom(map['status'] as String?),
        minPlayers: (map['min_players'] ?? 3) as int,
        maxPlayers: (map['max_players'] ?? 12) as int,
        playerCount: ((map['player_count'] ?? 0) as num).toInt(),
        settings: Map<String, dynamic>.from(
            (map['settings'] ?? const <String, dynamic>{}) as Map<dynamic, dynamic>),
        locale: (map['locale'] ?? 'ar') as String,
        hostNickname: map['host_nickname'] as String?,
        createdAt: map['created_at'] == null
            ? null
            : DateTime.parse(map['created_at'] as String),
        lastActivityAt: map['last_activity_at'] == null
            ? null
            : DateTime.parse(map['last_activity_at'] as String),
      );

  Room copyWith({RoomStatus? status, int? playerCount, String? hostId}) => Room(
        id: id,
        code: code,
        gameKey: gameKey,
        hostId: hostId ?? this.hostId,
        title: title,
        isPublic: isPublic,
        hasPassword: hasPassword,
        status: status ?? this.status,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        playerCount: playerCount ?? this.playerCount,
        settings: settings,
        locale: locale,
        hostNickname: hostNickname,
        createdAt: createdAt,
        lastActivityAt: lastActivityAt,
      );
}
