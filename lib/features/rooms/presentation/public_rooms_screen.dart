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
import '../../../providers/rooms_provider.dart';

class PublicRoomsScreen extends ConsumerStatefulWidget {
  const PublicRoomsScreen({super.key, this.gameKey});
  final String? gameKey;

  @override
  ConsumerState<PublicRoomsScreen> createState() => _PublicRoomsScreenState();
}

class _PublicRoomsScreenState extends ConsumerState<PublicRoomsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.gameKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(publicRoomsFilterProvider.notifier).state = widget.gameKey;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<Room>> rooms = ref.watch(publicRoomsProvider);
    final int count = rooms.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              ScreenHeader(
                title: l10n.t('public_rooms'),
                subtitle: count == 0 ? null : '$count',
                accent: AppColors.green,
                onBack: context.canPop() ? () => context.pop() : null,
                actions: <Widget>[
                  GlassIconButton(
                    icon: Icons.refresh_rounded,
                    onTap: () => ref.invalidate(publicRoomsProvider),
                  ),
                ],
              ),
              Expanded(
                child: rooms.when(
                  loading: () => const LoadingView(),
                  error: (Object e, _) => ErrorView(
                      error: e, onRetry: () => ref.invalidate(publicRoomsProvider)),
                  data: (List<Room> list) {
                    if (list.isEmpty) {
                      return EmptyView(
                        icon: Icons.meeting_room_outlined,
                        message: l10n.t('no_public_rooms'),
                        action: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: GradientButton(
                            label: l10n.t('create_room'),
                            icon: Icons.add_rounded,
                            onTap: () => context.push('/create-room'),
                          ),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(publicRoomsProvider),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        itemCount: list.length,
                        itemBuilder: (_, int i) => FadeInUp(
                          delay: Duration(milliseconds: 40 * (i < 8 ? i : 8)),
                          child: _RoomCard(room: list[i]),
                        ),
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

class _RoomCard extends ConsumerWidget {
  const _RoomCard({required this.room});
  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    final GameDef? game = ref.watch(gameByKeyProvider(room.gameKey));
    final bool joinable = !room.isFull && room.status == RoomStatus.waiting;
    final Color seed = AppColors.forSeed(room.gameKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        glowColor: seed,
        onTap: () => context.push('/join?code=${room.code}'),
        child: Row(
          children: <Widget>[
            // أيقونة اللعبة
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: AppGradients.from(seed),
                borderRadius: BorderRadius.circular(AppTheme.rSm),
                boxShadow: AppTheme.glow(seed, opacity: 0.3, blur: 16, y: 6),
              ),
              alignment: Alignment.center,
              child: Text(game?.icon ?? '🎮', style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          room.title.isEmpty
                              ? (game?.name(l10n.languageCode) ?? room.gameKey)
                              : room.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ),
                      if (room.hasPassword)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: 6),
                          child: Icon(Icons.lock_rounded, size: 14, color: muted),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      GlassPill(
                        dense: true,
                        icon: Icons.person_outline_rounded,
                        label: '${room.playerCount}/${room.maxPlayers}',
                        color: room.isFull ? AppColors.danger : AppColors.green,
                      ),
                      GlassPill(
                        dense: true,
                        icon: Icons.tag_rounded,
                        label: room.code,
                        color: AppColors.gold,
                      ),
                      if (room.status == RoomStatus.playing)
                        GlassPill(
                          dense: true,
                          icon: Icons.play_circle_outline_rounded,
                          label: l10n.t('start_game'),
                          color: AppColors.rose,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _JoinChip(
              label: joinable ? l10n.t('join') : l10n.t('join_as_spectator'),
              color: joinable ? AppColors.green : AppColors.coffee,
              onTap: () => context.push('/join?code=${room.code}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinChip extends StatelessWidget {
  const _JoinChip({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 96),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppGradients.from(color),
          borderRadius: BorderRadius.circular(100),
          boxShadow: AppTheme.glow(color, opacity: 0.34, blur: 16, y: 6),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
