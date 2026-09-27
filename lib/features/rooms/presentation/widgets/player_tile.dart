import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../models/models.dart';

/// بطاقة لاعب زجاجية — تُستعمل في غرفة الانتظار وقوائم اللاعبين.
class PlayerTile extends StatelessWidget {
  const PlayerTile({
    super.key,
    required this.player,
    required this.isHost,
    this.isMe = false,
    this.showReady = true,
    this.trailing,
    this.onTap,
  });

  final RoomPlayer player;
  final bool isHost;
  final bool isMe;
  final bool showReady;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    final bool ready = showReady && player.isReady;
    final Color accent = !player.isAlive
        ? AppColors.danger
        : (ready ? AppColors.green : (isHost ? AppColors.gold : AppColors.latte));

    final String status = player.isSpectator
        ? l10n.t('spectators')
        : (!player.isAlive
            ? l10n.t('you_are_dead')
            : (player.isReady ? l10n.t('ready') : l10n.t('not_ready')));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: onTap,
        scale: onTap == null ? 1 : 0.98,
        child: AnimatedContainer(
          duration: AppTheme.fast,
          curve: AppTheme.ease,
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          decoration: BoxDecoration(
            color: isMe
                ? accent.op(isDark ? 0.14 : 0.10)
                : (isDark ? AppColors.white.op(0.05) : AppColors.white.op(0.62)),
            borderRadius: BorderRadius.circular(AppTheme.rMd),
            border: Border.all(
              color: isMe
                  ? accent.op(0.45)
                  : (isDark ? AppColors.white : AppColors.coffee).op(0.10),
              width: isMe ? 1.4 : 1,
            ),
            boxShadow: ready ? AppTheme.glow(accent, opacity: 0.18, blur: 16, y: 6) : null,
          ),
          child: Row(
            children: <Widget>[
              // الأفاتار مع حلقة ملوّنة
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.from(accent),
                ),
                child: AppAvatar(
                  avatarKey: player.avatarKey,
                  size: 42,
                  dimmed: !player.isAlive || player.isDisconnected,
                  badge: player.isDisconnected
                      ? const _Dot(color: AppColors.mutedDark, icon: Icons.wifi_off)
                      : (ready ? const _Dot(color: AppColors.green, icon: Icons.check) : null),
                ),
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
                            player.nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: ink,
                              decoration:
                                  player.isAlive ? null : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        if (isMe)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 6),
                            child: Text('(${l10n.t('you')})',
                                style: TextStyle(fontSize: 11, color: muted)),
                          ),
                        if (isHost)
                          const Padding(
                            padding: EdgeInsetsDirectional.only(start: 6),
                            child: Icon(Icons.star_rounded, size: 16, color: AppColors.gold),
                          ),
                        if (player.isMuted)
                          const Padding(
                            padding: EdgeInsetsDirectional.only(start: 6),
                            child:
                                Icon(Icons.volume_off_rounded, size: 15, color: AppColors.danger),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: <Widget>[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w600, color: muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (player.score > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: AppGradients.gold,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${player.score}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.espresso,
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

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
        ),
        child: Icon(icon, size: 10, color: AppColors.white),
      );
}
