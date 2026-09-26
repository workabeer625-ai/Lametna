import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/catalog_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<Profile?> async = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('profile')),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.t('setup_profile'),
            onPressed: () => context.push('/profile-setup'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (Object e, _) =>
            ErrorView(error: e, onRetry: () => ref.read(profileProvider.notifier).refresh()),
        data: (Profile? profile) {
          if (profile == null) {
            return EmptyView(
              message: l10n.t('sign_in'),
              action: FilledButton(
                onPressed: () => context.go('/welcome'),
                child: Text(l10n.t('sign_in')),
              ),
            );
          }

          final AsyncValue<List<Achievement>> badges =
              ref.watch(achievementsProvider(profile.id));
          final List<Country> countries =
              ref.watch(countriesProvider).valueOrNull ?? <Country>[];
          final Country? country = profile.countryCode == null
              ? null
              : countries.where((Country c) => c.code == profile.countryCode).firstOrNull;

          return RefreshIndicator(
            onRefresh: () => ref.read(profileProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Center(
                  child: Column(
                    children: <Widget>[
                      AppAvatar(avatarKey: profile.avatarKey, size: 96),
                      const SizedBox(height: 12),
                      Text(profile.nickname,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (profile.showCountry && country != null)
                        Text('${country.flagEmoji} ${country.name(l10n.languageCode)}'),
                      if (profile.isGuest)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Chip(
                            label: Text(l10n.t('guest_mode')),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: l10n.t('stats'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      StatTile(
                          label: l10n.t('level'),
                          value: '${profile.level}',
                          icon: Icons.military_tech_outlined),
                      StatTile(
                          label: l10n.t('total_points'),
                          value: '${profile.totalPoints}',
                          icon: Icons.stars_outlined),
                      StatTile(
                          label: l10n.t('games_played'),
                          value: '${profile.gamesPlayed}',
                          icon: Icons.sports_esports_outlined),
                      StatTile(
                          label: l10n.t('games_won'),
                          value: '${profile.gamesWon}',
                          icon: Icons.emoji_events_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SectionCard(
                  title: l10n.t('badges'),
                  child: badges.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Text(l10n.t('error_body')),
                    data: (List<Achievement> list) {
                      final List<Achievement> earned =
                          list.where((Achievement a) => a.isEarned).toList();
                      if (earned.isEmpty) {
                        return Text(l10n.t('no_badges'));
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: list
                            .map((Achievement a) => Opacity(
                                  opacity: a.isEarned ? 1 : 0.35,
                                  child: Chip(
                                    avatar: Text(a.icon),
                                    label: Text(a.name(l10n.languageCode)),
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                if (profile.createdAt != null)
                  Center(
                    child: Text(
                      '${l10n.t('member_since')}: '
                      '${profile.createdAt!.toLocal().toString().split(' ').first}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
