class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.nickname,
    this.avatarKey,
    this.countryCode,
    this.points = 0,
    this.wins = 0,
    this.games = 0,
    this.level = 1,
  });

  final int rank;
  final String userId;
  final String nickname;
  final String? avatarKey;
  final String? countryCode;
  final int points;
  final int wins;
  final int games;
  final int level;

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) => LeaderboardEntry(
        rank: ((map['rank'] ?? 0) as num).toInt(),
        userId: (map['user_id'] ?? '') as String,
        nickname: (map['nickname'] ?? '') as String,
        avatarKey: map['avatar_key'] as String?,
        countryCode: map['country_code'] as String?,
        points: ((map['points'] ?? 0) as num).toInt(),
        wins: ((map['wins'] ?? 0) as num).toInt(),
        games: ((map['games'] ?? 0) as num).toInt(),
        level: ((map['level'] ?? 1) as num).toInt(),
      );
}
