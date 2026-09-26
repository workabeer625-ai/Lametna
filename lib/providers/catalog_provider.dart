import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'core_providers.dart';

final FutureProvider<List<GameDef>> gamesProvider = FutureProvider<List<GameDef>>(
  (Ref ref) => ref.watch(supabaseServiceProvider).fetchGames(),
);

final FutureProvider<List<Country>> countriesProvider = FutureProvider<List<Country>>(
  (Ref ref) => ref.watch(supabaseServiceProvider).fetchCountries(),
);

final FutureProvider<List<AvatarOption>> avatarsProvider = FutureProvider<List<AvatarOption>>(
  (Ref ref) => ref.watch(supabaseServiceProvider).fetchAvatars(),
);

final FutureProviderFamily<List<Achievement>, String> achievementsProvider =
    FutureProvider.family<List<Achievement>, String>(
  (Ref ref, String userId) => ref.watch(supabaseServiceProvider).fetchAchievements(userId),
);

final ProviderFamily<GameDef?, String> gameByKeyProvider =
    Provider.family<GameDef?, String>((Ref ref, String key) {
  final List<GameDef>? games = ref.watch(gamesProvider).valueOrNull;
  if (games == null) return null;
  for (final GameDef g in games) {
    if (g.key == key) return g;
  }
  return null;
});

/// تصفية الألعاب حسب الفئة المختارة في قائمة الألعاب.
final StateProvider<String?> gameCategoryFilterProvider =
    StateProvider<String?>((Ref ref) => null);

final Provider<List<GameDef>> filteredGamesProvider = Provider<List<GameDef>>((Ref ref) {
  final List<GameDef> games = ref.watch(gamesProvider).valueOrNull ?? <GameDef>[];
  final String? filter = ref.watch(gameCategoryFilterProvider);
  if (filter == null) return games;
  return games.where((GameDef g) => g.categories.contains(filter)).toList();
});
