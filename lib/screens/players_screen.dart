import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nav.dart';
import '../models/party_game.dart';
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
import 'deck_screen.dart';
import 'role_reveal_screen.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key, this.game});

  final PartyGame? game;

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final TextEditingController _field = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add(AppState state) {
    final String name = _field.text.trim();
    if (name.isEmpty) return;
    state.addPlayer(name);
    _field.clear();
    HapticFeedback.lightImpact();
  }

  void _start(AppState state) {
    final PartyGame game = widget.game!;
    if (state.players.length < game.minPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تحتاجون ${game.minPlayers} لاعبين على الأقل')),
      );
      return;
    }
    state.game = game;
    if (game.mode == GameMode.imposter) {
      state.dealRoles();
      Nav.push(context, const RoleRevealScreen());
    } else {
      Nav.push(context, DeckScreen(game: game));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final PartyGame? game = widget.game;
    final Color accent = game?.primary ?? state.accent;
    final List<Player> players = state.players;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: AuroraBackground(
        colors: <Color>[accent, AppColors.indigo, AppColors.magenta],
        animate: !state.reduceMotion,
        child: Stack(
          children: <Widget>[
            SafeArea(
              bottom: false,
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
                          label: '${players.length}/16',
                          icon: Icons.groups_2_rounded,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: FadeInUp(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('مين في اللمة؟',
                              style: Theme.of(context).textTheme.displayMedium),
                          const SizedBox(height: 4),
                          Text(
                            game == null
                                ? 'أضف أصدقاءك وخلّهم جاهزين لأي لعبة'
                                : 'لعبة ${game.name} • ${game.playersLabel}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Add field ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                    child: FadeInUp(
                      delay: const Duration(milliseconds: 90),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: Colors.white.op(0.06),
                                    border: Border.all(color: Colors.white.op(0.12)),
                                  ),
                                  child: TextField(
                                    controller: _field,
                                    focusNode: _focus,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _add(state),
                                    cursorColor: accent,
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'اسم اللاعب…',
                                      hintStyle: TextStyle(
                                        color: AppColors.inkMuted,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      prefixIcon: Icon(Icons.person_outline_rounded,
                                          color: AppColors.inkMuted, size: 20),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Pressable(
                            onTap: () => _add(state),
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: AppGradients.from(accent),
                                boxShadow: AppTheme.glow(accent,
                                    opacity: 0.45, blur: 20, y: 8),
                              ),
                              child: const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 26),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── List ──────────────────────────────────────
                  Expanded(
                    child: players.isEmpty
                        ? Center(
                            child: Text(
                              'ما في لاعبين بعد 👀',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics()),
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 150),
                            itemCount: players.length,
                            itemBuilder: (BuildContext context, int i) {
                              final Player p = players[i];
                              return FadeInUp(
                                key: ValueKey<String>(p.id),
                                delay: Duration(milliseconds: 40 * i),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _PlayerRow(
                                    player: p,
                                    index: i,
                                    onAvatar: () => state.cycleAvatar(p),
                                    onRemove: () => state.removePlayer(p.id),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            if (game != null)
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
                    label: 'ابدأ اللعبة',
                    icon: Icons.bolt_rounded,
                    colors: game.colors,
                    onTap: () => _start(state),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    super.key,
    required this.player,
    required this.index,
    required this.onAvatar,
    required this.onRemove,
  });

  final Player player;
  final int index;
  final VoidCallback onAvatar;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppTheme.rMd,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      tint: player.color,
      tintOpacity: 0.10,
      child: Row(
        children: <Widget>[
          Pressable(onTap: onAvatar, child: AvatarOrb(player: player, size: 46)),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  player.score > 0 ? '${player.score} نقطة' : 'لاعب رقم ${index + 1}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Pressable(
            onTap: onRemove,
            scale: 0.85,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.coral.op(0.12),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 17, color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
  }
}
