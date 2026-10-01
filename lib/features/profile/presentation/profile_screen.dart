import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/design_kit.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/catalog_provider.dart';
import '../../auth/presentation/upgrade_account_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<Profile?> async = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              ScreenHeader(
                title: l10n.t('profile'),
                actions: <Widget>[
                  GlassIconButton(
                    icon: Icons.edit_outlined,
                    onTap: () => context.push('/profile-setup'),
                  ),
                  const SizedBox(width: 8),
                  GlassIconButton(
                    icon: Icons.settings_outlined,
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ),
              Expanded(
                child: async.when(
                  loading: () => const LoadingView(),
                  error: (Object e, _) => ErrorView(
                      error: e,
                      onRetry: () => ref.read(profileProvider.notifier).refresh()),
                  data: (Profile? profile) {
                    if (profile == null) {
                      return EmptyView(
                        message: l10n.t('sign_in'),
                        action: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: GradientButton(
                            label: l10n.t('sign_in'),
                            icon: Icons.login_rounded,
                            onTap: () => context.go('/welcome'),
                          ),
                        ),
                      );
                    }
                    return _ProfileBody(profile: profile);
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

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    final AsyncValue<List<Achievement>> badges =
        ref.watch(achievementsProvider(profile.id));
    final List<Country> countries =
        ref.watch(countriesProvider).valueOrNull ?? <Country>[];
    final bool isGuest = ref.watch(isGuestProvider);

    final Country? country = profile.countryCode == null
        ? null
        : countries.where((Country c) => c.code == profile.countryCode).firstOrNull;

    final int inLevel = profile.totalPoints % 100;

    return RefreshIndicator(
      onRefresh: () => ref.read(profileProvider.notifier).refresh(),
      child: ListView(
        physics:
            const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
        children: <Widget>[
          // ── الهوية ─────────────────────────────────────────
          FadeInUp(
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.gold,
                    boxShadow:
                        AppTheme.glow(AppColors.gold, opacity: 0.4, blur: 30, y: 12),
                  ),
                  child: AppAvatar(avatarKey: profile.avatarKey, size: 104),
                ),
                const SizedBox(height: 14),
                Text(
                  profile.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    if (profile.showCountry && country != null)
                      GlassPill(
                        dense: true,
                        label:
                            '${country.flagEmoji} ${country.name(l10n.languageCode)}',
                        color: AppColors.green,
                      ),
                    if (isGuest)
                      GlassPill(
                        dense: true,
                        icon: Icons.person_outline_rounded,
                        label: l10n.t('guest_badge'),
                        color: AppColors.amber,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── دعوة الضيف لإكمال حسابه ────────────────────────
          if (isGuest) ...<Widget>[
            const SizedBox(height: 18),
            FadeInUp(
              delay: const Duration(milliseconds: 60),
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                glowColor: AppColors.green,
                onTap: () => showUpgradeAccountSheet(context),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppGradients.green,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded,
                          size: 22, color: AppColors.white),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            l10n.t('upgrade_title'),
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: ink),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            l10n.t('upgrade_body'),
                            style: TextStyle(
                                fontSize: 11.5,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                                color: muted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_left_rounded,
                        size: 22, color: muted.op(0.6)),
                  ],
                ),
              ),
            ),
          ],

          // ── بطاقة المستوى ──────────────────────────────────
          const SizedBox(height: 20),
          FadeInUp(
            delay: const Duration(milliseconds: 80),
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              glowColor: AppColors.gold,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        '${l10n.t('level')} ${profile.level}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: ink,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$inLevel / 100',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Stack(
                      children: <Widget>[
                        Container(
                          height: 10,
                          color: (isDark ? AppColors.white : AppColors.coffee).op(0.10),
                        ),
                        FractionallySizedBox(
                          widthFactor: (inLevel / 100).clamp(0.02, 1.0),
                          child: Container(
                            height: 10,
                            decoration: const BoxDecoration(gradient: AppGradients.gold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── الإحصاءات ──────────────────────────────────────
          const SizedBox(height: 14),
          FadeInUp(
            delay: const Duration(milliseconds: 140),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    icon: Icons.stars_rounded,
                    label: l10n.t('total_points'),
                    value: '${profile.totalPoints}',
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.sports_esports_rounded,
                    label: l10n.t('games_played'),
                    value: '${profile.gamesPlayed}',
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FadeInUp(
            delay: const Duration(milliseconds: 180),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    icon: Icons.emoji_events_rounded,
                    label: l10n.t('games_won'),
                    value: '${profile.gamesWon}',
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.military_tech_rounded,
                    label: l10n.t('level'),
                    value: '${profile.level}',
                    color: AppColors.rose,
                  ),
                ),
              ],
            ),
          ),

          // ── الأوسمة ────────────────────────────────────────
          const SizedBox(height: 22),
          FadeInUp(
            delay: const Duration(milliseconds: 220),
            child: SectionHeader(title: l10n.t('badges')),
          ),
          const SizedBox(height: 10),
          FadeInUp(
            delay: const Duration(milliseconds: 260),
            child: GlassCard(
              child: badges.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => Text(l10n.t('error_body'),
                    style: TextStyle(color: muted, fontSize: 13)),
                data: (List<Achievement> list) {
                  if (list.where((Achievement a) => a.isEarned).isEmpty) {
                    return Row(
                      children: <Widget>[
                        Icon(Icons.workspace_premium_outlined,
                            size: 20, color: muted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(l10n.t('no_badges'),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: muted)),
                        ),
                      ],
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: list
                        .map((Achievement a) => _Badge(
                              achievement: a,
                              locale: l10n.languageCode,
                            ))
                        .toList(),
                  );
                },
              ),
            ),
          ),

          if (profile.createdAt != null) ...<Widget>[
            const SizedBox(height: 18),
            Center(
              child: Text(
                '${l10n.t('member_since')}: '
                '${profile.createdAt!.toLocal().toString().split(' ').first}',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: muted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.white.op(0.05) : AppColors.white.op(0.62),
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        border:
            Border.all(color: (isDark ? AppColors.white : AppColors.coffee).op(0.10)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppGradients.from(color),
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.glow(color, opacity: 0.28, blur: 14, y: 5),
            ),
            child: Icon(icon, size: 19, color: AppColors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 19,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.achievement, required this.locale});
  final Achievement achievement;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final bool earned = achievement.isEarned;

    return Opacity(
      opacity: earned ? 1 : 0.4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: earned ? AppGradients.gold : null,
          color: earned
              ? null
              : (isDark ? AppColors.white.op(0.06) : AppColors.white.op(0.6)),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: earned
                ? AppColors.goldDeep.op(0.4)
                : (isDark ? AppColors.white : AppColors.coffee).op(0.12),
          ),
          boxShadow:
              earned ? AppTheme.glow(AppColors.gold, opacity: 0.26, blur: 14, y: 5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(achievement.icon, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              achievement.name(locale),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: earned ? AppColors.espresso : ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
