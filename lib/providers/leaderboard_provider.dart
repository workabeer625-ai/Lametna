import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'core_providers.dart';

@immutable
class LeaderboardQuery {
  const LeaderboardQuery({this.scope = 'global', this.period = 'all', this.gameKey});

  final String scope;
  final String period;
  final String? gameKey;

  LeaderboardQuery copyWith({String? scope, String? period, String? gameKey, bool clearGame = false}) =>
      LeaderboardQuery(
        scope: scope ?? this.scope,
        period: period ?? this.period,
        gameKey: clearGame ? null : (gameKey ?? this.gameKey),
      );

  @override
  bool operator ==(Object other) =>
      other is LeaderboardQuery &&
      other.scope == scope &&
      other.period == period &&
      other.gameKey == gameKey;

  @override
  int get hashCode => Object.hash(scope, period, gameKey);
}

final StateProvider<LeaderboardQuery> leaderboardQueryProvider =
    StateProvider<LeaderboardQuery>((Ref ref) => const LeaderboardQuery());

final AutoDisposeFutureProvider<List<LeaderboardEntry>> leaderboardProvider =
    FutureProvider.autoDispose<List<LeaderboardEntry>>((Ref ref) {
  final LeaderboardQuery q = ref.watch(leaderboardQueryProvider);
  return ref.watch(supabaseServiceProvider).fetchLeaderboard(
        scope: q.scope,
        period: q.period,
        gameKey: q.gameKey,
      );
});
