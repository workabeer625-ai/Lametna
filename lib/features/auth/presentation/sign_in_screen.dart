import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/design_kit.dart';
import '../../../providers/auth_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authActionsProvider).signIn(_email.text, _password.text);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        context.showSnack(ErrorMapper.map(e).localized(context.l10n.languageCode), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!Validators.isEmail(_email.text)) {
      context.showSnack(context.l10n.t('invalid_email'), error: true);
      return;
    }
    try {
      await ref.read(authActionsProvider).resetPassword(_email.text);
      if (mounted) context.showSnack(context.l10n.t('reset_sent'));
    } catch (e) {
      if (mounted) {
        context.showSnack(ErrorMapper.map(e).localized(context.l10n.languageCode), error: true);
      }
    }
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
          child: Column(
            children: <Widget>[
              ScreenHeader(
                title: l10n.t('sign_in'),
                onBack: context.canPop() ? () => context.pop() : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        FadeInUp(
                          child: const Center(child: BrandMark(size: 74)),
                        ),
                        const SizedBox(height: 26),
                        FadeInUp(
                          delay: const Duration(milliseconds: 80),
                          child: GlassCard(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                            child: Column(
                              children: <Widget>[
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const <String>[AutofillHints.email],
                                  style: TextStyle(
                                      color: ink, fontWeight: FontWeight.w600),
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
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  style: TextStyle(
                                      color: ink, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    labelText: l10n.t('password'),
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  validator: (String? v) =>
                                      (v ?? '').isEmpty ? l10n.t('weak_password') : null,
                                ),
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: TextButton(
                                    onPressed: _busy ? null : _resetPassword,
                                    child: Text(
                                      l10n.t('forgot_password'),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        FadeInUp(
                          delay: const Duration(milliseconds: 140),
                          child: GradientButton(
                            label: l10n.t('sign_in'),
                            icon: Icons.login_rounded,
                            height: 58,
                            loading: _busy,
                            onTap: _busy ? null : _submit,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          delay: const Duration(milliseconds: 190),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                l10n.t('no_account'),
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: muted),
                              ),
                              TextButton(
                                onPressed: () => context.replace('/sign-up'),
                                child: Text(
                                  l10n.t('sign_up'),
                                  style: TextStyle(
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
