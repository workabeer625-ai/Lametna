import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { online, offline }

/// مراقبة الاتصال بالشبكة — تُستخدم لعرض شاشة «لا يوجد إنترنت»
/// وإعادة الاشتراك في Realtime تلقائيًا بعد عودة الشبكة.
class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  NetworkStatus _last = NetworkStatus.online;

  Stream<NetworkStatus> get stream => _controller.stream;
  NetworkStatus get status => _last;
  bool get isOnline => _last == NetworkStatus.online;

  Future<void> start() async {
    _emit(await _connectivity.checkConnectivity());
    _sub = _connectivity.onConnectivityChanged.listen(_emit);
  }

  void _emit(List<ConnectivityResult> results) {
    final bool online = results.isNotEmpty &&
        results.any((ConnectivityResult r) => r != ConnectivityResult.none);
    final NetworkStatus next = online ? NetworkStatus.online : NetworkStatus.offline;
    if (next != _last) {
      _last = next;
      _controller.add(next);
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }
}
