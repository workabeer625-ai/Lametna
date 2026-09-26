import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/validators.dart';
import '../../../models/models.dart';
import '../../../providers/core_providers.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key, this.initialCode});
  final String? initialCode;

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final TextEditingController _code = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  bool _needsPassword = false;

  @override
  void initState() {
    super.initState();
    _code.text = widget.initialCode ??
        ref.read(localPrefsProvider).lastRoomCode ??
        '';
  }

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _join({bool asSpectator = false}) async {
    final AppLocalizations l10n = context.l10n;
    final String code = Validators.normalizeRoomCode(_code.text);
    if (!Validators.isRoomCode(code)) {
      context.showSnack(l10n.t('code_hint'), error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final Room room = await ref.read(supabaseServiceProvider).joinRoom(
            code: code,
            password: _password.text.isEmpty ? null : _password.text,
            asSpectator: asSpectator,
          );
      await ref.read(localPrefsProvider).setLastRoomCode(room.code);
      if (mounted) context.pushReplacement('/room/${room.id}');
    } catch (e) {
      final AppException mapped = ErrorMapper.map(e);
      if (mapped.code == 'WRONG_PASSWORD') {
        setState(() => _needsPassword = true);
      }
      if (mapped.code == 'GAME_IN_PROGRESS' && !asSpectator) {
        if (mounted && await _askSpectate()) {
          await _join(asSpectator: true);
          return;
        }
      }
      if (mounted) context.showSnack(mapped.localized(l10n.languageCode), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _askSpectate() async {
    final AppLocalizations l10n = context.l10n;
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: Text(l10n.t('join_as_spectator')),
            content: Text(l10n.t('game_in_progress_hint')),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('cancel'))),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.t('join'))),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('join_by_code'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            const SizedBox(height: 8),
            Icon(Icons.vpn_key_outlined,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: l10n.t('enter_code'),
                hintText: l10n.t('code_hint'),
                counterText: '',
              ),
              onChanged: (String v) {
                final String norm = Validators.normalizeRoomCode(v);
                if (norm != v) {
                  _code.value = TextEditingValue(
                    text: norm,
                    selection: TextSelection.collapsed(offset: norm.length),
                  );
                }
              },
            ),
            if (_needsPassword) ...<Widget>[
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.t('room_password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : () => _join(),
              child: _busy
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.t('join')),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _busy ? null : () => _join(asSpectator: true),
              child: Text(l10n.t('join_as_spectator')),
            ),
          ],
        ),
      ),
    );
  }
}
