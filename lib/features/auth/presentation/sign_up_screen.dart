import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/design_kit.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _nickname = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _busy = false;
  bool _acceptedRules = false;

  @override
  void dispose() {
    _nickname.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_acceptedRules) {
      context.showSnack(context.l10n.t('rules'), error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authActionsProvider).signUp(
            _email.text,
            _password.text,
            _nickname.text.trim(),
            ref.read(settingsProvider).locale,
          );
      if (mounted) {
        context.showSnack(context.l10n.t('signup_success'));
        context.go('/profile-setup');
      }
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

    final TextStyle fieldStyle =
        TextStyle(color: ink, fontWeight: FontWeight.w600);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              ScreenHeader(
                title: l10n.t('sign_up'),
                onBack: context.canPop() ? () => context.pop() : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        FadeInUp(
                          child: GlassCard(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            child: Column(
                              children: <Widget>[
                                TextFormField(
                                  controller: _nickname,
                                  maxLength: AppConstants.maxNicknameLength,
                                  style: fieldStyle,
                                  decoration: InputDecoration(
                                    labelText: l10n.t('nickname'),
                                    hintText: l10n.t('nickname_hint'),
                                    prefixIcon: const Icon(Icons.badge_outlined),
                                    counterText: '',
                                  ),
                                  validator: (String? v) =>
                                      Validators.isNickname(v ?? '')
                                          ? null
                                          : l10n.t('nickname_too_short'),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  style: fieldStyle,
                                  decoration: InputDecoration(
                                    labelText: l10n.t('email'),
                                    prefixIcon: const Icon(Icons.alternate_email),
                                  ),
                                  validator: (String? v) => Validators.isEmail(v ?? '')
                                      ? null
                                      : l10n.t('invalid_email'),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _password,
                                  obscureText: true,
                                  style: fieldStyle,
                                  decoration: InputDecoration(
                                    labelText: l10n.t('password'),
                                    prefixIcon: const Icon(Icons.lock_outline),
                                  ),
                                  validator: (String? v) =>
                                      Validators.isStrongEnoughPassword(v ?? '')
                                          ? null
                                          : l10n.t('weak_password'),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _confirm,
                                  obscureText: true,
                                  style: fieldStyle,
                                  decoration: InputDecoration(
                                    labelText: l10n.t('confirm_password'),
                                    prefixIcon: const Icon(Icons.lock_reset),
                                  ),
                                  validator: (String? v) => v == _password.text
                                      ? null
                                      : l10n.t('password_mismatch'),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── الموافقة على القواعد ─────────────────
                        const SizedBox(height: 14),
                        FadeInUp(
                          delay: const Duration(milliseconds: 90),
                          child: Pressable(
                            onTap: () =>
                                setState(() => _acceptedRules = !_acceptedRules),
                            scale: 0.99,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: _acceptedRules
                                    ? AppColors.green.op(isDark ? 0.16 : 0.12)
                                    : (isDark
                                        ? AppColors.white.op(0.05)
                                        : AppColors.white.op(0.6)),
                                borderRadius: BorderRadius.circular(AppTheme.rSm),
                                border: Border.all(
                                  color: _acceptedRules
                                      ? AppColors.green.op(0.45)
                                      : (isDark ? AppColors.white : AppColors.coffee)
                                          .op(0.12),
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  AnimatedContainer(
                                    duration: AppTheme.fast,
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      gradient: _acceptedRules
                                          ? AppGradients.green
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                      border: _acceptedRules
                                          ? null
                                          : Border.all(
                                              color: muted.op(0.5), width: 1.6),
                                    ),
                                    child: _acceptedRules
                                        ? const Icon(Icons.check_rounded,
                                            size: 16, color: AppColors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => context.push('/rules'),
                                      child: Text(
                                        l10n.t('rules'),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.gold,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColors.gold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),
                        FadeInUp(
                          delay: const Duration(milliseconds: 140),
                          child: GradientButton(
                            label: l10n.t('sign_up'),
                            icon: Icons.person_add_alt_1_rounded,
                            height: 58,
                            loading: _busy,
                            colors: const <Color>[
                              AppColors.greenLight,
                              AppColors.greenDeep,
                            ],
                            onTap: _busy ? null : _submit,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeInUp(
                          delay: const Duration(milliseconds: 190),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                l10n.t('have_account'),
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: muted),
                              ),
                              TextButton(
                                onPressed: () => context.replace('/sign-in'),
                                child: Text(
                                  l10n.t('sign_in'),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: AppTheme.fontBody,
                                    color: AppColors.gold,
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
            ],
          ),
        ),
      ),
    );
  }
}
