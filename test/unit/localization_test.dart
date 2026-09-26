import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lametna/app/localization/app_localizations.dart';
import 'package:lametna/app/localization/strings_ar.dart';
import 'package:lametna/app/localization/strings_en.dart';

void main() {
  group('الترجمة', () {
    test('العربية والإنجليزية بنفس المفاتيح تمامًا', () {
      final Set<String> ar = arStrings.keys.toSet();
      final Set<String> en = enStrings.keys.toSet();
      expect(ar.difference(en), isEmpty, reason: 'مفاتيح ناقصة في الإنجليزية');
      expect(en.difference(ar), isEmpty, reason: 'مفاتيح ناقصة في العربية');
    });

    test('لا توجد قيم فارغة', () {
      for (final MapEntry<String, String> e in arStrings.entries) {
        expect(e.value.trim(), isNotEmpty, reason: 'المفتاح ${e.key} فارغ');
      }
      for (final MapEntry<String, String> e in enStrings.entries) {
        expect(e.value.trim(), isNotEmpty, reason: 'key ${e.key} is empty');
      }
    });

    test('اتجاه العربية RTL والإنجليزية LTR', () {
      expect(AppLocalizations(const Locale('ar')).direction, TextDirection.rtl);
      expect(AppLocalizations(const Locale('en')).direction, TextDirection.ltr);
    });

    test('t يعيد الترجمة الصحيحة ويسقط بأمان للمفاتيح المجهولة', () {
      final AppLocalizations ar = AppLocalizations(const Locale('ar'));
      final AppLocalizations en = AppLocalizations(const Locale('en'));
      expect(ar.t('app_name'), 'لمّتنا');
      expect(en.t('app_name'), 'Lametna');
      expect(ar.t('___missing___'), '___missing___');
    });

    test('مساعدات الفئات والأدوار', () {
      final AppLocalizations ar = AppLocalizations(const Locale('ar'));
      expect(ar.category('animal'), 'حيوان');
      expect(ar.mafiaRole('detective'), 'محقق');
      expect(ar.reportReason('racism'), 'عنصرية');
    });
  });
}
