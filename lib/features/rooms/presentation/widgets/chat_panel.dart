import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/utils/content_filter.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../models/models.dart';
import '../../../../providers/room_provider.dart';
import 'player_actions_sheet.dart';

/// دردشة نصية فقط — بلا صور ولا صوت، مع فلترة وحدّ للطول.
class ChatPanel extends ConsumerStatefulWidget {
  const ChatPanel({
    super.key,
    required this.roomId,
    required this.state,
    this.channel = 'public',
    this.enabled = true,
  });

  final String roomId;
  final RoomState state;
  final String channel;
  final bool enabled;

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = _controller.text.trim();
    final String? problem =
        ContentFilter.validate(text, maxLength: AppConstants.maxMessageLength);
    if (problem != null) {
      context.showSnack(
          ErrorMapper.map(Exception(problem)).localized(context.l10n.languageCode),
          error: true);
      return;
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(roomControllerProvider(widget.roomId).notifier)
          .sendMessage(text, channel: widget.channel);
      _controller.clear();
      _scrollToEnd();
    } catch (e) {
      if (mounted) {
        context.showSnack(ErrorMapper.map(e).localized(context.l10n.languageCode), error: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String? myId = ref.read(roomControllerProvider(widget.roomId).notifier).myId;
    final List<ChatMessage> messages = widget.state.messages
        .where((ChatMessage m) => m.channel == widget.channel || m.isSystem)
        .toList();

    return Column(
      children: <Widget>[
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(l10n.t('chat_rules'),
                      style: Theme.of(context).textTheme.bodySmall))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (_, int i) => _Bubble(
                    message: messages[i],
                    isMine: messages[i].isMine(myId),
                    onLongPress: messages[i].userId == null || messages[i].isMine(myId)
                        ? null
                        : () => showPlayerActionsSheet(
                              context: context,
                              ref: ref,
                              roomId: widget.roomId,
                              userId: messages[i].userId!,
                              nickname: messages[i].nickname ?? '',
                              isHost: false,
                            ),
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: widget.enabled && !_sending,
                    maxLength: AppConstants.maxMessageLength,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: widget.enabled
                          ? l10n.t('message_hint')
                          : l10n.t('you_are_dead'),
                      counterText: '',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: (widget.enabled && !_sending) ? _send : null,
                  icon: _sending
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMine, this.onLongPress});

  final ChatMessage message;
  final bool isMine;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message.body,
                style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (!isMine) ...<Widget>[
            AppAvatar(avatarKey: message.avatarKey, size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isMine ? colors.primaryContainer : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment:
                      isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: <Widget>[
                    if (!isMine)
                      Text(message.nickname ?? '',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold, color: colors.primary)),
                    Text(message.body),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
