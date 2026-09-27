import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/design_kit.dart';
import '../../../models/models.dart';
import '../../../providers/catalog_provider.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/settings_provider.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key, this.initialGameKey});
  final String? initialGameKey;

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String? _gameKey;
  bool _isPublic = true;
  int? _maxPlayers;
  int? _rounds;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _gameKey = widget.initialGameKey;
  }

  @override
  void dispose() {
    _title.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _create(GameDef game) async {
    setState(() => _busy = true);
    try {
      final Room room = await ref.read(supabaseServiceProvider).createRoom(
            gameKey: game.key,
            isPublic: _isPublic,
            password: _isPublic ? null : _password.text.trim(),
            title: _title.text.trim(),
            maxPlayers: _maxPlayers ?? game.maxPlayers,
            settings: <String, dynamic>{
              if (_rounds != null) 'rounds': _rounds,
            },
            locale: ref.read(settingsProvider).locale,
          );
      await ref.read(localPrefsProvider).setLastRoomCode(room.code);
      if (mounted) context.pushReplacement('/room/${room.id}');
    } catch (e) {
      if (mounted) {
        context.showSnack(ErrorMapper.map(e).localized(context.l10n.languageCode), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    final List<GameDef> games = ref.watch(gamesProvider).valueOrNull ?? <GameDef>[];
    _gameKey ??= games.isNotEmpty ? games.first.key : null;
    final GameDef? game = _gameKey == null ? null : ref.watch(gameByKeyProvider(_gameKey!));
    final Color accent =
        game == null ? AppColors.green : AppColors.forSeed(game.key);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              ScreenHeader(
                title: l10n.t('create_room'),
                subtitle: game?.name(l10n.languageCode),
                accent: accent,
                onBack: () => context.pop(),
              ),
              Expanded(
                child: games.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
                        children: <Widget>[
                          // ── اختيار اللعبة ────────────────────────
                          FadeInUp(
                            child: _Label(text: l10n.t('games'), color: muted),
                          ),
                          const SizedBox(height: 10),
                          FadeInUp(
                            delay: const Duration(milliseconds: 60),
                            child: SizedBox(
                              height: 108,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: games.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 10),
                                itemBuilder: (_, int i) {
                                  final GameDef g = games[i];
                                  return _GamePick(
                                    game: g,
                                    selected: g.key == _gameKey,
                                    locale: l10n.languageCode,
                                    onTap: () => setState(() {
                                      _gameKey = g.key;
                                      _maxPlayers = null;
                                      _rounds = null;
                                    }),
                                  );
                                },
                              ),
                            ),
                          ),

                          // ── اسم الغرفة ──────────────────────────
                          const SizedBox(height: 22),
                          FadeInUp(
                            delay: const Duration(milliseconds: 110),
                            child: TextField(
                              controller: _title,
                              maxLength: 48,
                              style: TextStyle(color: ink, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                labelText:
                                    '${l10n.t('room_title')} (${l10n.t('optional')})',
                                prefixIcon: const Icon(Icons.meeting_room_outlined),
                                counterText: '',
                              ),
                            ),
                          ),

                          // ── عامة / خاصة ─────────────────────────
                          const SizedBox(height: 16),
                          FadeInUp(
                            delay: const Duration(milliseconds: 160),
                            child: GlassCard(
                              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                              glowColor: _isPublic ? AppColors.green : AppColors.coffee,
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          gradient: AppGradients.from(
                                              _isPublic ? AppColors.green : AppColors.coffee),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _isPublic ? Icons.public_rounded : Icons.lock_rounded,
                                          color: AppColors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              _isPublic
                                                  ? l10n.t('room_public')
                                                  : l10n.t('room_private'),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                                color: ink,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _isPublic
                                                  ? l10n.t('public_rooms')
                                                  : l10n.t('room_password_hint'),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 11.5, color: muted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: _isPublic,
                                        onChanged: (bool v) => setState(() => _isPublic = v),
                                      ),
                                    ],
                                  ),
                                  AnimatedSize(
                                    duration: AppTheme.fast,
                                    curve: AppTheme.ease,
                                    child: _isPublic
                                        ? const SizedBox(width: double.infinity)
                                        : Padding(
                                            padding: const EdgeInsets.only(top: 12),
                                            child: TextField(
                                              controller: _password,
                                              style: TextStyle(
                                                  color: ink, fontWeight: FontWeight.w600),
                                              decoration: InputDecoration(
                                                labelText: l10n.t('room_password'),
                                                helperText: l10n.t('room_password_hint'),
                                                prefixIcon: const Icon(Icons.lock_outline),
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── الإعدادات ───────────────────────────
                          if (game != null) ...<Widget>[
                            const SizedBox(height: 18),
                            FadeInUp(
                              delay: const Duration(milliseconds: 210),
                              child: GlassCard(
                                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                                child: Column(
                                  children: <Widget>[
                                    _SliderRow(
                                      label: l10n.t('max_players'),
                                      value: (_maxPlayers ?? game.maxPlayers).toDouble(),
                                      min: game.minPlayers.toDouble(),
                                      max: game.maxPlayers.toDouble(),
                                      divisions:
                                          (game.maxPlayers - game.minPlayers).clamp(1, 24),
                                      accent: accent,
                                      onChanged: (double v) =>
                                          setState(() => _maxPlayers = v.round()),
                                    ),
                                    if (game.key != 'mafia')
                                      _SliderRow(
                                        label: l10n.t('rounds'),
                                        value: (_rounds ?? game.defaultRounds).toDouble(),
                                        min: 1,
                                        max: 12,
                                        divisions: 11,
                                        accent: AppColors.gold,
                                        onChanged: (double v) =>
                                            setState(() => _rounds = v.round()),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            FadeInUp(
                              delay: const Duration(milliseconds: 250),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  GlassPill(
                                    icon: Icons.groups_2_outlined,
                                    label: '${game.minPlayers}–${game.maxPlayers} '
                                        '${l10n.t('players')}',
                                    color: AppColors.green,
                                  ),
                                  GlassPill(
                                    icon: Icons.timer_outlined,
                                    label: '${game.roundSeconds}${l10n.t('seconds')} / '
                                        '${l10n.t('round')}',
                                    color: AppColors.gold,
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 26),
                          FadeInUp(
                            delay: const Duration(milliseconds: 300),
                            child: GradientButton(
                              label: l10n.t('create_room'),
                              icon: Icons.rocket_launch_rounded,
                              height: 58,
                              loading: _busy,
                              colors: <Color>[
                                AppColors.lighten(accent, 0.1),
                                AppColors.deepen(accent, 0.14),
                              ],
                              onTap: (_busy || game == null) ? null : () => _create(game),
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

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: color,
        ),
      );
}

/// بطاقة اختيار لعبة (شريط أفقي).
class _GamePick extends StatelessWidget {
  const _GamePick({
    required this.game,
    required this.selected,
    required this.locale,
    required this.onTap,
  });

  final GameDef game;
  final bool selected;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color seed = AppColors.forSeed(game.key);
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.fast,
        curve: AppTheme.ease,
        width: 104,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.from(seed) : null,
          color: selected
              ? null
              : (isDark ? AppColors.white.op(0.05) : AppColors.white.op(0.6)),
          borderRadius: BorderRadius.circular(AppTheme.rMd),
          border: Border.all(
            color: selected ? seed.op(0.0) : (isDark ? AppColors.white : AppColors.coffee).op(0.12),
          ),
          boxShadow: selected ? AppTheme.glow(seed, opacity: 0.4) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(game.icon, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 8),
            Text(
              game.name(locale),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.white : ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.accent,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Color accent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: ink),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppGradients.from(accent),
                borderRadius: BorderRadius.circular(100),
                boxShadow: AppTheme.glow(accent, opacity: 0.32, blur: 14),
              ),
              child: Text(
                '${value.round()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            inactiveTrackColor: accent.op(0.16),
            thumbColor: accent,
            overlayColor: accent.op(0.14),
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
