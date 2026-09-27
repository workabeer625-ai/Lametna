class GameSession {
  const GameSession({
    required this.id,
    required this.roomId,
    required this.gameKey,
    required this.status,
    this.totalRounds = 5,
    this.currentRound = 0,
    this.config = const <String, dynamic>{},
    this.result,
    this.startedAt,
    this.endedAt,
  });

  final String id;
  final String roomId;
  final String gameKey;
  final String status;
  final int totalRounds;
  final int currentRound;
  final Map<String, dynamic> config;
  final Map<String, dynamic>? result;
  final DateTime? startedAt;
  final DateTime? endedAt;

  bool get isRunning => status == 'running';
  bool get isFinished => status == 'finished';

  List<Map<String, dynamic>> get standings {
    final dynamic raw = result?['standings'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .map((dynamic e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
        .toList();
  }

  List<String> get winners {
    final dynamic raw = result?['winners'];
    if (raw is! List) return const <String>[];
    return raw.map((dynamic e) => e.toString()).toList();
  }

  factory GameSession.fromMap(Map<String, dynamic> map) => GameSession(
        id: map['id'] as String,
        roomId: (map['room_id'] ?? '') as String,
        gameKey: (map['game_key'] ?? '') as String,
        status: (map['status'] ?? 'pending') as String,
        totalRounds: (map['total_rounds'] ?? 5) as int,
        currentRound: (map['current_round'] ?? 0) as int,
        config: Map<String, dynamic>.from(
            (map['config'] ?? const <String, dynamic>{}) as Map<dynamic, dynamic>),
        result: map['result'] == null
            ? null
            : Map<String, dynamic>.from(map['result'] as Map<dynamic, dynamic>),
        startedAt:
            map['started_at'] == null ? null : DateTime.parse(map['started_at'] as String),
        endedAt: map['ended_at'] == null ? null : DateTime.parse(map['ended_at'] as String),
      );
}
