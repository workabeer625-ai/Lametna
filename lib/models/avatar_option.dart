class AvatarOption {
  const AvatarOption({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    this.sortOrder = 0,
  });

  final String key;
  final String nameAr;
  final String nameEn;
  final int sortOrder;

  String name(String locale) => locale == 'en' ? nameEn : nameAr;
  String get assetPath => 'assets/avatars/$key.png';

  factory AvatarOption.fromMap(Map<String, dynamic> map) => AvatarOption(
        key: map['key'] as String,
        nameAr: (map['name_ar'] ?? '') as String,
        nameEn: (map['name_en'] ?? '') as String,
        sortOrder: (map['sort_order'] ?? 0) as int,
      );
}
