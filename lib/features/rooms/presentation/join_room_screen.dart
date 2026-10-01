import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/design_kit.dart';
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              ScreenHeader(
                title: l10n.t('join_by_code'),
                onBack: () => context.pop(),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 36),
                  children: <Widget>[
                    // ── أيقونة المفتاح المتوهّجة ─────────────────
                    FadeInUp(
                      child: Center(
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            gradient: AppGradients.gold,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: AppTheme.glow(AppColors.gold,
                                opacity: 0.45, blur: 34, y: 14),
                          ),
                          child: const Icon(Icons.vpn_key_rounded,
                              size: 42, color: AppColors.espresso),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeInUp(
                      delay: const Duration(milliseconds: 70),
                      child: Text(
                        l10n.t('code_hint'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: muted,
                        ),
                      ),
                    ),

                    // ── حقل الرمز ───────────────────────────────
                    const SizedBox(height: 22),
                    FadeInUp(
                      delay: const Duration(milliseconds: 120),
                      child: GlassCard(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                        glowColor: AppColors.gold,
                        child: TextField(
                          controller: _code,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 12,
                            color: ink,
                          ),
                          decoration: InputDecoration(
                            hintText: 'ABC123',
                            hintStyle: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 12,
                              color: muted.op(0.35),
                            ),
                            counterText: '',
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          onChanged: (String v) {
                            final String norm = Validators.normalizeRoomCode(v);
                            if (norm != v) {
                              _code.value = TextEditingValue(
                                text: norm,
                                selection: TextSelection.collapsed(offset: norm.length),
                              );
                            }
                            setState(() {});
                          },
                        ),
                      ),
                    ),

                    // ── كلمة السر عند الحاجة ────────────────────
                    if (_needsPassword) ...<Widget>[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        style: TextStyle(color: ink, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: l10n.t('room_password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                      ),
                    ],

                    const SizedBox(height: 26),
                    FadeInUp(
                      delay: const Duration(milliseconds: 170),
                      child: GradientButton(
                        label: l10n.t('join'),
                        icon: Icons.login_rounded,
                        height: 58,
                        loading: _busy,
                        onTap: _busy ? null : () => _join(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInUp(
                      delay: const Duration(milliseconds: 210),
                      child: GhostButton(
                        label: l10n.t('join_as_spectator'),
                        icon: Icons.visibility_outlined,
                        onTap: _busy ? null : () => _join(asSpectator: true),
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
