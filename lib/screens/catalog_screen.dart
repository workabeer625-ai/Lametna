import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../data/game_catalog.dart';
import '../models/party_game.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_in.dart';
import '../widgets/game_tile.dart';
import '../widgets/pressable.dart';
import 'game_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _category = 'الكل';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);

    List<PartyGame> games = GameCatalog.inCategory(_category);
    if (_query.trim().isNotEmpty) {
      final String q = _query.trim();
      games = games
          .where((PartyGame g) => g.name.contains(q) || g.tagline.contains(q))
          .toList();
    }

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: FadeInUp(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('مكتبة الألعاب',
                        style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text(
                      'اختر اللعبة اللي تناسب مزاج اللمة',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Search ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: FadeInUp(
                delay: const Duration(milliseconds: 80),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.white.op(0.06),
                        border: Border.all(color: Colors.white.op(0.12)),
                      ),
                      child: TextField(
                        onChanged: (String v) => setState(() => _query = v),
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: state.accent,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن لعبة…',
                          hintStyle: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.inkMuted, size: 20),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Category chips ──────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeInUp(
              delay: const Duration(milliseconds: 140),
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  itemCount: GameCatalog.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int i) {
                    final String c = GameCatalog.categories[i];
                    final bool selected = c == _category;
                    return Pressable(
                      onTap: () => setState(() => _category = c),
                      scale: 0.93,
                      child: AnimatedContainer(
                        duration: AppTheme.fast,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          gradient: selected ? AppGradients.from(state.accent) : null,
                          color: selected ? null : Colors.white.op(0.06),
                          border: Border.all(
                            color: selected
                                ? Colors.white.op(0.25)
                                : Colors.white.op(0.10),
                          ),
                          boxShadow: selected
                              ? AppTheme.glow(state.accent, opacity: 0.35, blur: 16, y: 6)
                              : null,
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : AppColors.inkMuted,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          if (games.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: <Widget>[
                    Text('🫥', style: TextStyle(fontSize: 46, color: Colors.white.op(0.5))),
                    const SizedBox(height: 12),
                    Text(
                      'ما لقينا لعبة بهذا الاسم',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
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
                      delay: Duration(milliseconds: 60 * i),
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
                  childCount: games.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
