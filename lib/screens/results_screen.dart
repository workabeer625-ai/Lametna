import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../models/player.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/avatar_orb.dart';
import '../widgets/confetti.dart';
import '../widgets/fade_in.dart';
import '../widgets/glass.dart';
import '../widgets/gradient_button.dart';
import 'role_reveal_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.accused, required this.caught});

  final Player accused;
  final bool caught;

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final List<Player> spies = state.imposters;
    final Color tone = caught ? AppColors.mint : AppColors.coral;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AuroraBackground(
        colors: <Color>[tone, AppColors.indigo, state.game.primary],
        animate: !state.reduceMotion,
        child: Stack(
          children: <Widget>[
            SafeArea(
              child: ListView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 180),
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerRight,
                    child: GlassIconButton(
                      icon: Icons.home_rounded,
                      onTap: () => Navigator.of(context)
                          .popUntil((Route<dynamic> r) => r.isFirst),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeInUp(
                    child: Center(
                      child: Column(
                        children: <Widget>[
                          Text(
                            caught ? '🎉' : '🕶️',
                            style: const TextStyle(fontSize: 62),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            caught ? 'أمسكتم الجاسوس!' : 'الجاسوس فاز!',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            caught
                                ? 'تصويت موفق… المجموعة تأخذ النقاط'
                                : 'شكّيتم في الشخص الغلط',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Verdict ─────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 140),
                    child: GlassCard(
                      tint: tone,
                      tintOpacity: 0.14,
                      glowColor: tone,
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              AvatarOrb(player: accused, size: 52),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      'المتهم: ${accused.name}',
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      caught ? 'كان فعلاً الجاسوس ✅' : 'كان بريئاً ❌',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: tone,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Divider(color: Colors.white.op(0.08)),
                          ),
                          Row(
                            children: <Widget>[
                              const Text(
                                'الكلمة السرّية',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                state.secretWord,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  'الجواسيس',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Flexible(
                                child: Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: <Widget>[
                                    for (final Player s in spies)
                                      GlassPill(
                                        label: '${s.emoji} ${s.name}',
                                        color: AppColors.coral,
                                        dense: true,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),
                  FadeInUp(
                    delay: const Duration(milliseconds: 220),
                    child: Row(
                      children: <Widget>[
                        const Text(
                          'النقاط بعد الجولة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const Spacer(),
                        GlassPill(
                          label: 'جولة ${state.roundsPlayed}',
                          icon: Icons.replay_rounded,
                          color: state.game.primary,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (int i = 0; i < state.ranking.length; i++)
                    FadeInUp(
                      delay: Duration(milliseconds: 260 + i * 50),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _ScoreRow(
                          rank: i + 1,
                          player: state.ranking[i],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (caught) const Positioned.fill(child: ConfettiOverlay()),

            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[AppColors.bg.op(0), AppColors.bg.op(0.94)],
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: GhostButton(
                        label: 'الرئيسية',
                        icon: Icons.home_rounded,
                        onTap: () => Navigator.of(context)
                            .popUntil((Route<dynamic> r) => r.isFirst),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GradientButton(
                        label: 'جولة جديدة',
                        icon: Icons.refresh_rounded,
                        colors: state.game.colors,
                        onTap: () {
                          state.dealRoles();
                          Nav.replace(context, const RoleRevealScreen());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.rank, required this.player});

  final int rank;
  final Player player;

  @override
  Widget build(BuildContext context) {
    final bool top = rank == 1;
    return GlassCard(
      radius: AppTheme.rMd,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      tint: top ? AppColors.amber : Colors.white,
      tintOpacity: top ? 0.14 : 0.07,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 26,
            child: Text(
              '$rank',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: top ? AppColors.amber : AppColors.inkMuted,
              ),
            ),
          ),
          AvatarOrb(player: player, size: 38, showGlow: false),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            '${player.score}',
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'نقطة',
            style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
