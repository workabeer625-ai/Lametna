import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nav.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/avatar_orb.dart';
import '../widgets/fade_in.dart';
import '../widgets/glass.dart';
import '../widgets/gradient_button.dart';
import '../widgets/timer_ring.dart';
import 'voting_screen.dart';

/// The discussion round: a big glowing countdown.
class RoundScreen extends StatefulWidget {
  const RoundScreen({super.key});

  @override
  State<RoundScreen> createState() => _RoundScreenState();
}

class _RoundScreenState extends State<RoundScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late int _total;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _total = 60 * AppScope.read(context).roundMinutes;
    _c = AnimationController(
      vsync: this,
      duration: Duration(seconds: _total),
    )..addStatusListener((AnimationStatus s) {
        if (s == AnimationStatus.completed && mounted) {
          HapticFeedback.heavyImpact();
          setState(() => _finished = true);
        }
      });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _fmt(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        colors: <Color>[
          _finished ? AppColors.coral : state.game.primary,
          AppColors.indigo,
          AppColors.magenta,
        ],
        animate: !state.reduceMotion,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: <Widget>[
                    GlassIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    GlassPill(
                      label: state.game.name,
                      icon: state.game.icon,
                      color: state.game.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              FadeInUp(
                child: Text(
                  _finished ? 'انتهى الوقت!' : 'وقت النقاش',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _finished ? 'حان وقت التصويت 👇' : 'اسألوا… وراقبوا ردود الفعل',
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (BuildContext context, Widget? _) {
                      final double remaining = (1 - _c.value) * _total;
                      final bool danger = remaining <= 15;
                      final Color color = _finished
                          ? AppColors.coral
                          : (danger ? AppColors.amber : state.game.primary);

                      return TimerRing(
                        progress: 1 - _c.value,
                        color: color,
                        size: 268,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              _fmt(remaining.ceil().clamp(0, _total)),
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 58,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                                height: 1.1,
                                shadows: <Shadow>[
                                  Shadow(color: color.op(0.55), blurRadius: 26),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'دقيقة : ثانية',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Players reminder strip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.players.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (BuildContext context, int i) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          AvatarOrb(player: state.players[i], size: 40),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 52,
                            child: Text(
                              state.players[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  children: <Widget>[
                    if (!_finished) ...<Widget>[
                      Expanded(
                        child: GhostButton(
                          label: _c.isAnimating ? 'إيقاف' : 'متابعة',
                          icon: _c.isAnimating
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          onTap: () {
                            setState(() {
                              if (_c.isAnimating) {
                                _c.stop();
                              } else {
                                _c.forward();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: _finished ? 1 : 1,
                      child: GradientButton(
                        label: _finished ? 'التصويت' : 'تخطّي',
                        icon: Icons.how_to_vote_rounded,
                        colors: state.game.colors,
                        onTap: () => Nav.replace(context, const VotingScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
