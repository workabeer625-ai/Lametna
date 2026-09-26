import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/content_filter.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../providers/core_providers.dart';
import '../../../models/models.dart';
import '../engine/game_definition.dart';
import '../shared/game_scaffold.dart';

/// الكذاب بيننا — الكلمة السرية وتوزيعها يتمّان على الخادم.
/// العميل لا يعرف من هو الكذاب إطلاقًا حتى تُحسم الجولة.
class LiarGame extends GameDefinition {
  const LiarGame();

  @override
  String get key => GameKeys.liar;

  @override
  Widget buildRound(BuildContext context, GameRoundContext ctx) => _LiarRoundView(ctx: ctx);

  @override
  Widget? buildRoundResult(BuildContext context, GameRoundContext ctx) {
    final AppLocalizations l10n = context.l10n;
    final Map<String, dynamic>? result = ctx.state.round?.result;
    if (result == null) return null;
    final bool caught = (result['caught'] ?? false) as bool;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(caught ? '🎉' : '🎭', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(caught ? l10n.t('liar_caught') : l10n.t('liar_escaped'),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: Text(l10n.t('liar_was')),
                subtitle: Text(
                  ctx.state.playerById(result['liar'] as String?)?.nickname ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: Text(l10n.t('liar_your_word')),
                subtitle: Text('${result['word'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiarRoundView extends StatefulWidget {
  const _LiarRoundView({required this.ctx});
  final GameRoundContext ctx;

  @override
  State<_LiarRoundView> createState() => _LiarRoundViewState();
}

class _LiarRoundViewState extends State<_LiarRoundView> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;

  GameRound get _round => widget.ctx.state.round!;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _describe() async {
    final AppLocalizations l10n = context.l10n;
    final String text = _controller.text.trim();
    final String? problem = ContentFilter.validate(text, maxLength: 120);
    if (problem != null) {
      context.showSnack(
          ErrorMapper.map(Exception(problem)).localized(l10n.languageCode), error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.ctx.controller.submitAnswer(<String, dynamic>{'value': text});
    } catch (e) {
      if (mounted) {
        context.showSnack(ErrorMapper.map(e).localized(l10n.languageCode), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _vote(String userId) async {
    try {
      await widget.ctx.controller.castVote(kind: 'liar', targetUser: userId);
    } catch (e) {
      if (mounted) {
        context.showSnack(
            ErrorMapper.map(e).localized(context.l10n.languageCode), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final GameRound round = _round;

    // --- مرحلة الوصف -------------------------------------------------
    if (round.stage == 'describe') {
      if (widget.ctx.state.hasSubmitted) {
        return GameRoundScaffold(
          round: round,
          title: l10n.t('liar'),
          child: const WaitingForOthers(),
        );
      }
      return GameRoundScaffold(
        round: round,
        title: l10n.t('liar_describe'),
        subtitle: '${l10n.t('cat_object')}: ${round.prompt['category'] ?? ''}',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      Text(l10n.t('liar_your_word'),
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 6),
                      _MyWord(roundId: round.id),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLength: 120,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.t('liar_describe')),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _describe,
                icon: const Icon(Icons.send),
                label: Text(l10n.t('submit')),
              ),
            ],
          ),
        ),
      );
    }

    // --- مرحلة التصويت -------------------------------------------------
    final List<Map<String, dynamic>> ballot = round.ballot;
    return GameRoundScaffold(
      round: round,
      title: l10n.t('liar_vote'),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: ballot.map((Map<String, dynamic> entry) {
          final String userId = '${entry['user_id']}';
          final bool isMe = userId == widget.ctx.myUserId;
          return Card(
            child: ListTile(
              leading: AppAvatar(
                avatarKey: widget.ctx.state.playerById(userId)?.avatarKey,
                size: 40,
              ),
              title: Text('${entry['nickname']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${entry['text'] ?? ''}'),
              trailing: isMe
                  ? null
                  : FilledButton(
                      onPressed: widget.ctx.state.hasVoted ? null : () => _vote(userId),
                      child: Text(l10n.t('vote')),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


/// كلمة اللاعب السرية — تُجلب من الخادم لكل لاعب على حدة.
/// الكذاب يستلم كلمة مختلفة (decoy) ولا يعرف أنه الكذاب.
class _MyWord extends ConsumerWidget {
  const _MyWord({required this.roundId});
  final String roundId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: ref.read(supabaseServiceProvider).fetchMyRoundSecretWord(roundId),
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
              height: 32, width: 32, child: CircularProgressIndicator(strokeWidth: 2));
        }
        final String word = snapshot.data ?? '؟؟؟';
        return Text(
          word.isEmpty ? '؟؟؟' : word,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        );
      },
    );
  }
}
