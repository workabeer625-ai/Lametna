import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/extensions/context_ext.dart';
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
  final RoomController controller = ref.read(roomControllerProvider(roomId).notifier);

  Future<void> run(Future<void> Function() action, String successKey) async {
    try {
      await action();
      if (context.mounted) context.showSnack(l10n.t(successKey));
    } catch (e) {
      if (context.mounted) {
        context.showSnack(ErrorMapper.map(e).localized(l10n.languageCode), error: true);
      }
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            title: Text(nickname,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(l10n.t('report_user')),
            onTap: () async {
              Navigator.pop(sheetContext);
              await _showReportDialog(context, ref, roomId, userId, nickname);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: Text(l10n.t('block_user')),
            subtitle: Text(l10n.t('privacy')),
            onTap: () async {
              Navigator.pop(sheetContext);
              await run(() => controller.block(userId), 'done');
            },
          ),
          if (isHost) ...<Widget>[
            const Divider(height: 1),
            ListTile(
              leading: Icon(isMuted ? Icons.volume_up : Icons.volume_off),
              title: Text(isMuted ? l10n.t('unmute_player') : l10n.t('mute_player')),
              onTap: () async {
                Navigator.pop(sheetContext);
                await run(() => controller.mute(userId, !isMuted), 'done');
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: Text(l10n.t('kick_player')),
              onTap: () async {
                Navigator.pop(sheetContext);
                await run(() => controller.kick(userId), 'done');
              },
            ),
            ListTile(
              leading: const Icon(Icons.gavel),
              title: Text(l10n.t('ban_player')),
              onTap: () async {
                Navigator.pop(sheetContext);
                await run(() => controller.ban(userId), 'done');
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text(l10n.t('transfer_host')),
              onTap: () async {
                Navigator.pop(sheetContext);
                await run(() => controller.transferHost(userId), 'done');
              },
            ),
          ],
        ],
      ),
    ),
  );
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
    builder: (BuildContext dialogContext) => StatefulBuilder(
      builder: (BuildContext ctx, void Function(void Function()) setState) => AlertDialog(
        title: Text('${l10n.t('report_user')}: $nickname'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: reason,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.t('report_reason')),
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
                decoration: InputDecoration(labelText: l10n.t('report_details')),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(roomControllerProvider(roomId).notifier).report(
                      userId: userId,
                      reason: reason,
                      details: details.text.trim().isEmpty ? null : details.text.trim(),
                    );
                if (context.mounted) context.showSnack(l10n.t('report_sent'));
              } catch (e) {
                if (context.mounted) {
                  context.showSnack(
                      ErrorMapper.map(e).localized(l10n.languageCode), error: true);
                }
              }
            },
            child: Text(l10n.t('report')),
          ),
        ],
      ),
    ),
  );
}
