import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/validators.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('sign_up'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _nickname,
                  maxLength: AppConstants.maxNicknameLength,
                  decoration: InputDecoration(
                    labelText: l10n.t('nickname'),
                    hintText: l10n.t('nickname_hint'),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (String? v) =>
                      Validators.isNickname(v ?? '') ? null : l10n.t('nickname_too_short'),
                ),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.t('email'),
                    prefixIcon: const Icon(Icons.alternate_email),
                  ),
                  validator: (String? v) =>
                      Validators.isEmail(v ?? '') ? null : l10n.t('invalid_email'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.t('password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (String? v) => Validators.isStrongEnoughPassword(v ?? '')
                      ? null
                      : l10n.t('weak_password'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.t('confirm_password'),
                    prefixIcon: const Icon(Icons.lock_reset),
                  ),
                  validator: (String? v) =>
                      v == _password.text ? null : l10n.t('password_mismatch'),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _acceptedRules,
                  onChanged: (bool? v) => setState(() => _acceptedRules = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: GestureDetector(
                    onTap: () => context.push('/rules'),
                    child: Text(
                      l10n.t('rules'),
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.t('sign_up')),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(l10n.t('have_account')),
                    TextButton(
                      onPressed: () => context.replace('/sign-in'),
                      child: Text(l10n.t('sign_in')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
