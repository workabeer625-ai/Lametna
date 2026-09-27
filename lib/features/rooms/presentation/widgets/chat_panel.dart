import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/utils/content_filter.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/pressable.dart';
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

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;

    return Column(
      children: <Widget>[
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.forum_outlined, size: 40, color: muted.op(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          l10n.t('chat_rules'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600, color: muted),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.white.op(0.06) : AppColors.white.op(0.7),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: (isDark ? AppColors.white : AppColors.coffee).op(0.12)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: TextField(
                      controller: _controller,
                      enabled: widget.enabled && !_sending,
                      maxLength: AppConstants.maxMessageLength,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: ink),
                      decoration: InputDecoration(
                        hintText: widget.enabled
                            ? l10n.t('message_hint')
                            : l10n.t('you_are_dead'),
                        hintStyle: TextStyle(fontSize: 13.5, color: muted),
                        counterText: '',
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Pressable(
                  onTap: (widget.enabled && !_sending) ? _send : null,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: widget.enabled
                          ? AppGradients.gold
                          : AppGradients.from(AppColors.mutedDark),
                      shape: BoxShape.circle,
                      boxShadow: widget.enabled
                          ? AppTheme.glow(AppColors.gold, opacity: 0.34, blur: 18, y: 6)
                          : null,
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(15),
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: AppColors.espresso),
                          )
                        : const Icon(Icons.send_rounded,
                            size: 20, color: AppColors.espresso),
                  ),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.gold.op(isDark ? 0.14 : 0.16),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.gold.op(0.24)),
            ),
            child: Text(
              message.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: muted),
            ),
          ),
        ),
      );
    }

    final Color seed = AppColors.forSeed(message.nickname ?? message.userId ?? '');
    final BorderRadius radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 6),
      bottomRight: Radius.circular(isMine ? 6 : 18),
    );

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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMine ? AppGradients.green : null,
                  color: isMine
                      ? null
                      : (isDark ? AppColors.white.op(0.07) : AppColors.white.op(0.78)),
                  borderRadius: radius,
                  border: isMine
                      ? null
                      : Border.all(
                          color: (isDark ? AppColors.white : AppColors.coffee).op(0.10)),
                  boxShadow: isMine
                      ? AppTheme.glow(AppColors.green, opacity: 0.22, blur: 14, y: 5)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment:
                      isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: <Widget>[
                    if (!isMine)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          message.nickname ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: seed,
                          ),
                        ),
                      ),
                    Text(
                      message.body,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: isMine ? AppColors.white : ink,
                      ),
                    ),
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
