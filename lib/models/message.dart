class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.body,
    this.userId,
    this.nickname,
    this.avatarKey,
    this.isSystem = false,
    this.channel = 'public',
    required this.createdAt,
  });

  final int id;
  final String roomId;
  final String? userId;
  final String? nickname;
  final String? avatarKey;
  final String body;
  final bool isSystem;
  final String channel;
  final DateTime createdAt;

  bool isMine(String? uid) => userId != null && userId == uid;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? p = map['profiles'] is Map
        ? Map<String, dynamic>.from(map['profiles'] as Map<dynamic, dynamic>)
        : null;
    return ChatMessage(
      id: (map['id'] as num).toInt(),
      roomId: (map['room_id'] ?? '') as String,
      userId: map['user_id'] as String?,
      nickname: (p?['nickname'] ?? map['nickname']) as String?,
      avatarKey: (p?['avatar_key'] ?? map['avatar_key']) as String?,
      body: (map['body'] ?? '') as String,
      isSystem: (map['is_system'] ?? false) as bool,
      channel: (map['channel'] ?? 'public') as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
