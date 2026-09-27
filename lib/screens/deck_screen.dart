import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/party_game.dart';
import '../models/player.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/avatar_orb.dart';
import '../widgets/glass.dart';
import '../widgets/gradient_button.dart';
import '../widgets/pressable.dart';

/// Swipeable deck of prompt cards (truth / dare / would-you-rather…).
class DeckScreen extends StatefulWidget {
  const DeckScreen({super.key, required this.game});

  final PartyGame game;

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen>
    with SingleTickerProviderStateMixin {
  late List<String> _cards;
  int _index = 0;
  Offset _drag = Offset.zero;
  bool _flinging = false;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  Tween<Offset> _tween = Tween<Offset>(begin: Offset.zero, end: Offset.zero);

  final math.Random _rng = math.Random();
  Player? _turn;

  @override
  void initState() {
    super.initState();
    _cards = <String>[...widget.game.prompts]..shuffle(_rng);

    _anim.addListener(() {
      setState(() {
        _drag = _tween.transform(Curves.easeOut.transform(_anim.value));
      });
    });
    _anim.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed && _flinging) {
        setState(() {
          _flinging = false;
          _index++;
          _drag = Offset.zero;
          _pickTurn();
        });
        _anim.value = 0;
      }
    });
    _pickTurn();
  }

  void _pickTurn() {
    final List<Player> players = AppScope.read(context).players;
    if (players.isEmpty) return;
    _turn = players[_rng.nextInt(players.length)];
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _next({bool toLeft = true}) {
    if (_anim.isAnimating || _index >= _cards.length) return;
    HapticFeedback.mediumImpact();
    _flinging = true;
    _tween = Tween<Offset>(
      begin: _drag,
      end: Offset(toLeft ? -520 : 520, _drag.dy - 60),
    );
    _anim.forward(from: 0);
  }

  void _settle() {
    _flinging = false;
    _tween = Tween<Offset>(begin: _drag, end: Offset.zero);
    _anim.forward(from: 0);
  }

  void _restart() {
    setState(() {
      _cards = <String>[...widget.game.prompts]..shuffle(_rng);
      _index = 0;
      _drag = Offset.zero;
      _pickTurn();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final PartyGame game = widget.game;
    final bool done = _index >= _cards.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AuroraBackground(
        colors: <Color>[game.primary, game.colors.last, AppColors.indigo],
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
                      label: done
                          ? 'خلصت البطاقات'
                          : '${_index + 1} / ${_cards.length}',
                      icon: game.icon,
                      color: game.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(game.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 2),
              Text(game.tagline, style: Theme.of(context).textTheme.bodyMedium),

              // ── Whose turn ────────────────────────────────────
              if (_turn != null && !done)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: AnimatedSwitcher(
                    duration: AppTheme.medium,
                    child: Container(
                      key: ValueKey<String>('${_turn!.id}$_index'),
                      padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.white.op(0.07),
                        border: Border.all(color: Colors.white.op(0.12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          AvatarOrb(player: _turn!, size: 30, showGlow: false),
                          const SizedBox(width: 9),
                          Text(
                            'الدور على ${_turn!.name}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: Center(
                  child: done
                      ? _DeckFinished(game: game, onRestart: _restart)
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 26),
                          child: AspectRatio(
                            aspectRatio: 0.78,
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                for (int depth = 2; depth >= 1; depth--)
                                  if (_index + depth < _cards.length)
                                    Transform.translate(
                                      offset: Offset(0, depth * 14.0),
                                      child: Transform.scale(
                                        scale: 1 - depth * 0.05,
                                        child: Opacity(
                                          opacity: 0.5 - depth * 0.14,
                                          child: _PromptCard(
                                            text: _cards[_index + depth],
                                            game: game,
                                          ),
                                        ),
                                      ),
                                    ),
                                GestureDetector(
                                  onPanUpdate: (DragUpdateDetails d) {
                                    if (_anim.isAnimating) return;
                                    setState(() => _drag += d.delta);
                                  },
                                  onPanEnd: (DragEndDetails d) {
                                    if (_drag.dx.abs() > 95) {
                                      _next(toLeft: _drag.dx < 0);
                                    } else {
                                      _settle();
                                    }
                                  },
                                  onTap: () => _next(),
                                  child: Transform.translate(
                                    offset: _drag,
                                    child: Transform.rotate(
                                      angle: _drag.dx / 1600,
                                      child: _PromptCard(
                                        text: _cards[_index],
                                        game: game,
                                        elevated: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: GhostButton(
                        label: 'خلط',
                        icon: Icons.shuffle_rounded,
                        onTap: _restart,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GradientButton(
                        label: done ? 'من البداية' : 'البطاقة التالية',
                        icon: Icons.arrow_back_rounded,
                        colors: game.colors,
                        onTap: done ? _restart : () => _next(),
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

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.text,
    required this.game,
    this.elevated = false,
  });

  final String text;
  final PartyGame game;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: game.gradient,
        border: Border.all(color: Colors.white.op(0.22), width: 1.4),
        boxShadow: elevated
            ? AppTheme.glow(game.primary, opacity: 0.45, blur: 46, y: 20)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -30,
              right: -20,
              child: Text(
                game.emoji,
                style: TextStyle(fontSize: 150, color: Colors.white.op(0.14)),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.white.op(0.12),
                      Colors.black.op(0.26),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(game.emoji, style: const TextStyle(fontSize: 26)),
                      const Spacer(),
                      Icon(Icons.swipe_rounded,
                          size: 20, color: Colors.white.op(0.7)),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    text,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: Colors.black.op(0.2),
                        ),
                        child: Text(
                          'اسحب أو اضغط للتالي',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.op(0.9),
                          ),
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
    );
  }
}

class _DeckFinished extends StatelessWidget {
  const _DeckFinished({required this.game, required this.onRestart});

  final PartyGame game;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: GlassCard(
        tint: game.primary,
        tintOpacity: 0.14,
        glowColor: game.primary,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('🎊', style: TextStyle(fontSize: 54)),
            const SizedBox(height: 14),
            Text('خلّصتوا كل البطاقات!',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'تبون جولة ثانية بترتيب جديد؟',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Pressable(
              onTap: onRestart,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: game.gradient,
                ),
                child: const Text(
                  'أعد الخلط',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
