import 'package:flutter/material.dart';

import '../models/player.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Glowing circular avatar for a player.
class AvatarOrb extends StatelessWidget {
  const AvatarOrb({
    super.key,
    required this.player,
    this.size = 54,
    this.showGlow = true,
    this.ring = true,
  });

  final Player player;
  final double size;
  final bool showGlow;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[
            player.color.op(0.55),
            AppColors.deepen(player.color, 0.30).op(0.75),
          ],
        ),
        border: ring ? Border.all(color: player.color.op(0.55), width: 1.4) : null,
        boxShadow: showGlow
            ? AppTheme.glow(player.color, opacity: 0.30, blur: 18, y: 6)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        player.emoji,
        style: TextStyle(fontSize: size * 0.44, height: 1.1),
      ),
    );
  }
}

/// A stacked row of avatars — "who is playing" at a glance.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.players,
    this.max = 5,
    this.size = 34,
  });

  final List<Player> players;
  final int max;
  final double size;

  @override
  Widget build(BuildContext context) {
    final List<Player> shown = players.take(max).toList();
    final int extra = players.length - shown.length;
    final double overlap = size * 0.34;

    return SizedBox(
      height: size,
      width: shown.isEmpty
          ? 0
          : size + (shown.length - 1) * (size - overlap) + (extra > 0 ? size - overlap : 0),
      child: Stack(
        children: <Widget>[
          for (int i = 0; i < shown.length; i++)
            Positioned(
              right: i * (size - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bgAlt, width: 2),
                ),
                child: AvatarOrb(player: shown[i], size: size, showGlow: false),
              ),
            ),
          if (extra > 0)
            Positioned(
              right: shown.length * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.op(0.10),
                  border: Border.all(color: AppColors.bgAlt, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$extra',
                  style: TextStyle(
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
