class Achievement {
  const Achievement({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr = '',
    this.descriptionEn = '',
    this.icon = '🏅',
    this.points = 0,
    this.awardedAt,
  });

  final String key;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String icon;
  final int points;
  final DateTime? awardedAt;

  bool get isEarned => awardedAt != null;
  String name(String locale) => locale == 'en' ? nameEn : nameAr;
  String description(String locale) => locale == 'en' ? descriptionEn : descriptionAr;

  factory Achievement.fromMap(Map<String, dynamic> map, {DateTime? awardedAt}) => Achievement(
        key: map['key'] as String,
        nameAr: (map['name_ar'] ?? '') as String,
        nameEn: (map['name_en'] ?? '') as String,
        descriptionAr: (map['description_ar'] ?? '') as String,
        descriptionEn: (map['description_en'] ?? '') as String,
        icon: (map['icon'] ?? '🏅') as String,
        points: (map['points'] ?? 0) as int,
        awardedAt: awardedAt,
      );
}
