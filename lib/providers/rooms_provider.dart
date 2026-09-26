import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'core_providers.dart';

final StateProvider<String?> publicRoomsFilterProvider =
    StateProvider<String?>((Ref ref) => null);

final FutureProvider<List<Room>> publicRoomsProvider =
    FutureProvider.autoDispose<List<Room>>((Ref ref) {
  final String? gameKey = ref.watch(publicRoomsFilterProvider);
  return ref.watch(supabaseServiceProvider).fetchPublicRooms(gameKey: gameKey);
});
