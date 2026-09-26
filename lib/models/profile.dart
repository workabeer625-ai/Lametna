/// ملف اللاعب — لا يحتوي على بيانات حساسة ولا صور شخصية.
class Profile {
  const Profile({
    required this.id,
    required this.nickname,
    this.avatarKey,
    this.countryCode,
    this.showCountry = false,
    this.locale = 'ar',
    this.themeMode = 'system',
    this.role = 'player',
    this.isGuest = false,
    this.totalPoints = 0,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.winStreak = 0,
    this.bestStreak = 0,
    this.level = 1,
    this.notificationsEnabled = true,
    this.createdAt,
  });

  final String id;
  final String nickname;
  final String? avatarKey;
  final String? countryCode;
  final bool showCountry;
  final String locale;
  final String themeMode;
  final String role;
  final bool isGuest;
  final int totalPoints;
  final int gamesPlayed;
  final int gamesWon;
  final int winStreak;
  final int bestStreak;
  final int level;
  final bool notificationsEnabled;
  final DateTime? createdAt;

  bool get isAdmin => role == 'admin' || role == 'moderator';

  double get winRate => gamesPlayed == 0 ? 0 : gamesWon / gamesPlayed;

  /// النقاط المتبقية للمستوى التالي (500 نقطة لكل مستوى).
  int get pointsToNextLevel => (level * 500) - totalPoints;

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        nickname: (map['nickname'] ?? '') as String,
        avatarKey: map['avatar_key'] as String?,
        countryCode: map['country_code'] as String?,
        showCountry: (map['show_country'] ?? false) as bool,
        locale: (map['locale'] ?? 'ar') as String,
        themeMode: (map['theme_mode'] ?? 'system') as String,
        role: (map['role'] ?? 'player') as String,
        isGuest: (map['is_guest'] ?? false) as bool,
        totalPoints: (map['total_points'] ?? 0) as int,
        gamesPlayed: (map['games_played'] ?? 0) as int,
        gamesWon: (map['games_won'] ?? 0) as int,
        winStreak: (map['win_streak'] ?? 0) as int,
        bestStreak: (map['best_streak'] ?? 0) as int,
        level: (map['level'] ?? 1) as int,
        notificationsEnabled: (map['notifications_enabled'] ?? true) as bool,
        createdAt: map['created_at'] == null
            ? null
            : DateTime.parse(map['created_at'] as String),
      );

  /// الحقول التي يسمح الخادم للاعب بتعديلها فقط.
  Map<String, dynamic> toUpdateMap() => <String, dynamic>{
        'nickname': nickname,
        'avatar_key': avatarKey,
        'country_code': countryCode,
        'show_country': showCountry,
        'locale': locale,
        'theme_mode': themeMode,
        'notifications_enabled': notificationsEnabled,
      };

  Profile copyWith({
    String? nickname,
    String? avatarKey,
    String? countryCode,
    bool? showCountry,
    String? locale,
    String? themeMode,
    bool? notificationsEnabled,
  }) =>
      Profile(
        id: id,
        nickname: nickname ?? this.nickname,
        avatarKey: avatarKey ?? this.avatarKey,
        countryCode: countryCode ?? this.countryCode,
        showCountry: showCountry ?? this.showCountry,
        locale: locale ?? this.locale,
        themeMode: themeMode ?? this.themeMode,
        role: role,
        isGuest: isGuest,
        totalPoints: totalPoints,
        gamesPlayed: gamesPlayed,
        gamesWon: gamesWon,
        winStreak: winStreak,
        bestStreak: bestStreak,
        level: level,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        createdAt: createdAt,
      );
}
