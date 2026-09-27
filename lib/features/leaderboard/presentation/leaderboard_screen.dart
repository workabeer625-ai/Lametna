import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/design_kit.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/leaderboard_provider.dart';

const List<String> _scopes = <String>['global', 'arab', 'yemen'];
const List<String> _periods = <String>['week', 'month', 'all'];

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final LeaderboardQuery query = ref.watch(leaderboardQueryProvider);
    final AsyncValue<List<LeaderboardEntry>> async = ref.watch(leaderboardProvider);
    final String? myId = ref.watch(profileProvider).valueOrNull?.id;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              ScreenHeader(title: l10n.t('leaderboard'), accent: AppColors.gold),

              // ── المرشّحات ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: FadeInUp(
                  child: Column(
                    children: <Widget>[
                      _Segmented(
                        values: _scopes,
                        selected: query.scope,
                        labelOf: (String s) => l10n.t('scope_$s'),
                        accent: AppColors.green,
                        onChanged: (String v) => ref
                            .read(leaderboardQueryProvider.notifier)
                            .state = query.copyWith(scope: v),
                      ),
                      const SizedBox(height: 8),
                      _Segmented(
                        values: _periods,
                        selected: query.period,
                        labelOf: (String p) => l10n.t('period_$p'),
                        accent: AppColors.gold,
                        onChanged: (String v) => ref
                            .read(leaderboardQueryProvider.notifier)
                            .state = query.copyWith(period: v),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: async.when(
                  loading: () => const LoadingView(),
                  error: (Object e, _) =>
                      ErrorView(error: e, onRetry: () => ref.invalidate(leaderboardProvider)),
                  data: (List<LeaderboardEntry> list) {
                    if (list.isEmpty) {
                      return EmptyView(
                          icon: Icons.leaderboard_outlined,
                          message: l10n.t('no_leaderboard'));
                    }
                    final List<LeaderboardEntry> top =
                        list.take(3).toList(growable: false);
                    final List<LeaderboardEntry> rest =
                        list.length > 3 ? list.sublist(3) : <LeaderboardEntry>[];

                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(leaderboardProvider),
                      child: ListView(
                        physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                        children: <Widget>[
                          FadeInUp(child: _Podium(top: top, myId: myId)),
                          const SizedBox(height: 18),
                          ...List<Widget>.generate(
                            rest.length,
                            (int i) => FadeInUp(
                              delay: Duration(milliseconds: 30 * (i < 8 ? i : 8)),
                              child: _RankRow(
                                entry: rest[i],
                                isMe: rest[i].userId == myId,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// مبدّل شرائح زجاجي بمؤشّر متدرّج.
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    required this.accent,
  });

  final List<String> values;
  final String selected;
  final String Function(String) labelOf;
  final ValueChanged<String> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.white.op(0.06) : AppColors.white.op(0.55),
        borderRadius: BorderRadius.circular(100),
        border:
            Border.all(color: (isDark ? AppColors.white : AppColors.coffee).op(0.12)),
      ),
      child: Row(
        children: values.map((String v) {
          final bool on = v == selected;
          return Expanded(
            child: Pressable(
              onTap: () => onChanged(v),
              scale: 0.97,
              child: AnimatedContainer(
                duration: AppTheme.fast,
                curve: AppTheme.ease,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: on ? AppGradients.from(accent) : null,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow:
                      on ? AppTheme.glow(accent, opacity: 0.32, blur: 14, y: 5) : null,
                ),
                child: Text(
                  labelOf(v),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: on ? FontWeight.w800 : FontWeight.w700,
                    color: on ? AppColors.white : muted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// منصّة التتويج لأفضل ثلاثة.
class _Podium extends StatelessWidget {
  const _Podium({required this.top, required this.myId});
  final List<LeaderboardEntry> top;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    LeaderboardEntry? at(int i) => top.length > i ? top[i] : null;

    return SizedBox(
      height: 230,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
              child: _PodiumSpot(
                  entry: at(1), place: 2, height: 112, myId: myId)),
          Expanded(
              child: _PodiumSpot(
                  entry: at(0), place: 1, height: 150, myId: myId)),
          Expanded(
              child: _PodiumSpot(
                  entry: at(2), place: 3, height: 92, myId: myId)),
        ],
      ),
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  const _PodiumSpot({
    required this.entry,
    required this.place,
    required this.height,
    required this.myId,
  });

  final LeaderboardEntry? entry;
  final int place;
  final double height;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final LeaderboardEntry e = entry!;

    final Color tone = switch (place) {
      1 => AppColors.gold,
      2 => AppColors.latte,
      _ => AppColors.coffee,
    };
    final String medal = switch (place) {
      1 => '🥇',
      2 => '🥈',
      _ => '🥉',
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        if (place == 1)
          const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Text('👑', style: TextStyle(fontSize: 22)),
          ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.from(tone),
            boxShadow: AppTheme.glow(tone, opacity: 0.4, blur: 20, y: 8),
          ),
          child: AppAvatar(avatarKey: e.avatarKey, size: place == 1 ? 62 : 50),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            e.nickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: e.userId == myId ? tone : ink,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[tone.op(0.55), tone.op(0.14)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            border: Border.all(color: tone.op(0.35)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(medal, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                '${e.points}',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry, required this.isMe});
  final LeaderboardEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.gold.op(isDark ? 0.16 : 0.12)
              : (isDark ? AppColors.white.op(0.05) : AppColors.white.op(0.62)),
          borderRadius: BorderRadius.circular(AppTheme.rMd),
          border: Border.all(
            color: isMe
                ? AppColors.gold.op(0.45)
                : (isDark ? AppColors.white : AppColors.coffee).op(0.10),
            width: isMe ? 1.4 : 1,
          ),
          boxShadow:
              isMe ? AppTheme.glow(AppColors.gold, opacity: 0.2, blur: 16, y: 6) : null,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 30,
              child: Text(
                '${entry.rank}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: muted,
                ),
              ),
            ),
            AppAvatar(avatarKey: entry.avatarKey, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    entry.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.t('level')} ${entry.level}  •  '
                    '${entry.wins}/${entry.games} ${l10n.t('games_won')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w600, color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (Rect r) => AppGradients.gold.createShader(r),
              child: Text(
                '${entry.points}',
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
