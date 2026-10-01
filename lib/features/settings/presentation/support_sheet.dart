import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/design_kit.dart';

/// ورقة «تواصل مع الدعم / أبلغ عن مشكلة».
///
/// تفتح تطبيق البريد برسالة جاهزة إلى [AppConstants.supportEmail]،
/// وإن تعذّر ذلك (لا يوجد تطبيق بريد) تنسخ العنوان والرسالة إلى الحافظة.
Future<void> showSupportSheet(
  BuildContext context, {
  bool isBugReport = false,
  String? userId,
}) {
  final AppLocalizations l10n = context.l10n;

  final String subject = isBugReport
      ? l10n.t('support_subject_bug')
      : l10n.t('support_subject_help');

  final String platform =
      kIsWeb ? 'web' : '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

  final String body = '${l10n.t('support_body_hint')}\n\n'
      '--------------------\n'
      '${AppConstants.appNameEn} ${AppConstants.appVersion}\n'
      '$platform\n'
      '${userId == null ? '' : 'id: $userId\n'}'
      '--------------------\n';

  Future<void> openMail() async {
    final Uri uri = Uri.parse(
      'mailto:${AppConstants.supportEmail}'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      await Clipboard.setData(
          ClipboardData(text: '${AppConstants.supportEmail}\n\n$subject\n$body'));
      if (context.mounted) context.showSnack(l10n.t('support_copied'));
    }
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.espresso.op(0.45),
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final bool isDark = Theme.of(sheetContext).brightness == Brightness.dark;
      final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
      final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;
      final Color tone = isBugReport ? AppColors.rose : AppColors.gold;

      return ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppTheme.rXl)),
        child: Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.espresso.op(0.94) : AppColors.cream.op(0.97),
            border: Border(
              top: BorderSide(
                  color: (isDark ? AppColors.white : AppColors.coffee).op(0.12)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: AppGradients.gold,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppGradients.from(tone),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow:
                          AppTheme.glow(tone, opacity: 0.3, blur: 20, y: 8),
                    ),
                    child: Icon(
                      isBugReport
                          ? Icons.bug_report_rounded
                          : Icons.support_agent_rounded,
                      size: 27,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isBugReport
                        ? l10n.t('report_problem')
                        : l10n.t('contact_support'),
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.t('support_how'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12.5,
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                        color: muted),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.alternate_email_rounded,
                            size: 18, color: tone),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppConstants.supportEmail,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: l10n.t('open_mail_app'),
                    icon: Icons.send_rounded,
                    height: 54,
                    colors: <Color>[
                      AppColors.lighten(tone, 0.08),
                      AppColors.deepen(tone, 0.14),
                    ],
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await openMail();
                    },
                  ),
                  const SizedBox(height: 10),
                  GhostButton(
                    label: l10n.t('copy_email'),
                    icon: Icons.content_copy_rounded,
                    height: 50,
                    onTap: () async {
                      await Clipboard.setData(
                          const ClipboardData(text: AppConstants.supportEmail));
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                      if (context.mounted) {
                        context.showSnack(l10n.t('email_copied'));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
