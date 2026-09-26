/// تعريف لعبة كما يأتي من جدول games.
class GameDef {
  const GameDef({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr = '',
    this.descriptionEn = '',
    this.icon = '🎮',
    this.categories = const <String>[],
    this.minPlayers = 3,
    this.maxPlayers = 12,
    this.defaultRounds = 5,
    this.roundSeconds = 90,
    this.isActive = true,
  });

  final String key;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String icon;
  final List<String> categories;
  final int minPlayers;
  final int maxPlayers;
  final int defaultRounds;
  final int roundSeconds;
  final bool isActive;

  String name(String locale) => locale == 'en' ? nameEn : nameAr;
  String description(String locale) => locale == 'en' ? descriptionEn : descriptionAr;

  factory GameDef.fromMap(Map<String, dynamic> map) => GameDef(
        key: map['key'] as String,
        nameAr: (map['name_ar'] ?? '') as String,
        nameEn: (map['name_en'] ?? '') as String,
        descriptionAr: (map['description_ar'] ?? '') as String,
        descriptionEn: (map['description_en'] ?? '') as String,
        icon: (map['icon'] ?? '🎮') as String,
        categories: ((map['categories'] ?? const <dynamic>[]) as List<dynamic>)
            .map((dynamic e) => e.toString())
            .toList(),
        minPlayers: (map['min_players'] ?? 3) as int,
        maxPlayers: (map['max_players'] ?? 12) as int,
        defaultRounds: (map['default_rounds'] ?? 5) as int,
        roundSeconds: (map['round_seconds'] ?? 90) as int,
        isActive: (map['is_active'] ?? true) as bool,
      );
}
