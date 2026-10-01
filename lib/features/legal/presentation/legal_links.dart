import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/design_kit.dart';

/// روابط الوثائق القانونية — تظهر **قبل** إنشاء الحساب أو الدخول كضيف،
/// حتى يستطيع المستخدم قراءتها دون تسجيل (المسارات عامة في الموجّه).
class LegalLinksRow extends StatelessWidget {
  const LegalLinksRow({super.key, this.showConsent = true, this.compact = false});

  /// إظهار جملة «بالمتابعة فإنك توافق…».
  final bool showConsent;

  /// نسخة مضغوطة (داخل بطاقة ضيّقة).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showConsent) ...<Widget>[
          Text(
            l10n.t('legal_consent'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          spacing: compact ? 6 : 8,
          runSpacing: 8,
          children: <Widget>[
            _LegalChip(
              label: l10n.t('privacy_policy'),
              icon: Icons.privacy_tip_outlined,
              route: '/privacy',
              compact: compact,
            ),
            _LegalChip(
              label: l10n.t('terms'),
              icon: Icons.description_outlined,
              route: '/terms',
              compact: compact,
            ),
            _LegalChip(
              label: l10n.t('rules'),
              icon: Icons.gavel_rounded,
              route: '/rules',
              compact: compact,
            ),
          ],
        ),
      ],
    );
  }
}

class _LegalChip extends StatelessWidget {
  const _LegalChip({
    required this.label,
    required this.icon,
    required this.route,
    required this.compact,
  });

  final String label;
  final IconData icon;
  final String route;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Pressable(
      onTap: () => context.push(route),
      scale: 0.96,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.white.op(0.06) : AppColors.white.op(0.6),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.gold.op(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: compact ? 13 : 14, color: AppColors.gold),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 11.5 : 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
