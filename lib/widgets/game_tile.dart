import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/party_game.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'pressable.dart';

/// Decorative rings painted inside game cards.
class _RingsPainter extends CustomPainter {
  _RingsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * 0.12, size.height * 0.22);
    for (int i = 1; i <= 4; i++) {
      final Paint p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = color.op(0.20 - i * 0.03);
      canvas.drawCircle(center, size.shortestSide * 0.28 * i, p);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => old.color != color;
}

/// Large highlighted card used in the home carousel.
class FeaturedGameCard extends StatelessWidget {
  const FeaturedGameCard({
    super.key,
    required this.game,
    this.onTap,
    this.scale = 1.0,
  });

  final PartyGame game;
  final VoidCallback? onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.97,
      child: Transform.scale(
        scale: scale,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.rXl),
            gradient: game.gradient,
            boxShadow: AppTheme.glow(game.primary, opacity: 0.38, blur: 40, y: 20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.rXl),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: CustomPaint(painter: _RingsPainter(Colors.white)),
                ),
                Positioned(
                  left: -28,
                  bottom: -26,
                  child: Transform.rotate(
                    angle: -0.18,
                    child: Text(
                      game.emoji,
                      style: TextStyle(
                        fontSize: 130,
                        height: 1,
                        color: Colors.white.op(0.16),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.white.op(0.10),
                          Colors.black.op(0.28),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.op(0.20),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: Colors.white.op(0.28)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'الأكثر لعباً',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.op(0.95),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(game.emoji, style: const TextStyle(fontSize: 26)),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        game.name,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.op(0.86),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          _MiniStat(icon: Icons.group_rounded, label: game.playersLabel),
                          const SizedBox(width: 8),
                          _MiniStat(icon: Icons.timer_outlined, label: '${game.minutes} دقائق'),
                          const Spacer(),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: game.primary,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.op(0.18),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: Colors.white.op(0.9)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.op(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact card used in the games grid.
class GameTile extends StatelessWidget {
  const GameTile({super.key, required this.game, this.onTap, this.index = 0});

  final PartyGame game;
  final VoidCallback? onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      radius: AppTheme.rLg,
      padding: EdgeInsets.zero,
      tint: game.primary,
      tintOpacity: 0.16,
      glowColor: game.primary,
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -18,
            left: -18,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[game.primary.op(0.42), game.primary.op(0)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: game.gradient,
                        boxShadow: AppTheme.glow(game.primary, opacity: 0.4, blur: 16, y: 6),
                      ),
                      alignment: Alignment.center,
                      child: Text(game.emoji, style: const TextStyle(fontSize: 22)),
                    ),
                    const Spacer(),
                    Transform.rotate(
                      angle: -math.pi / 4,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.white.op(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  game.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  game.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    GlassPill(
                      label: game.playersLabel,
                      icon: Icons.group_rounded,
                      color: game.primary,
                      dense: true,
                    ),
                    const SizedBox(width: 6),
                    _HeatDots(heat: game.heat, color: game.primary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatDots extends StatelessWidget {
  const _HeatDots({required this.heat, required this.color});
  final int heat;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < heat ? color : Colors.white.op(0.14),
              ),
            ),
          ),
      ],
    );
  }
}
