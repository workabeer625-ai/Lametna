import 'package:flutter/material.dart';

import 'strings_ar.dart';
import 'strings_en.dart';

/// ترجمة خفيفة بدون توليد كود — عربي (RTL) وإنجليزي (LTR).
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  bool get isArabic => locale.languageCode == 'ar';
  String get languageCode => locale.languageCode;
  TextDirection get direction => isArabic ? TextDirection.rtl : TextDirection.ltr;

  Map<String, String> get _table => isArabic ? arStrings : enStrings;

  /// ترجمة مفتاح مع استبدال اختياري: t('round') أو t('x', {'n': '3'}).
  String t(String key, [Map<String, String>? args]) {
    String value = _table[key] ?? enStrings[key] ?? arStrings[key] ?? key;
    if (args != null) {
      args.forEach((String k, String v) => value = value.replaceAll('{$k}', v));
    }
    return value;
  }

  /// أرقام عربية-هندية للعربية عند الرغبة، وإلا الأرقام اللاتينية.
  String number(int value) => value.toString();

  String category(String key) => t('cat_$key');
  String mafiaRole(String role) => t('role_$role');
  String reportReason(String reason) => t('reason_$reason');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// اختصار مريح: context.l10n.t('home')
extension LocalizationExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
