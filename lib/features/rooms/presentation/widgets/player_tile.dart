import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../models/models.dart';

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
    final ColorScheme colors = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: AppAvatar(
        avatarKey: player.avatarKey,
        size: 42,
        dimmed: !player.isAlive || player.isDisconnected,
        badge: player.isDisconnected
            ? const _Dot(color: Colors.grey, icon: Icons.wifi_off)
            : (showReady && player.isReady
                ? const _Dot(color: Colors.green, icon: Icons.check)
                : null),
      ),
      title: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              player.nickname,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: player.isAlive ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          if (isMe)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 6),
              child: Text('(${l10n.t('you')})',
                  style: TextStyle(fontSize: 12, color: colors.outline)),
            ),
          if (isHost)
            const Padding(
              padding: EdgeInsetsDirectional.only(start: 6),
              child: Icon(Icons.star, size: 15, color: Color(0xFFD9A441)),
            ),
          if (player.isMuted)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 6),
              child: Icon(Icons.volume_off, size: 15, color: colors.error),
            ),
        ],
      ),
      subtitle: Text(
        player.isSpectator
            ? l10n.t('spectators')
            : (!player.isAlive
                ? l10n.t('you_are_dead')
                : (player.isReady ? l10n.t('ready') : l10n.t('not_ready'))),
        style: TextStyle(fontSize: 12, color: colors.outline),
      ),
      trailing: trailing ??
          (player.score > 0
              ? Text('${player.score}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: colors.primary, fontSize: 16))
              : null),
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
        child: Icon(icon, size: 10, color: Colors.white),
      );
}
