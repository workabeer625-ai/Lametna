class Country {
  const Country({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    this.flagEmoji = '',
    this.region = 'other',
  });

  final String code;
  final String nameAr;
  final String nameEn;
  final String flagEmoji;
  final String region;

  String name(String locale) => locale == 'en' ? nameEn : nameAr;

  factory Country.fromMap(Map<String, dynamic> map) => Country(
        code: map['code'] as String,
        nameAr: (map['name_ar'] ?? '') as String,
        nameEn: (map['name_en'] ?? '') as String,
        flagEmoji: (map['flag_emoji'] ?? '') as String,
        region: (map['region'] ?? 'other') as String,
      );
}
