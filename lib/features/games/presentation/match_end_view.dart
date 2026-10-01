import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/design_kit.dart';
import '../../../models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/room_provider.dart';

/// نهاية المباراة: الترتيب النهائي، الفائزون، وإعادة اللعب.
class MatchEndView extends ConsumerWidget {
  const MatchEndView({
    super.key,
    required this.roomId,
    required this.state,
    required this.controller,
    required this.isHost,
  });

  final String roomId;
  final RoomState state;
  final RoomController controller;
  final bool isHost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    final GameSession? session = state.session;
    final List<Map<String, dynamic>> standings =
        session?.standings ?? <Map<String, dynamic>>[];
    final List<String> winners = session?.winners ?? <String>[];
    final bool iWon = winners.contains(controller.myId);
    final String? reason = session?.result?['reason'] as String?;

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
        await ref.read(profileProvider.notifier).refresh();
      } catch (e) {
        if (context.mounted) {
          context.showSnack(ErrorMapper.map(e).localized(l10n.languageCode), error: true);
        }
      }
    }

    return Stack(
      children: <Widget>[
        SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: <Widget>[
                    // ── العنوان ─────────────────────────────
                    FadeInUp(
                      child: Column(
                        children: <Widget>[
                          Text(iWon ? '🏆' : '🎉',
                              style: const TextStyle(fontSize: 72)),
                          const SizedBox(height: 10),
                          ShaderMask(
                            shaderCallback: (Rect r) =>
                                AppGradients.gold.createShader(r),
                            child: Text(
                              l10n.t('match_over'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          if (reason == 'mafia_mafia' ||
                              reason == 'mafia_citizens') ...<Widget>[
                            const SizedBox(height: 10),
                            GlassPill(
                              icon: Icons.flag_rounded,
                              label: reason == 'mafia_mafia'
                                  ? l10n.t('mafia_wins')
                                  : l10n.t('citizens_wins'),
                              color: reason == 'mafia_mafia'
                                  ? AppColors.danger
                                  : AppColors.green,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── الترتيب النهائي ─────────────────────
                    const SizedBox(height: 26),
                    FadeInUp(
                      delay: const Duration(milliseconds: 90),
                      child: SectionHeader(title: l10n.t('final_results')),
                    ),
                    const SizedBox(height: 12),
                    if (standings.isEmpty)
                      Text(
                        l10n.t('empty'),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: muted),
                      )
                    else
                      ...List<Widget>.generate(standings.length, (int i) {
                        final Map<String, dynamic> row = standings[i];
                        final bool isWinner = winners.contains(row['user_id']);
                        final Color tone =
                            isWinner ? AppColors.gold : AppColors.latte;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: FadeInUp(
                            delay: Duration(
                                milliseconds: 120 + 40 * (i < 8 ? i : 8)),
                            offset: 10,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(12, 11, 16, 11),
                              decoration: BoxDecoration(
                                color: isWinner
                                    ? AppColors.gold.op(isDark ? 0.16 : 0.12)
                                    : (isDark
                                        ? AppColors.white.op(0.05)
                                        : AppColors.white.op(0.62)),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.rMd),
                                border: Border.all(
                                  color: isWinner
                                      ? AppColors.gold.op(0.45)
                                      : (isDark
                                              ? AppColors.white
                                              : AppColors.coffee)
                                          .op(0.10),
                                ),
                                boxShadow: isWinner
                                    ? AppTheme.glow(AppColors.gold,
                                        opacity: 0.24, blur: 20, y: 8)
                                    : null,
                              ),
                              child: Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 26,
                                    child: Text(
                                      '${i + 1}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: isWinner ? tone : muted,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppGradients.from(tone),
                                    ),
                                    child: AppAvatar(
                                      avatarKey: row['avatar_key'] as String?,
                                      size: 38,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Row(
                                      children: <Widget>[
                                        Flexible(
                                          child: Text(
                                            '${row['nickname']}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: ink,
                                            ),
                                          ),
                                        ),
                                        if (isWinner)
                                          const Padding(
                                            padding:
                                                EdgeInsetsDirectional.only(start: 6),
                                            child: Text('👑',
                                                style: TextStyle(fontSize: 14)),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${row['score']}',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: isWinner ? AppColors.gold : ink,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.t('points'),
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: muted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),

              // ── الأزرار ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: GhostButton(
                        label: l10n.t('home'),
                        icon: Icons.home_rounded,
                        height: 54,
                        onTap: () async {
                          await controller.leave();
                          if (context.mounted) context.go('/home');
                        },
                      ),
                    ),
                    if (isHost) ...<Widget>[
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientButton(
                          label: l10n.t('play_again'),
                          icon: Icons.replay_rounded,
                          height: 54,
                          onTap: () => run(controller.playAgain),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (iWon) const IgnorePointer(child: ConfettiOverlay(count: 90)),
      ],
    );
  }
}
