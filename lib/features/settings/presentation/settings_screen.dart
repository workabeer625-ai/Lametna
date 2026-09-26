import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final SettingsState settings = ref.watch(settingsProvider);
    final SettingsController controller = ref.read(settingsProvider.notifier);
    final Profile? profile = ref.watch(profileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('settings'))),
      body: ListView(
        children: <Widget>[
          _Header(title: l10n.t('appearance')),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.t('language')),
            subtitle: Text(settings.isArabic ? l10n.t('arabic') : l10n.t('english')),
            trailing: SegmentedButton<String>(
              segments: <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'ar', label: Text(l10n.t('arabic'))),
                ButtonSegment<String>(value: 'en', label: Text(l10n.t('english'))),
              ],
              selected: <String>{settings.locale},
              showSelectedIcon: false,
              onSelectionChanged: (Set<String> v) => controller.setLocale(v.first),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: Text(l10n.t('dark_mode')),
            subtitle: Text(switch (settings.themeMode) {
              ThemeMode.light => l10n.t('theme_light'),
              ThemeMode.dark => l10n.t('theme_dark'),
              ThemeMode.system => l10n.t('theme_system'),
            }),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (BuildContext ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ThemeMode.values
                      .map((ThemeMode mode) => RadioListTile<ThemeMode>(
                            value: mode,
                            groupValue: settings.themeMode,
                            title: Text(switch (mode) {
                              ThemeMode.light => l10n.t('theme_light'),
                              ThemeMode.dark => l10n.t('theme_dark'),
                              ThemeMode.system => l10n.t('theme_system'),
                            }),
                            onChanged: (ThemeMode? v) {
                              if (v != null) controller.setThemeMode(v);
                              Navigator.pop(ctx);
                            },
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(l10n.t('notifications')),
            value: settings.notificationsEnabled,
            onChanged: controller.setNotifications,
          ),

          _Header(title: l10n.t('privacy')),
          if (profile != null)
            SwitchListTile(
              secondary: const Icon(Icons.public),
              title: Text(l10n.t('show_country')),
              subtitle: Text(l10n.t('country_optional')),
              value: profile.showCountry,
              onChanged: profile.countryCode == null
                  ? null
                  : (bool v) => ref
                      .read(profileProvider.notifier)
                      .save(profile.copyWith(showCountry: v)),
            ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.t('privacy_policy')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.t('terms')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.rule_outlined),
            title: Text(l10n.t('rules')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/rules'),
          ),

          _Header(title: l10n.t('support')),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(l10n.t('support')),
            subtitle: const Text(AppConstants.supportEmail),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(l10n.t('report_problem')),
            subtitle: const Text(AppConstants.supportEmail),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.t('about')),
            subtitle: Text('${AppConstants.appNameAr} — ${AppConstants.sloganAr}'),
          ),

          const Divider(height: 32),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(l10n.t('sign_out'),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () async {
              final bool confirmed = await _confirm(context, l10n.t('sign_out_confirm'));
              if (!confirmed) return;
              await ref.read(authActionsProvider).signOut();
              if (context.mounted) context.go('/welcome');
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
            title: Text(l10n.t('delete_account'),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            subtitle: Text(l10n.t('delete_account_warning')),
            onTap: () async {
              final bool confirmed =
                  await _confirm(context, l10n.t('delete_account_warning'));
              if (!confirmed) return;
              try {
                await ref.read(authActionsProvider).deleteAccount();
                if (context.mounted) context.go('/welcome');
              } catch (e) {
                if (context.mounted) {
                  context.showSnack(
                      ErrorMapper.map(e).localized(l10n.languageCode), error: true);
                }
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String message) async {
    final AppLocalizations l10n = context.l10n;
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            content: Text(message),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('cancel'))),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.t('confirm'))),
            ],
          ),
        ) ??
        false;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                )),
      );
}
