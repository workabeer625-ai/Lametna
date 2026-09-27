import 'package:flutter_test/flutter_test.dart';
import 'package:lametna/core/utils/server_clock.dart';

void main() {
  group('ServerClock — المؤقت يعتمد على الخادم لا على الجهاز', () {
    test('يطبّق الفارق على الوقت الحالي', () {
      final ServerClock clock = ServerClock.withOffset(const Duration(seconds: 30));
      final Duration diff = clock.now().difference(DateTime.now().toUtc());
      expect(diff.inSeconds, closeTo(30, 1));
    });

    test('remaining لا يعود سالبًا أبدًا', () {
      final ServerClock clock = ServerClock.withOffset(Duration.zero);
      final DateTime past = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
      expect(clock.remaining(past), Duration.zero);
    });

    test('remaining يحسب بشكل صحيح مع انحراف ساعة الجهاز', () {
      // جهاز ساعته متأخرة دقيقة عن الخادم
      final ServerClock clock = ServerClock.withOffset(const Duration(minutes: 1));
      final DateTime endsAt = DateTime.now().toUtc().add(const Duration(minutes: 2));
      // الوقت الفعلي المتبقي بحسب الخادم = 60 ثانية وليس 120
      expect(clock.remaining(endsAt).inSeconds, closeTo(60, 2));
    });

    test('hasEnded يعتمد على ساعة الخادم', () {
      final ServerClock clock = ServerClock.withOffset(const Duration(minutes: 10));
      final DateTime endsAt = DateTime.now().toUtc().add(const Duration(minutes: 5));
      expect(clock.hasEnded(endsAt), isTrue, reason: 'الخادم متقدم 10 دقائق');
      expect(clock.hasEnded(null), isTrue);
    });
  });
}
