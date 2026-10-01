import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/design_kit.dart';
import '../../../models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/catalog_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final Profile? profile = ref.watch(profileProvider).valueOrNull;
    final List<GameDef> games = ref.watch(gamesProvider).valueOrNull ?? <GameDef>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(gamesProvider);
              await ref.read(profileProvider.notifier).refresh();
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: <Widget>[
                // ── الترويسة ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: FadeInUp(
                      child: Row(
                        children: <Widget>[
                          const BrandMark(size: 38),
                          const SizedBox(width: 10),
                          BrandWordmark(text: l10n.t('app_name'), fontSize: 23),
                          const Spacer(),
                          GlassIconButton(
                            icon: Icons.settings_outlined,
                            onTap: () => context.push('/settings'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── بطاقة الترحيب ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: FadeInUp(
                      delay: const Duration(milliseconds: 80),
                      child: _GreetingCard(profile: profile),
                    ),
                  ),
                ),

                // ── إجراءات سريعة ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: FadeInUp(
                      delay: const Duration(milliseconds: 150),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _ActionTile(
                                  icon: Icons.add_circle_outline_rounded,
                                  label: l10n.t('create_room'),
                                  color: AppColors.green,
                                  onTap: () => context.push('/create-room'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionTile(
                                  icon: Icons.vpn_key_outlined,
                                  label: l10n.t('join_by_code'),
                                  color: AppColors.gold,
                                  onTap: () => context.push('/join'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _ActionTile(
                            icon: Icons.public_rounded,
                            label: l10n.t('public_rooms'),
                            color: AppColors.coffee,
                            wide: true,
                            onTap: () => context.push('/public-rooms'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── عنوان الألعاب ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                    child: FadeInUp(
                      delay: const Duration(milliseconds: 220),
                      child: SectionHeader(
                        title: l10n.t('games'),
                        actionLabel: l10n.t('all_games'),
                        onAction: () => context.go('/games'),
                      ),
                    ),
                  ),
                ),

                // ── شريط الألعاب الأفقي ────────────────────────
                if (games.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: FadeInUp(
                      delay: const Duration(milliseconds: 280),
                      child: SizedBox(
                        height: 186,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                          itemCount: games.length > 8 ? 8 : games.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (BuildContext context, int i) =>
                              _GameCardMini(game: games[i]),
                        ),
                      ),
                    ),
                  ),

                // ── قائمة مختصرة ───────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < games.length && i < 4; i++)
                          FadeInUp(
                            delay: Duration(milliseconds: 320 + i * 60),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _GameRow(game: games[i]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// بطاقة ترحيب زجاجية: الأفاتار، المستوى، النقاط وشريط التقدّم.
class _GreetingCard extends StatelessWidget {
  const _GreetingCard({this.profile});
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final int points = profile?.totalPoints ?? 0;
    final int level = profile?.level ?? 1;
    final double progress = ((points % 100) / 100).clamp(0.0, 1.0);

    return GlassCard(
      glowColor: AppColors.gold,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.gold,
                  boxShadow: AppTheme.glow(AppColors.gold, opacity: 0.32, blur: 20, y: 8),
                ),
                child: AppAvatar(avatarKey: profile?.avatarKey, size: 56),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${l10n.t('welcome_back')}، ${profile?.nickname ?? '—'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        GlassPill(
                          label: '${l10n.t('level')} $level',
                          icon: Icons.military_tech_rounded,
                          color: AppColors.gold,
                          dense: true,
                        ),
                        GlassPill(
                          label: '$points ${l10n.t('points')}',
                          icon: Icons.star_rounded,
                          color: AppColors.green,
                          dense: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: <Widget>[
                Container(
                  height: 7,
                  color: theme.colorScheme.primary.op(0.10),
                ),
                FractionallySizedBox(
                  widthFactor: progress == 0 ? 0.04 : progress,
                  child: Container(
                    height: 7,
                    decoration: const BoxDecoration(gradient: AppGradients.gold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// زر إجراء سريع بتدرّج لوني وتوهّج.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: wide ? 16 : 18, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.rMd),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: <Color>[
              color.op(isDark ? 0.26 : 0.16),
              color.op(isDark ? 0.10 : 0.06),
            ],
          ),
          border: Border.all(color: color.op(0.30)),
          boxShadow: AppTheme.glow(color, opacity: isDark ? 0.20 : 0.14, blur: 20, y: 8),
        ),
        child: wide
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontBody,
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              )
            : Column(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: AppGradients.from(color),
                      boxShadow: AppTheme.glow(color, opacity: 0.35, blur: 14, y: 5),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontBody,
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// بطاقة لعبة مربّعة في الشريط الأفقي.
class _GameCardMini extends StatelessWidget {
  const _GameCardMini({required this.game});
  final GameDef game;

  @override
  Widget build(BuildContext context) {
    final String locale = context.l10n.languageCode;
    final Color color = AppColors.forSeed(game.key);

    return SizedBox(
      width: 152,
      child: GlassCard(
        onTap: () => context.push('/create-room?game=${game.key}'),
        padding: const EdgeInsets.all(14),
        tint: color,
        tintOpacity: 0.16,
        glowColor: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: AppGradients.from(color),
                boxShadow: AppTheme.glow(color, opacity: 0.35, blur: 14, y: 5),
              ),
              alignment: Alignment.center,
              child: Text(game.icon, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 12),
            Text(
              game.name(locale),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                game.description(locale),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            GlassPill(
              label: '${game.minPlayers}–${game.maxPlayers}',
              icon: Icons.group_rounded,
              color: color,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// صف لعبة في القائمة المختصرة.
class _GameRow extends StatelessWidget {
  const _GameRow({required this.game});
  final GameDef game;

  @override
  Widget build(BuildContext context) {
    final String locale = context.l10n.languageCode;
    final Color color = AppColors.forSeed(game.key);
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    return GlassCard(
      onTap: () => context.push('/create-room?game=${game.key}'),
      radius: AppTheme.rMd,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      tint: color,
      tintOpacity: 0.10,
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: color.op(0.16),
              border: Border.all(color: color.op(0.28)),
            ),
            alignment: Alignment.center,
            child: Text(game.icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  game.name(locale),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  game.description(locale),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            color: color,
          ),
        ],
      ),
    );
  }
}
