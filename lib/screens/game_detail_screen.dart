import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../models/party_game.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/fade_in.dart';
import '../widgets/glass.dart';
import '../widgets/gradient_button.dart';
import 'players_screen.dart';

class GameDetailScreen extends StatelessWidget {
  const GameDetailScreen({super.key, required this.game});

  final PartyGame game;

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        colors: <Color>[game.primary, game.colors.last, AppColors.indigo],
        animate: !state.reduceMotion,
        child: Stack(
          children: <Widget>[
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: <Widget>[
                  // ── Header ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Row(
                        children: <Widget>[
                          GlassIconButton(
                            icon: Icons.arrow_forward_rounded,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          GlassIconButton(
                            icon: Icons.favorite_border_rounded,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FadeInUp(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Center(
                              child: Container(
                                width: 104,
                                height: 104,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(34),
                                  gradient: game.gradient,
                                  boxShadow: AppTheme.glow(game.primary,
                                      opacity: 0.5, blur: 38, y: 16),
                                ),
                                alignment: Alignment.center,
                                child: Text(game.emoji,
                                    style: const TextStyle(fontSize: 50)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Text(
                                game.name,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.displayMedium,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                game.tagline,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                GlassPill(
                                  label: game.playersLabel,
                                  icon: Icons.group_rounded,
                                  color: game.primary,
                                ),
                                const SizedBox(width: 8),
                                GlassPill(
                                  label: '${game.minutes} دقائق',
                                  icon: Icons.timer_outlined,
                                  color: AppColors.cyan,
                                ),
                                const SizedBox(width: 8),
                                GlassPill(
                                  label: game.heatLabel,
                                  icon: Icons.local_fire_department_rounded,
                                  color: AppColors.amber,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── About ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                      child: FadeInUp(
                        delay: const Duration(milliseconds: 120),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Icon(Icons.info_outline_rounded,
                                      size: 18, color: game.primary),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'عن اللعبة',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                game.description,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Rules ─────────────────────────────────────
                  if (game.rules.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: FadeInUp(
                          delay: const Duration(milliseconds: 180),
                          child: GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Icon(Icons.checklist_rounded,
                                        size: 18, color: game.primary),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'القوانين',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                for (int i = 0; i < game.rules.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Container(
                                          width: 22,
                                          height: 22,
                                          margin: const EdgeInsets.only(top: 2),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: game.primary.op(0.16),
                                            border: Border.all(
                                                color: game.primary.op(0.35)),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${i + 1}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: game.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            game.rules[i],
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              height: 1.6,
                                              color: AppColors.inkSoft,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── Round setup ───────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: FadeInUp(
                        delay: const Duration(milliseconds: 240),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Icon(Icons.tune_rounded,
                                      size: 18, color: game.primary),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'إعدادات الجولة',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _StepperRow(
                                label: 'مدة الجولة',
                                value: '${state.roundMinutes} دقيقة',
                                color: game.primary,
                                onMinus: () =>
                                    state.setRoundMinutes(state.roundMinutes - 1),
                                onPlus: () =>
                                    state.setRoundMinutes(state.roundMinutes + 1),
                              ),
                              if (game.mode == GameMode.imposter)
                                _StepperRow(
                                  label: 'عدد الجواسيس',
                                  value: '${state.imposterCount}',
                                  color: game.primary,
                                  onMinus: () =>
                                      state.setImposterCount(state.imposterCount - 1),
                                  onPlus: () =>
                                      state.setImposterCount(state.imposterCount + 1),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 130)),
                ],
              ),
            ),

            // ── Sticky CTA ──────────────────────────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[AppColors.bg.op(0), AppColors.bg.op(0.92)],
                  ),
                ),
                child: GradientButton(
                  label: 'جهّز اللاعبين',
                  icon: Icons.play_arrow_rounded,
                  colors: game.colors,
                  onTap: () {
                    state.game = game;
                    Nav.push(context, PlayersScreen(game: game));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.color,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          _RoundIcon(icon: Icons.remove_rounded, color: color, onTap: onMinus),
          SizedBox(
            width: 78,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          _RoundIcon(icon: Icons.add_rounded, color: color, onTap: onPlus),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.op(0.16),
          border: Border.all(color: color.op(0.32)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
