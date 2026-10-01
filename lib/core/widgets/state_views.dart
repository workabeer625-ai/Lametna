import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../errors/app_exception.dart';
import '../errors/error_mapper.dart';
import 'fade_in.dart';
import 'gradient_button.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.gold,
              backgroundColor: AppColors.gold.op(0.16),
            ),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w600, color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppException mapped = ErrorMapper.map(error);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FadeInUp(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: AppColors.danger.op(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.danger.op(0.3)),
                ),
                child: const Icon(Icons.error_outline_rounded,
                    size: 36, color: AppColors.danger),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.t('error_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mapped.localized(l10n.languageCode),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: muted),
              ),
              if (onRetry != null) ...<Widget>[
                const SizedBox(height: 22),
                SizedBox(
                  width: 200,
                  child: GradientButton(
                    label: l10n.t('retry'),
                    icon: Icons.refresh_rounded,
                    onTap: onRetry,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, this.message, this.icon = Icons.inbox_outlined, this.action});

  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FadeInUp(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: <Color>[
                      AppColors.gold.op(0.22),
                      AppColors.coffee.op(0.16),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold.op(0.28)),
                ),
                child: Icon(icon, size: 40, color: AppColors.gold),
              ),
              const SizedBox(height: 18),
              Text(
                message ?? context.l10n.t('empty'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              if (action != null) ...<Widget>[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}
