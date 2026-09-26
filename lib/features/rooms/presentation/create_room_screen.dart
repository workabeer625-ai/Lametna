import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
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
    final List<GameDef> games = ref.watch(gamesProvider).valueOrNull ?? <GameDef>[];
    _gameKey ??= games.isNotEmpty ? games.first.key : null;
    final GameDef? game = _gameKey == null ? null : ref.watch(gameByKeyProvider(_gameKey!));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('create_room'))),
      body: games.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: _gameKey,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.t('games'),
                      prefixIcon: const Icon(Icons.sports_esports_outlined),
                    ),
                    items: games
                        .map((GameDef g) => DropdownMenuItem<String>(
                              value: g.key,
                              child: Text('${g.icon}  ${g.name(l10n.languageCode)}'),
                            ))
                        .toList(),
                    onChanged: (String? v) => setState(() {
                      _gameKey = v;
                      _maxPlayers = null;
                      _rounds = null;
                    }),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _title,
                    maxLength: 48,
                    decoration: InputDecoration(
                      labelText: '${l10n.t('room_title')} (${l10n.t('optional')})',
                      prefixIcon: const Icon(Icons.meeting_room_outlined),
                    ),
                  ),
                  SwitchListTile(
                    value: _isPublic,
                    onChanged: (bool v) => setState(() => _isPublic = v),
                    title: Text(_isPublic ? l10n.t('room_public') : l10n.t('room_private')),
                    subtitle: Text(_isPublic
                        ? l10n.t('public_rooms')
                        : l10n.t('room_password_hint')),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (!_isPublic)
                    TextField(
                      controller: _password,
                      decoration: InputDecoration(
                        labelText: l10n.t('room_password'),
                        helperText: l10n.t('room_password_hint'),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                  if (game != null) ...<Widget>[
                    const SizedBox(height: 18),
                    Text('${l10n.t('max_players')}: ${_maxPlayers ?? game.maxPlayers}',
                        style: Theme.of(context).textTheme.titleSmall),
                    Slider(
                      value: (_maxPlayers ?? game.maxPlayers).toDouble(),
                      min: game.minPlayers.toDouble(),
                      max: game.maxPlayers.toDouble(),
                      divisions: (game.maxPlayers - game.minPlayers).clamp(1, 24),
                      label: '${_maxPlayers ?? game.maxPlayers}',
                      onChanged: (double v) => setState(() => _maxPlayers = v.round()),
                    ),
                    if (game.key != 'mafia') ...<Widget>[
                      Text('${l10n.t('rounds')}: ${_rounds ?? game.defaultRounds}',
                          style: Theme.of(context).textTheme.titleSmall),
                      Slider(
                        value: (_rounds ?? game.defaultRounds).toDouble(),
                        min: 1,
                        max: 12,
                        divisions: 11,
                        label: '${_rounds ?? game.defaultRounds}',
                        onChanged: (double v) => setState(() => _rounds = v.round()),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.info_outline, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${game.minPlayers}–${game.maxPlayers} '
                                '${l10n.t('players')}  •  ${game.roundSeconds}'
                                '${l10n.t('seconds')} / ${l10n.t('round')}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: (_busy || game == null) ? null : () => _create(game),
                    icon: _busy
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add),
                    label: Text(l10n.t('create_room')),
                  ),
                ],
              ),
            ),
    );
  }
}
