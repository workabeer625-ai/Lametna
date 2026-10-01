import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/design_kit.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../legal/presentation/legal_links.dart';
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
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              children: <Widget>[
                const Spacer(),
                const FadeInUp(
                  offset: 0,
                  scaleFrom: 0.8,
                  child: LametnaLogo(size: 116),
                ),
                const SizedBox(height: 26),
                FadeInUp(
                  delay: const Duration(milliseconds: 120),
                  child: Text(
                    l10n.t('welcome_title'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall,
                  ),
                ),
                const SizedBox(height: 8),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: GlassPill(
                    label: l10n.t('slogan'),
                    icon: Icons.local_cafe_rounded,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  delay: const Duration(milliseconds: 280),
                  child: Text(
                    l10n.t('welcome_body'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const Spacer(),
                FadeInUp(
                  delay: const Duration(milliseconds: 360),
                  child: GlassCard(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                    child: Column(
                      children: <Widget>[
                        GradientButton(
                          label: l10n.t('sign_in'),
                          icon: Icons.login_rounded,
                          onTap: _busy ? null : () => context.push('/sign-in'),
                        ),
                        const SizedBox(height: 10),
                        GhostButton(
                          label: l10n.t('sign_up'),
                          icon: Icons.person_add_alt_1_rounded,
                          onTap: _busy ? null : () => context.push('/sign-up'),
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: _busy ? null : _guest,
                          icon: _busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.person_outline, size: 19),
                          label: Text(l10n.t('guest_mode')),
                        ),
                        Text(
                          l10n.t('guest_note'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        Divider(
                          height: 1,
                          color: (theme.brightness == Brightness.dark
                                  ? AppColors.white
                                  : AppColors.coffee)
                              .op(0.10),
                        ),
                        const SizedBox(height: 12),
                        // الوثائق القانونية متاحة للقراءة قبل أي تسجيل.
                        const LegalLinksRow(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
