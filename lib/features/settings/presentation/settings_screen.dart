import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/design_kit.dart';
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

    final String themeLabel = switch (settings.themeMode) {
      ThemeMode.light => l10n.t('theme_light'),
      ThemeMode.dark => l10n.t('theme_dark'),
      ThemeMode.system => l10n.t('theme_system'),
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              ScreenHeader(
                title: l10n.t('settings'),
                onBack: context.canPop() ? () => context.pop() : null,
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  children: <Widget>[
                    // ── المظهر ──────────────────────────────
                    _Group(
                      title: l10n.t('appearance'),
                      delay: 0,
                      children: <Widget>[
                        _Row(
                          icon: Icons.language_rounded,
                          color: AppColors.green,
                          title: l10n.t('language'),
                          subtitle:
                              settings.isArabic ? l10n.t('arabic') : l10n.t('english'),
                          trailing: _MiniToggle(
                            options: const <String>['ar', 'en'],
                            labels: <String>[l10n.t('arabic'), l10n.t('english')],
                            selected: settings.locale,
                            onChanged: controller.setLocale,
                          ),
                        ),
                        _Row(
                          icon: Icons.dark_mode_outlined,
                          color: AppColors.plum,
                          title: l10n.t('dark_mode'),
                          subtitle: themeLabel,
                          chevron: true,
                          onTap: () => _pickTheme(context, settings, controller, l10n),
                        ),
                        _SwitchRow(
                          icon: Icons.notifications_outlined,
                          color: AppColors.amber,
                          title: l10n.t('notifications'),
                          value: settings.notificationsEnabled,
                          onChanged: controller.setNotifications,
                        ),
                      ],
                    ),

                    // ── الخصوصية ────────────────────────────
                    _Group(
                      title: l10n.t('privacy'),
                      delay: 70,
                      children: <Widget>[
                        if (profile != null)
                          _SwitchRow(
                            icon: Icons.public_rounded,
                            color: AppColors.teal,
                            title: l10n.t('show_country'),
                            subtitle: l10n.t('country_optional'),
                            value: profile.showCountry,
                            onChanged: profile.countryCode == null
                                ? null
                                : (bool v) => ref
                                    .read(profileProvider.notifier)
                                    .save(profile.copyWith(showCountry: v)),
                          ),
                        _Row(
                          icon: Icons.privacy_tip_outlined,
                          color: AppColors.coffee,
                          title: l10n.t('privacy_policy'),
                          chevron: true,
                          onTap: () => context.push('/privacy'),
                        ),
                        _Row(
                          icon: Icons.description_outlined,
                          color: AppColors.coffee,
                          title: l10n.t('terms'),
                          chevron: true,
                          onTap: () => context.push('/terms'),
                        ),
                        _Row(
                          icon: Icons.rule_rounded,
                          color: AppColors.coffee,
                          title: l10n.t('rules'),
                          chevron: true,
                          onTap: () => context.push('/rules'),
                        ),
                      ],
                    ),

                    // ── الدعم ───────────────────────────────
                    _Group(
                      title: l10n.t('support'),
                      delay: 140,
                      children: <Widget>[
                        _Row(
                          icon: Icons.mail_outline_rounded,
                          color: AppColors.gold,
                          title: l10n.t('support'),
                          subtitle: AppConstants.supportEmail,
                        ),
                        _Row(
                          icon: Icons.bug_report_outlined,
                          color: AppColors.rose,
                          title: l10n.t('report_problem'),
                          subtitle: AppConstants.supportEmail,
                        ),
                        _Row(
                          icon: Icons.info_outline_rounded,
                          color: AppColors.latte,
                          title: l10n.t('about'),
                          subtitle:
                              '${AppConstants.appNameAr} — ${AppConstants.sloganAr}',
                        ),
                      ],
                    ),

                    // ── الحساب ──────────────────────────────
                    _Group(
                      title: l10n.t('profile'),
                      delay: 210,
                      children: <Widget>[
                        _Row(
                          icon: Icons.logout_rounded,
                          color: AppColors.danger,
                          danger: true,
                          title: l10n.t('sign_out'),
                          onTap: () async {
                            final bool ok =
                                await _confirm(context, l10n.t('sign_out_confirm'));
                            if (!ok) return;
                            await ref.read(authActionsProvider).signOut();
                            if (context.mounted) context.go('/welcome');
                          },
                        ),
                        _Row(
                          icon: Icons.delete_forever_rounded,
                          color: AppColors.danger,
                          danger: true,
                          title: l10n.t('delete_account'),
                          subtitle: l10n.t('delete_account_warning'),
                          onTap: () async {
                            final bool ok = await _confirm(
                                context, l10n.t('delete_account_warning'));
                            if (!ok) return;
                            try {
                              await ref.read(authActionsProvider).deleteAccount();
                              if (context.mounted) context.go('/welcome');
                            } catch (e) {
                              if (context.mounted) {
                                context.showSnack(
                                    ErrorMapper.map(e).localized(l10n.languageCode),
                                    error: true);
                              }
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    Center(
                      child: Opacity(
                        opacity: 0.6,
                        child: BrandWordmark(text: l10n.t('app_name'), fontSize: 18),
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

  Future<void> _pickTheme(
    BuildContext context,
    SettingsState settings,
    SettingsController controller,
    AppLocalizations l10n,
  ) async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.rLg)),
      ),
      builder: (BuildContext ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((ThemeMode mode) {
              final bool on = mode == settings.themeMode;
              final (IconData icon, String label) = switch (mode) {
                ThemeMode.light => (Icons.light_mode_rounded, l10n.t('theme_light')),
                ThemeMode.dark => (Icons.dark_mode_rounded, l10n.t('theme_dark')),
                ThemeMode.system => (Icons.brightness_auto_rounded, l10n.t('theme_system')),
              };
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Pressable(
                  onTap: () {
                    controller.setThemeMode(mode);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: on ? AppGradients.gold : null,
                      color: on
                          ? null
                          : (isDark
                              ? AppColors.white.op(0.05)
                              : AppColors.white.op(0.7)),
                      borderRadius: BorderRadius.circular(AppTheme.rMd),
                      border: Border.all(
                        color: on
                            ? AppColors.goldDeep.op(0.4)
                            : (isDark ? AppColors.white : AppColors.coffee).op(0.12),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(icon,
                            size: 20,
                            color: on
                                ? AppColors.espresso
                                : (isDark
                                    ? AppColors.inkLight
                                    : AppColors.inkDark)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: on
                                  ? AppColors.espresso
                                  : (isDark
                                      ? AppColors.inkLight
                                      : AppColors.inkDark),
                            ),
                          ),
                        ),
                        if (on)
                          const Icon(Icons.check_rounded,
                              size: 20, color: AppColors.espresso),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
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

/// مجموعة إعدادات داخل بطاقة زجاجية.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children, this.delay = 0});

  final String title;
  final List<Widget> children;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return FadeInUp(
      delay: Duration(milliseconds: delay),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 6, bottom: 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: muted,
                ),
              ),
            ),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.color,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.chevron = false,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final Color color;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = danger
        ? AppColors.danger
        : (isDark ? AppColors.inkLight : AppColors.inkDark);
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return Pressable(
      onTap: onTap,
      scale: onTap == null ? 1 : 0.985,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.op(isDark ? 0.18 : 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w600, color: muted),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 8),
              trailing!,
            ] else if (chevron)
              Icon(Icons.chevron_right_rounded, size: 22, color: muted),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.color,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final Color color;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => _Row(
        icon: icon,
        title: title,
        color: color,
        subtitle: subtitle,
        trailing: Switch(value: value, onChanged: onChanged),
      );
}

/// مفتاح صغير بخيارين (اللغة).
class _MiniToggle extends StatelessWidget {
  const _MiniToggle({
    required this.options,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.white : AppColors.coffee).op(0.08),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(options.length, (int i) {
          final bool on = options[i] == selected;
          return Pressable(
            onTap: () => onChanged(options[i]),
            child: AnimatedContainer(
              duration: AppTheme.fast,
              curve: AppTheme.ease,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: on ? AppGradients.gold : null,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: on ? AppColors.espresso : muted,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
