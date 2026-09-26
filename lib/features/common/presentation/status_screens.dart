import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/network/env.dart';
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
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(emoji, style: const TextStyle(fontSize: 72)),
                const SizedBox(height: 18),
                Text(title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(body,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
                if (action != null) ...<Widget>[const SizedBox(height: 24), action!],
              ],
            ),
          ),
        ),
      );
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
      action: FilledButton.icon(
        onPressed: () => ref.invalidate(networkStatusProvider),
        icon: const Icon(Icons.refresh),
        label: Text(l10n.t('retry')),
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
          : FilledButton(onPressed: onRetry, child: Text(l10n.t('retry'))),
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
      action: FilledButton(
        onPressed: () => context.go('/home'),
        child: Text(l10n.t('home')),
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
      action: FilledButton(
        onPressed: () => context.go('/home'),
        child: Text(l10n.t('home')),
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
