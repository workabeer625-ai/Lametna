import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import 'splash_screen.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String current = ref.watch(settingsProvider).locale;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const LametnaLogo(size: 88),
              const SizedBox(height: 28),
              Text('اختر اللغة / Choose your language',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 32),
              _LanguageTile(
                title: 'العربية',
                subtitle: 'اللغة الأساسية — واجهة من اليمين لليسار',
                flag: '🌙',
                selected: current == 'ar',
                onTap: () => ref.read(settingsProvider.notifier).setLocale('ar'),
              ),
              const SizedBox(height: 12),
              _LanguageTile(
                title: 'English',
                subtitle: 'Secondary language — left-to-right layout',
                flag: '🌍',
                selected: current == 'en',
                onTap: () => ref.read(settingsProvider.notifier).setLocale('en'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await ref.read(settingsProvider.notifier).setLocale(current);
                  if (context.mounted) context.go('/welcome');
                },
                child: Text(context.l10n.t('next')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      color: selected ? colors.primaryContainer : null,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Text(flag, style: const TextStyle(fontSize: 30)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle),
        trailing: Icon(selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected ? colors.primary : colors.outline),
      ),
    );
  }
}
