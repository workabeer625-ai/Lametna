import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/env.dart';
import '../../../core/widgets/design_kit.dart';
import '../../../providers/core_providers.dart';

class _StatusScaffold extends StatelessWidget {
  const _StatusScaffold({
    required this.emoji,
    required this.title,
    required this.body,
    this.action,
  });

  final String emoji;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(28),
              child: FadeInUp(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(emoji, style: const TextStyle(fontSize: 72)),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 23,
                        height: 1.35,
                        fontWeight: FontWeight.w900,
                        color: ink,
                      ),
                    ),
                    if (body.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                          color: muted,
                        ),
                      ),
                    ],
                    if (action != null) ...<Widget>[
                      const SizedBox(height: 26),
                      SizedBox(width: 230, child: action!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// شاشة عدم وجود إنترنت — تعيد المحاولة تلقائيًا عند عودة الشبكة.
class NoInternetScreen extends ConsumerWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    return _StatusScaffold(
      emoji: '📡',
      title: l10n.t('no_internet'),
      body: l10n.t('no_internet_body'),
      action: GradientButton(
        label: l10n.t('retry'),
        icon: Icons.refresh_rounded,
        onTap: () => ref.invalidate(networkStatusProvider),
      ),
    );
  }
}

/// شاشة انقطاع الاتصال بالغرفة.
class DisconnectedScreen extends StatelessWidget {
  const DisconnectedScreen({super.key, this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return _StatusScaffold(
      emoji: '🔌',
      title: l10n.t('disconnected'),
      body: l10n.t('reconnecting'),
      action: onRetry == null
          ? null
          : GradientButton(
              label: l10n.t('retry'),
              icon: Icons.refresh_rounded,
              onTap: onRetry,
            ),
    );
  }
}

/// شاشة خطأ عامة.
class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return _StatusScaffold(
      emoji: '⚠️',
      title: l10n.t('error_title'),
      body: message ?? l10n.t('error_body'),
      action: GradientButton(
        label: l10n.t('home'),
        icon: Icons.home_rounded,
        onTap: () => context.go('/home'),
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return _StatusScaffold(
      emoji: '🧭',
      title: l10n.t('not_found'),
      body: '',
      action: GradientButton(
        label: l10n.t('home'),
        icon: Icons.home_rounded,
        onTap: () => context.go('/home'),
      ),
    );
  }
}

/// تظهر فقط إذا نُسي ضبط متغيرات البيئة عند البناء.
class MissingConfigScreen extends StatelessWidget {
  const MissingConfigScreen({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _StatusScaffold(
          emoji: '🔧',
          title: 'إعدادات الخادم غير مضبوطة',
          body: Env.missingConfigMessage,
        ),
      );
}
