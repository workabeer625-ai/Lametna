import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../models/player.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/avatar_orb.dart';
import '../widgets/fade_in.dart';
import '../widgets/glass.dart';
import '../widgets/gradient_button.dart';
import '../widgets/pressable.dart';
import 'results_screen.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({super.key});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final List<Player> players = state.players;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AuroraBackground(
        colors: <Color>[state.game.primary, AppColors.indigo, AppColors.blue],
        animate: !state.reduceMotion,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: <Widget>[
                    GlassIconButton(
                      icon: Icons.arrow_forward_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    GlassPill(
                      label: 'التصويت',
                      icon: Icons.how_to_vote_rounded,
                      color: state.game.primary,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: FadeInUp(
                  child: Column(
                    children: <Widget>[
                      Text('مين الجاسوس؟',
                          style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 4),
                      Text(
                        'اتفقوا على مشتبه به واحد واضغط عليه',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.86,
                  ),
                  itemCount: players.length,
                  itemBuilder: (BuildContext context, int i) {
                    final Player p = players[i];
                    final bool selected = p.id == _selectedId;
                    return FadeInUp(
                      delay: Duration(milliseconds: 40 * i),
                      child: Pressable(
                        onTap: () => setState(() => _selectedId = p.id),
                        child: AnimatedContainer(
                          duration: AppTheme.fast,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppTheme.rMd),
                            color: selected
                                ? p.color.op(0.22)
                                : Colors.white.op(0.055),
                            border: Border.all(
                              color: selected
                                  ? p.color.op(0.85)
                                  : Colors.white.op(0.10),
                              width: selected ? 1.8 : 1,
                            ),
                            boxShadow: selected
                                ? AppTheme.glow(p.color, opacity: 0.35, blur: 22, y: 8)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              AvatarOrb(player: p, size: 48, showGlow: selected),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? AppColors.ink
                                        : AppColors.inkSoft,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppColors.bg.op(0), AppColors.bg.op(0.92)],
          ),
        ),
        child: GradientButton(
          label: 'اكشف النتيجة',
          icon: Icons.visibility_rounded,
          colors: state.game.colors,
          onTap: _selectedId == null
              ? null
              : () {
                  final Player accused = players
                      .firstWhere((Player p) => p.id == _selectedId);
                  final bool caught = accused.isImposter;

                  if (caught) {
                    for (final Player p in players) {
                      if (!p.isImposter) state.addPoints(p.id, 2);
                    }
                  } else {
                    for (final Player p in players) {
                      if (p.isImposter) state.addPoints(p.id, 3);
                    }
                  }
                  state.completeRound();

                  Nav.replace(
                    context,
                    ResultsScreen(accused: accused, caught: caught),
                  );
                },
        ),
      ),
    );
  }
}
