import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/widgets/design_kit.dart';
import '../../../../providers/room_provider.dart';

const List<String> reportReasons = <String>[
  'abuse', 'racism', 'sectarian', 'bullying', 'incitement',
  'profanity', 'doxxing', 'impersonation', 'spam', 'other',
];

/// إجراءات على لاعب: إبلاغ، حظر شخصي، وأدوات المضيف (كتم/طرد/حظر/نقل الإدارة).
Future<void> showPlayerActionsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String roomId,
  required String userId,
  required String nickname,
  required bool isHost,
  bool isMuted = false,
}) async {
  final AppLocalizations l10n = context.l10n;
  final RoomController controller =
      ref.read(roomControllerProvider(roomId).notifier);

  Future<void> run(Future<void> Function() action, String successKey) async {
    try {
      await action();
      if (context.mounted) context.showSnack(l10n.t(successKey));
    } catch (e) {
      if (context.mounted) {
        context.showSnack(ErrorMapper.map(e).localized(l10n.languageCode),
            error: true);
      }
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.espresso.op(0.45),
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final bool isDark = Theme.of(sheetContext).brightness == Brightness.dark;
      final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
      final Color tone = AppColors.forSeed(userId);

      return _SheetShell(
        isDark: isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- رأس البطاقة ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.from(tone),
                      boxShadow:
                          AppTheme.glow(tone, opacity: 0.32, blur: 18, y: 6),
                    ),
                    child: Text(
                      nickname.isEmpty ? '؟' : nickname.trim().substring(0, 1),
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: ink,
                      ),
                    ),
                  ),
                  if (isHost)
                    GlassPill(
                      dense: true,
                      icon: Icons.shield_moon_rounded,
                      label: l10n.t('host'),
                      color: AppColors.gold,
                    ),
                ],
              ),
            ),

            // --- إجراءات متاحة للجميع ---
            _ActionTile(
              icon: Icons.flag_rounded,
              color: AppColors.amber,
              label: l10n.t('report_user'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _showReportDialog(context, ref, roomId, userId, nickname);
              },
            ),
            _ActionTile(
              icon: Icons.block_rounded,
              color: AppColors.rose,
              label: l10n.t('block_user'),
              subtitle: l10n.t('privacy'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await run(() => controller.block(userId), 'done');
              },
            ),

            // --- أدوات المضيف ---
            if (isHost) ...<Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: AppGradients.gold,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.t('host'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.mutedLight
                            : AppColors.mutedDark,
                      ),
                    ),
                  ],
                ),
              ),
              _ActionTile(
                icon: isMuted
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: AppColors.teal,
                label:
                    isMuted ? l10n.t('unmute_player') : l10n.t('mute_player'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await run(() => controller.mute(userId, !isMuted), 'done');
                },
              ),
              _ActionTile(
                icon: Icons.exit_to_app_rounded,
                color: AppColors.plum,
                label: l10n.t('kick_player'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await run(() => controller.kick(userId), 'done');
                },
              ),
              _ActionTile(
                icon: Icons.gavel_rounded,
                color: AppColors.danger,
                label: l10n.t('ban_player'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await run(() => controller.ban(userId), 'done');
                },
              ),
              _ActionTile(
                icon: Icons.workspace_premium_rounded,
                color: AppColors.gold,
                label: l10n.t('transfer_host'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await run(() => controller.transferHost(userId), 'done');
                },
              ),
            ],
            const SizedBox(height: 6),
          ],
        ),
      );
    },
  );
}

/// غلاف زجاجي للورقة السفلية مع مقبض سحب متدرّج.
class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child, required this.isDark});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const BorderRadius br =
        BorderRadius.vertical(top: Radius.circular(AppTheme.rXl));

    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: br,
            color: isDark
                ? AppColors.espresso.op(0.88)
                : AppColors.cream.op(0.94),
            border: Border(
              top: BorderSide(
                color: (isDark ? AppColors.white : AppColors.coffee).op(0.12),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: AppGradients.gold,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                Flexible(child: SingleChildScrollView(child: child)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// صف إجراء بأيقونة ملوّنة داخل مربّع متدرّج.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: Pressable(
        onTap: onTap,
        scale: 0.98,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isDark ? AppColors.white.op(0.05) : AppColors.white.op(0.62),
            borderRadius: BorderRadius.circular(AppTheme.rMd),
            border: Border.all(color: color.op(0.18)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.from(color),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: AppTheme.glow(color, opacity: 0.26, blur: 14, y: 5),
                ),
                child: Icon(icon, size: 20, color: AppColors.white),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, size: 22, color: muted.op(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showReportDialog(
  BuildContext context,
  WidgetRef ref,
  String roomId,
  String userId,
  String nickname,
) async {
  final AppLocalizations l10n = context.l10n;
  String reason = reportReasons.first;
  final TextEditingController details = TextEditingController();

  await showDialog<void>(
    context: context,
    barrierColor: AppColors.espresso.op(0.45),
    builder: (BuildContext dialogContext) {
      final bool isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;

      return StatefulBuilder(
        builder: (BuildContext ctx, void Function(void Function()) setState) =>
            Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: GlassCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            glowColor: AppColors.rose,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppGradients.from(AppColors.rose),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.flag_rounded,
                          size: 19, color: AppColors.white),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        '${l10n.t('report_user')}: $nickname',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(AppTheme.rMd),
                  decoration:
                      InputDecoration(labelText: l10n.t('report_reason')),
                  items: reportReasons
                      .map((String r) => DropdownMenuItem<String>(
                            value: r,
                            child: Text(l10n.reportReason(r)),
                          ))
                      .toList(),
                  onChanged: (String? v) => setState(() => reason = v ?? reason),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: details,
                  maxLength: 300,
                  maxLines: 3,
                  decoration:
                      InputDecoration(labelText: l10n.t('report_details')),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: GhostButton(
                        label: l10n.t('cancel'),
                        height: 50,
                        onTap: () => Navigator.pop(dialogContext),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        label: l10n.t('report'),
                        icon: Icons.send_rounded,
                        height: 50,
                        colors: <Color>[
                          AppColors.lighten(AppColors.rose, 0.08),
                          AppColors.deepen(AppColors.rose, 0.14),
                        ],
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          try {
                            await ref
                                .read(roomControllerProvider(roomId).notifier)
                                .report(
                                  userId: userId,
                                  reason: reason,
                                  details: details.text.trim().isEmpty
                                      ? null
                                      : details.text.trim(),
                                );
                            if (context.mounted) {
                              context.showSnack(l10n.t('report_sent'));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              context.showSnack(
                                  ErrorMapper.map(e)
                                      .localized(l10n.languageCode),
                                  error: true);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
