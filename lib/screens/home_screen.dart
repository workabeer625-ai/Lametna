import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../data/game_catalog.dart';
import '../models/party_game.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_orb.dart';
import '../widgets/brand.dart';
import '../widgets/fade_in.dart';
import '../widgets/game_tile.dart';
import '../widgets/glass.dart';
import '../widgets/gradient_button.dart';
import '../widgets/pressable.dart';
import '../widgets/section_header.dart';
import 'game_detail_screen.dart';
import 'players_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onSeeAllGames});

  final VoidCallback? onSeeAllGames;

  String get _greeting {
    final int h = DateTime.now().hour;
    if (h < 5) return 'سهرة موفقة 🌙';
    if (h < 12) return 'صباح الفل ☀️';
    if (h < 17) return 'نهارك سعيد 👋';
    return 'مساء الفل ✨';
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final List<PartyGame> games = GameCatalog.games;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: FadeInUp(
                child: Row(
                  children: <Widget>[
                    const BrandMark(size: 42),
                    const SizedBox(width: 10),
                    const BrandWordmark(fontSize: 24),
                    const Spacer(),
                    GlassIconButton(
                      icon: Icons.notifications_none_rounded,
                      badge: true,
                      onTap: () => _toast(context, 'ما في إشعارات جديدة'),
                    ),
                    const SizedBox(width: 10),
                    GlassIconButton(
                      icon: Icons.person_add_alt_1_rounded,
                      onTap: () => Nav.push(context, const PlayersScreen()),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Greeting ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
              child: FadeInUp(
                delay: const Duration(milliseconds: 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_greeting, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      'وش نلعب الليلة؟',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Quick start ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: FadeInUp(
                delay: const Duration(milliseconds: 150),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  tint: state.accent,
                  tintOpacity: 0.14,
                  glowColor: state.accent,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                GlassPill(
                                  label: '${state.players.length} لاعبين جاهزين',
                                  icon: Icons.group_rounded,
                                  color: state.accent,
                                  dense: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'ابدأ لمّة سريعة',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'نختار لك لعبة عشوائية وننطلق فوراً',
                              style: TextStyle(fontSize: 12.5, color: AppColors.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Pressable(
                        onTap: () {
                          final PartyGame g = (GameCatalog.games.toList()..shuffle()).first;
                          state.game = g;
                          Nav.push(context, GameDetailScreen(game: g));
                        },
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppGradients.from(state.accent),
                            boxShadow: AppTheme.glow(state.accent, opacity: 0.5, blur: 22, y: 8),
                          ),
                          child: const Icon(
                            Icons.casino_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Featured carousel ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 26),
              child: FadeInUp(
                delay: const Duration(milliseconds: 220),
                child: _FeaturedCarousel(games: GameCatalog.featured),
              ),
            ),
          ),

          // ── Players strip ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: FadeInUp(
                delay: const Duration(milliseconds: 280),
                child: GlassCard(
                  onTap: () => Nav.push(context, const PlayersScreen()),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: <Widget>[
                      AvatarStack(players: state.players),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text(
                              'من في اللمة؟',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              '${state.players.length} لاعبين • اضغط للتعديل',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_left_rounded, color: Colors.white.op(0.4)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Games grid ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: FadeInUp(
                delay: const Duration(milliseconds: 320),
                child: SectionHeader(
                  title: 'كل الألعاب',
                  subtitle: '${games.length} ألعاب تكفي سهرتكم كاملة',
                  actionLabel: 'عرض الكل',
                  accent: state.accent,
                  onAction: onSeeAllGames,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.80,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int i) {
                  final PartyGame g = games[i];
                  return FadeInUp(
                    delay: Duration(milliseconds: 360 + i * 60),
                    child: GameTile(
                      game: g,
                      index: i,
                      onTap: () {
                        state.game = g;
                        Nav.push(context, GameDetailScreen(game: g));
                      },
                    ),
                  );
                },
                childCount: games.length > 6 ? 6 : games.length,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: GhostButton(
                label: 'تصفّح كل الألعاب',
                icon: Icons.grid_view_rounded,
                onTap: onSeeAllGames,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

/// Horizontal hero carousel with depth-scaling pages and a dot indicator.
class _FeaturedCarousel extends StatefulWidget {
  const _FeaturedCarousel({required this.games});
  final List<PartyGame> games;

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  late final PageController _pc = PageController(viewportFraction: 0.86);
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pc.addListener(() {
      if (!mounted) return;
      setState(() => _page = _pc.page ?? 0);
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);

    return Column(
      children: <Widget>[
        SizedBox(
          height: 222,
          child: PageView.builder(
            controller: _pc,
            itemCount: widget.games.length,
            padEnds: true,
            itemBuilder: (BuildContext context, int i) {
              final double delta = (_page - i).abs().clamp(0.0, 1.0);
              final double scale = 1 - delta * 0.07;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Opacity(
                  opacity: 1 - delta * 0.25,
                  child: FeaturedGameCard(
                    game: widget.games[i],
                    scale: scale,
                    onTap: () {
                      state.game = widget.games[i];
                      Nav.push(context, GameDetailScreen(game: widget.games[i]));
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int i = 0; i < widget.games.length; i++)
              AnimatedContainer(
                duration: AppTheme.fast,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: (_page.round() == i) ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: (_page.round() == i)
                      ? widget.games[i].primary
                      : Colors.white.op(0.18),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
