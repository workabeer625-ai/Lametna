import 'package:flutter/material.dart';

import '../models/player.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_orb.dart';
import '../widgets/fade_in.dart';
import '../widgets/glass.dart';
import '../widgets/gradient_button.dart';
import '../widgets/section_header.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final List<Player> ranked = state.ranking;
    final List<Player> podium = ranked.take(3).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
        children: <Widget>[
          FadeInUp(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('لوحة الأبطال',
                    style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 4),
                Text(
                  'النقاط تتجمع من كل جولة تلعبونها',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── Stats ─────────────────────────────────────────────
          FadeInUp(
            delay: const Duration(milliseconds: 90),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    icon: Icons.replay_rounded,
                    value: '${state.roundsPlayed}',
                    label: 'جولة',
                    color: state.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.groups_2_rounded,
                    value: '${state.players.length}',
                    label: 'لاعب',
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.star_rounded,
                    value: '${ranked.isEmpty ? 0 : ranked.first.score}',
                    label: 'أعلى نقاط',
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // ── Podium ────────────────────────────────────────────
          if (podium.length >= 3)
            FadeInUp(
              delay: const Duration(milliseconds: 160),
              child: SizedBox(
                height: 208,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(child: _PodiumColumn(player: podium[1], place: 2, height: 108)),
                    const SizedBox(width: 10),
                    Expanded(child: _PodiumColumn(player: podium[0], place: 1, height: 148)),
                    const SizedBox(width: 10),
                    Expanded(child: _PodiumColumn(player: podium[2], place: 3, height: 84)),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 26),
          FadeInUp(
            delay: const Duration(milliseconds: 220),
            child: SectionHeader(
              title: 'الترتيب الكامل',
              subtitle: 'مرتّب حسب النقاط',
              accent: state.accent,
            ),
          ),
          const SizedBox(height: 14),

          for (int i = 0; i < ranked.length; i++)
            FadeInUp(
              delay: Duration(milliseconds: 260 + i * 45),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RankRow(rank: i + 1, player: ranked[i]),
              ),
            ),

          const SizedBox(height: 18),
          GhostButton(
            label: 'تصفير النقاط',
            icon: Icons.restart_alt_rounded,
            color: AppColors.coral,
            onTap: state.resetScores,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppTheme.rMd,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      tint: color,
      tintOpacity: 0.12,
      child: Column(
        children: <Widget>[
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.player,
    required this.place,
    required this.height,
  });

  final Player player;
  final int place;
  final double height;

  Color get _tone => switch (place) {
        1 => AppColors.amber,
        2 => const Color(0xFFCBD5E1),
        _ => const Color(0xFFD97706),
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        if (place == 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('👑', style: TextStyle(fontSize: 22, color: _tone)),
          ),
        AvatarOrb(player: player, size: place == 1 ? 60 : 48),
        const SizedBox(height: 8),
        Text(
          player.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[_tone.op(0.42), _tone.op(0.06)],
            ),
            border: Border.all(color: _tone.op(0.35)),
          ),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 12),
              Text(
                '$place',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _tone,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${player.score} نقطة',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.player});

  final int rank;
  final Player player;

  @override
  Widget build(BuildContext context) {
    final bool top = rank == 1;
    return GlassCard(
      radius: AppTheme.rMd,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      tint: top ? AppColors.amber : player.color,
      tintOpacity: top ? 0.14 : 0.08,
      child: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.op(0.07),
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: top ? AppColors.amber : AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AvatarOrb(player: player, size: 40, showGlow: false),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            '${player.score}',
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
