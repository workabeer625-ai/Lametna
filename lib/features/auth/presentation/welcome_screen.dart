import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';
import 'splash_screen.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _busy = false;

  Future<void> _guest() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(authActionsProvider)
          .signInAsGuest(null, ref.read(settingsProvider).locale);
      if (mounted) context.go('/profile-setup');
    } catch (e) {
      if (mounted) context.showSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              const Spacer(),
              const LametnaLogo(size: 100),
              const SizedBox(height: 24),
              Text(l10n.t('welcome_title'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(l10n.t('slogan'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.secondary)),
              const SizedBox(height: 20),
              Text(l10n.t('welcome_body'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : () => context.push('/sign-in'),
                child: Text(l10n.t('sign_in')),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _busy ? null : () => context.push('/sign-up'),
                child: Text(l10n.t('sign_up')),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _busy ? null : _guest,
                icon: _busy
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.person_outline),
                label: Text(l10n.t('guest_mode')),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(l10n.t('guest_note'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
