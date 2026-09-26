import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ساعة الخادم — لا نثق أبدًا بساعة الجهاز في توقيت الجولات.
///
/// نقيس الفارق بين `now()` في Postgres وساعة الجهاز مرة عند الاتصال
/// وكل بضع دقائق، ثم نحسب الوقت المتبقي بناءً على هذا الفارق.
class ServerClock {
  ServerClock(this._client);

  /// للاختبارات: ساعة بفارق معلوم دون نداء الشبكة.
  @visibleForTesting
  ServerClock.withOffset(Duration offset)
      : _client = null,
        _offset = offset,
        _lastSync = DateTime.now().toUtc();

  final SupabaseClient? _client;

  Duration _offset = Duration.zero;
  DateTime? _lastSync;

  Duration get offset => _offset;
  bool get isSynced => _lastSync != null;

  Future<void> sync() async {
    final SupabaseClient? client = _client;
    if (client == null) return;
    final DateTime before = DateTime.now().toUtc();
    final dynamic result = await client.rpc<dynamic>('server_now');
    final DateTime after = DateTime.now().toUtc();

    final DateTime serverTime = DateTime.parse(result.toString()).toUtc();
    // نصف زمن الرحلة يقرّب الفارق الحقيقي
    final Duration roundTrip = after.difference(before);
    final DateTime localMid = before.add(roundTrip ~/ 2);

    _offset = serverTime.difference(localMid);
    _lastSync = after;
  }

  /// الوقت الحالي بحسب الخادم.
  DateTime now() => DateTime.now().toUtc().add(_offset);

  /// المتبقي حتى لحظة معيّنة، صفر إذا انتهت.
  Duration remaining(DateTime? endsAt) {
    if (endsAt == null) return Duration.zero;
    final Duration d = endsAt.toUtc().difference(now());
    return d.isNegative ? Duration.zero : d;
  }

  bool hasEnded(DateTime? endsAt) =>
      endsAt == null || !endsAt.toUtc().isAfter(now());
}
