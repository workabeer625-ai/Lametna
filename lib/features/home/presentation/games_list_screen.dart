import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/design_kit.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/models.dart';
import '../../../providers/catalog_provider.dart';

const List<String> _categories = <String>[
  'yemeni', 'arabic', 'global', 'family', 'fast', 'competitive',
];

class GamesListScreen extends ConsumerWidget {
  const GamesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<GameDef>> async = ref.watch(gamesProvider);
    final String? filter = ref.watch(gameCategoryFilterProvider);
    final List<GameDef> games = ref.watch(filteredGamesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              // ── الترويسة ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: FadeInUp(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(l10n.t('games'),
                                style: Theme.of(context).textTheme.displaySmall),
                            const SizedBox(height: 2),
                            Text(
                              '${games.length} ${l10n.t('games')}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      const BrandMark(size: 36),
                    ],
                  ),
                ),
              ),

              // ── تصنيفات ──────────────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 90),
                child: SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    children: <Widget>[
                      _CategoryChip(
                        label: l10n.t('all_games'),
                        selected: filter == null,
                        onTap: () => ref
                            .read(gameCategoryFilterProvider.notifier)
                            .state = null,
                      ),
                      ..._categories.map(
                        (String c) => _CategoryChip(
                          label: l10n.category(c),
                          selected: filter == c,
                          color: AppColors.forSeed(c),
                          onTap: () => ref
                              .read(gameCategoryFilterProvider.notifier)
                              .state = filter == c ? null : c,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── القائمة ──────────────────────────────────────
              Expanded(
                child: async.when(
                  loading: () => const LoadingView(),
                  error: (Object e, _) => ErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(gamesProvider),
                  ),
                  data: (_) => games.isEmpty
                      ? EmptyView(message: l10n.t('empty'))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                          itemCount: games.length,
                          itemBuilder: (BuildContext context, int i) => FadeInUp(
                            delay: Duration(milliseconds: (i < 6 ? i : 6) * 60),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _GameCard(game: games[i]),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color c = color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Pressable(
        scale: 0.93,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppTheme.fast,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            gradient: selected ? AppGradients.from(c) : null,
            color: selected
                ? null
                : (isDark ? Colors.white.op(0.06) : AppColors.white.op(0.7)),
            border: Border.all(
              color: selected
                  ? Colors.white.op(0.25)
                  : (isDark ? Colors.white.op(0.10) : AppColors.coffee.op(0.12)),
            ),
            boxShadow: selected
                ? AppTheme.glow(c, opacity: 0.32, blur: 16, y: 6)
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontBody,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : (isDark ? AppColors.mutedLight : AppColors.mutedDark),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});
  final GameDef game;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String locale = l10n.languageCode;
    final ThemeData theme = Theme.of(context);
    final Color color = AppColors.forSeed(game.key);

    return GlassCard(
      tint: color,
      tintOpacity: 0.14,
      glowColor: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: AppGradients.from(color),
                  boxShadow: AppTheme.glow(color, opacity: 0.35, blur: 16, y: 6),
                ),
                alignment: Alignment.center,
                child: Text(game.icon, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(game.name(locale), style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        GlassPill(
                          label: '${game.minPlayers}–${game.maxPlayers}',
                          icon: Icons.group_rounded,
                          color: color,
                          dense: true,
                        ),
                        GlassPill(
                          label: '${game.roundSeconds}${l10n.t('seconds')}',
                          icon: Icons.timer_outlined,
                          color: AppColors.gold,
                          dense: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(game.description(locale), style: theme.textTheme.bodyMedium),
          if (game.categories.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final String c in game.categories)
                  GlassPill(
                    label: l10n.category(c),
                    color: AppColors.forSeed(c),
                    dense: true,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: GradientButton(
                  label: l10n.t('create_room'),
                  icon: Icons.add_rounded,
                  height: 48,
                  shine: false,
                  colors: <Color>[
                    AppColors.lighten(color, 0.06),
                    AppColors.deepen(color, 0.14),
                  ],
                  onTap: () => context.push('/create-room?game=${game.key}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GhostButton(
                  label: l10n.t('public_rooms'),
                  icon: Icons.public_rounded,
                  height: 48,
                  onTap: () => context.push('/public-rooms?game=${game.key}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
