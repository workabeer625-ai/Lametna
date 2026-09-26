import 'package:flutter_test/flutter_test.dart';
import 'package:lametna/core/utils/content_filter.dart';

void main() {
  group('تطبيع العربية', () {
    test('يزيل التشكيل والتطويل ويوحّد الألف والياء', () {
      expect(ContentFilter.normalizeArabic('أَحْمَــد'), 'احمد');
      expect(ContentFilter.normalizeArabic('إبراهيم'), 'ابراهيم');
      expect(ContentFilter.normalizeArabic('مدرسة'), 'مدرسه');
      expect(ContentFilter.normalizeArabic('  علي   محمد '), 'علي محمد');
    });
  });

  group('كشف الروابط', () {
    test('يكتشف الصيغ الشائعة', () {
      expect(ContentFilter.containsLink('زوروا https://example.com'), isTrue);
      expect(ContentFilter.containsLink('www.test.net'), isTrue);
      expect(ContentFilter.containsLink('t.me/channel'), isTrue);
    });

    test('لا يعتبر النص العادي رابطًا', () {
      expect(ContentFilter.containsLink('صباح الخير يا شباب'), isFalse);
    });
  });

  group('الكلمات الممنوعة', () {
    test('يكتشفها حتى مع التشكيل', () {
      expect(ContentFilter.containsBannedWord('يا غَبِي'), isTrue);
      expect(ContentFilter.containsBannedWord('you are stupid'), isTrue);
    });

    test('لا يحجب النص النظيف', () {
      expect(ContentFilter.containsBannedWord('لعبة ممتعة'), isFalse);
    });
  });

  group('validate', () {
    test('يعيد null للنص المقبول', () {
      expect(ContentFilter.validate('أهلًا بالجميع'), isNull);
    });

    test('يرفض الفارغ والطويل والروابط والإساءة', () {
      expect(ContentFilter.validate('   '), 'BAD_LENGTH');
      expect(ContentFilter.validate('a' * 400), 'BAD_LENGTH');
      expect(ContentFilter.validate('http://spam.xyz'), 'LINKS_NOT_ALLOWED');
      expect(ContentFilter.validate('غبي'), 'BLOCKED_CONTENT');
    });
  });
}
