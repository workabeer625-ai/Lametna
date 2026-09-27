import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/design_kit.dart';
import '../../../providers/settings_provider.dart';
import 'splash_screen.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String current = ref.watch(settingsProvider).locale;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: <Widget>[
                const Spacer(),
                const FadeInUp(child: LametnaLogo(size: 96)),
                const SizedBox(height: 28),
                FadeInUp(
                  delay: const Duration(milliseconds: 90),
                  child: Text(
                    'اختر اللغة / Choose your language',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 21,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                FadeInUp(
                  delay: const Duration(milliseconds: 150),
                  child: _LanguageTile(
                    title: 'العربية',
                    subtitle: 'اللغة الأساسية — واجهة من اليمين لليسار',
                    flag: '🌙',
                    accent: AppColors.gold,
                    selected: current == 'ar',
                    onTap: () => ref.read(settingsProvider.notifier).setLocale('ar'),
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 210),
                  child: _LanguageTile(
                    title: 'English',
                    subtitle: 'Secondary language — left-to-right layout',
                    flag: '🌍',
                    accent: AppColors.teal,
                    selected: current == 'en',
                    onTap: () => ref.read(settingsProvider.notifier).setLocale('en'),
                  ),
                ),
                const Spacer(flex: 2),
                FadeInUp(
                  delay: const Duration(milliseconds: 270),
                  child: GradientButton(
                    label: context.l10n.t('next'),
                    icon: Icons.arrow_forward_rounded,
                    height: 58,
                    onTap: () async {
                      await ref.read(settingsProvider.notifier).setLocale(current);
                      if (context.mounted) context.go('/welcome');
                    },
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

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.flag,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String flag;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.fast,
        curve: AppTheme.ease,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: selected
              ? accent.op(isDark ? 0.16 : 0.12)
              : (isDark ? AppColors.white.op(0.05) : AppColors.white.op(0.62)),
          borderRadius: BorderRadius.circular(AppTheme.rMd),
          border: Border.all(
            color: selected
                ? accent.op(0.5)
                : (isDark ? AppColors.white : AppColors.coffee).op(0.10),
            width: selected ? 1.6 : 1,
          ),
          boxShadow:
              selected ? AppTheme.glow(accent, opacity: 0.26, blur: 20, y: 8) : null,
        ),
        child: Row(
          children: <Widget>[
            Text(flag, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, color: ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w600, color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: AppTheme.fast,
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected ? AppGradients.from(accent) : null,
                border: selected
                    ? null
                    : Border.all(color: muted.op(0.5), width: 1.6),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 16, color: AppColors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
