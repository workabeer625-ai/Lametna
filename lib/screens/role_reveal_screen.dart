import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../models/player.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/avatar_orb.dart';
import '../widgets/fade_in.dart';
import '../widgets/flip_card.dart';
import '../widgets/glass.dart';
import '../widgets/gradient_button.dart';
import 'round_screen.dart';

/// Pass-the-phone secret role reveal.
class RoleRevealScreen extends StatefulWidget {
  const RoleRevealScreen({super.key});

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen> {
  int _index = 0;
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final List<Player> players = state.players;

    if (players.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('أضف لاعبين أولاً')),
      );
    }

    final Player player = players[_index.clamp(0, players.length - 1)];
    final bool isLast = _index >= players.length - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        colors: <Color>[
          _revealed && player.isImposter ? AppColors.coral : state.game.primary,
          AppColors.indigo,
          AppColors.violet,
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
                      label: 'لاعب ${_index + 1} من ${players.length}',
                      icon: Icons.style_rounded,
                      color: state.game.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 0; i < players.length; i++)
                    AnimatedContainer(
                      duration: AppTheme.fast,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: i == _index ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: i <= _index
                            ? state.game.primary
                            : Colors.white.op(0.16),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: FadeInUp(
                      key: ValueKey<int>(_index),
                      child: AspectRatio(
                        aspectRatio: 0.72,
                        child: FlipCard(
                          key: ValueKey<int>(_index),
                          onFlipped: (bool v) => setState(() => _revealed = v),
                          front: _CardFace(
                            child: _FrontFace(player: player),
                            colors: <Color>[
                              Colors.white.op(0.12),
                              Colors.white.op(0.04),
                            ],
                            borderColor: Colors.white.op(0.18),
                          ),
                          back: _CardFace(
                            colors: player.isImposter
                                ? <Color>[const Color(0xFFFB7185), const Color(0xFF881337)]
                                : <Color>[
                                    state.game.primary,
                                    state.game.colors.last,
                                  ],
                            borderColor: Colors.white.op(0.3),
                            glow: player.isImposter
                                ? AppColors.coral
                                : state.game.primary,
                            child: _BackFace(player: player),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                child: Column(
                  children: <Widget>[
                    AnimatedOpacity(
                      duration: AppTheme.fast,
                      opacity: _revealed ? 0.0 : 1.0,
                      child: Text(
                        'مرّر الجوال إلى ${player.name} ثم اضغط على البطاقة',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GradientButton(
                      label: isLast ? 'ابدأ الجولة' : 'التالي',
                      icon: isLast
                          ? Icons.timer_outlined
                          : Icons.arrow_back_rounded,
                      colors: state.game.colors,
                      onTap: _revealed
                          ? () {
                              if (isLast) {
                                Nav.replace(context, const RoundScreen());
                              } else {
                                setState(() {
                                  _index++;
                                  _revealed = false;
                                });
                              }
                            }
                          : null,
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

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.child,
    required this.colors,
    required this.borderColor,
    this.glow,
  });

  final Widget child;
  final List<Color> colors;
  final Color borderColor;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: colors,
        ),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: glow != null
            ? AppTheme.glow(glow!, opacity: 0.45, blur: 44, y: 18)
            : AppTheme.lift,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.white.op(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(24), child: child),
          ],
        ),
      ),
    );
  }
}

class _FrontFace extends StatelessWidget {
  const _FrontFace({required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        AvatarOrb(player: player, size: 92),
        const SizedBox(height: 22),
        Text(
          player.name,
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'بطاقتك جاهزة',
          style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: Colors.white.op(0.10),
            border: Border.all(color: Colors.white.op(0.18)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.touch_app_rounded, size: 16, color: AppColors.inkSoft),
              SizedBox(width: 7),
              Text(
                'اضغط للكشف',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackFace extends StatelessWidget {
  const _BackFace({required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) {
    final bool spy = player.isImposter;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(spy ? '🕵️' : '🎯', style: const TextStyle(fontSize: 54)),
        const SizedBox(height: 18),
        Text(
          spy ? 'أنت الجاسوس!' : 'الكلمة السرّية',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white.op(0.85),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          spy ? 'تصرّف بذكاء' : player.secret,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: Colors.black.op(0.22),
          ),
          child: Text(
            spy ? 'لا تكشف نفسك… خمّن الكلمة' : 'لا تقلها صراحة!',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.op(0.9),
            ),
          ),
        ),
      ],
    );
  }
}
