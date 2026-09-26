import 'package:flutter_test/flutter_test.dart';
import 'package:lametna/core/utils/validators.dart';

void main() {
  group('Validators.isEmail', () {
    test('يقبل بريدًا صحيحًا', () {
      expect(Validators.isEmail('ali@lametna.app'), isTrue);
      expect(Validators.isEmail('  user.name+tag@sub.example.co  '), isTrue);
    });

    test('يرفض بريدًا غير صحيح', () {
      expect(Validators.isEmail('ali@'), isFalse);
      expect(Validators.isEmail('ali.lametna.app'), isFalse);
      expect(Validators.isEmail(''), isFalse);
    });
  });

  group('Validators.isStrongEnoughPassword', () {
    test('8 أحرف فأكثر', () {
      expect(Validators.isStrongEnoughPassword('12345678'), isTrue);
      expect(Validators.isStrongEnoughPassword('1234567'), isFalse);
    });
  });

  group('رمز الغرفة', () {
    test('يقبل 6 خانات بأحرف كبيرة وأرقام', () {
      expect(Validators.isRoomCode('ABC123'), isTrue);
      expect(Validators.isRoomCode('abc123'), isTrue, reason: 'يُطبَّع إلى الأحرف الكبيرة');
    });

    test('يرفض الأطوال الخاطئة', () {
      expect(Validators.isRoomCode('ABC12'), isFalse);
      expect(Validators.isRoomCode('ABC1234'), isFalse);
    });

    test('التطبيع يزيل الرموز والمسافات', () {
      expect(Validators.normalizeRoomCode(' ab-c 12 3 '), 'ABC123');
    });
  });

  group('الاسم المستعار', () {
    test('بين 2 و24 حرفًا', () {
      expect(Validators.isNickname('ع'), isFalse);
      expect(Validators.isNickname('أبو علي'), isTrue);
      expect(Validators.isNickname('x' * 25), isFalse);
    });
  });
}
