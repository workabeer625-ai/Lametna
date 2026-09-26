import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/storage/local_prefs.dart';
import '../core/storage/secure_store.dart';
import '../core/utils/server_clock.dart';
import '../services/connectivity_service.dart';
import '../services/supabase_service.dart';

/// يُستبدل في main() بعد تهيئة SharedPreferences.
final Provider<LocalPrefs> localPrefsProvider = Provider<LocalPrefs>(
  (Ref ref) => throw UnimplementedError('localPrefsProvider must be overridden'),
);

final Provider<SecureStore> secureStoreProvider =
    Provider<SecureStore>((Ref ref) => const SecureStore());

final Provider<SupabaseClient> supabaseClientProvider =
    Provider<SupabaseClient>((Ref ref) => Supabase.instance.client);

final Provider<SupabaseService> supabaseServiceProvider = Provider<SupabaseService>(
  (Ref ref) => SupabaseService(ref.watch(supabaseClientProvider)),
);

final Provider<ServerClock> serverClockProvider = Provider<ServerClock>((Ref ref) {
  final ServerClock clock = ServerClock(ref.watch(supabaseClientProvider));
  unawaited(clock.sync());
  return clock;
});

final Provider<ConnectivityService> connectivityServiceProvider =
    Provider<ConnectivityService>((Ref ref) {
  final ConnectivityService service = ConnectivityService();
  unawaited(service.start());
  ref.onDispose(service.dispose);
  return service;
});

final StreamProvider<NetworkStatus> networkStatusProvider =
    StreamProvider<NetworkStatus>((Ref ref) {
  final ConnectivityService service = ref.watch(connectivityServiceProvider);
  return service.stream;
});

final Provider<bool> isOnlineProvider = Provider<bool>((Ref ref) {
  return ref.watch(networkStatusProvider).maybeWhen(
        data: (NetworkStatus s) => s == NetworkStatus.online,
        orElse: () => true,
      );
});

/// نبضة كل ثانية لتحديث المؤقتات في الواجهة (بدون إعادة بناء الشجرة كلها).
final StreamProvider<int> tickerProvider = StreamProvider<int>((Ref ref) {
  return Stream<int>.periodic(const Duration(seconds: 1), (int i) => i);
});
