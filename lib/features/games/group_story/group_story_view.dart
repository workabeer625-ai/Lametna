import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/content_filter.dart';
import '../../../models/models.dart';
import '../engine/game_definition.dart';
import '../shared/game_scaffold.dart';

/// القصة الجماعية — كتابة جملة ثم تصويت على أفضل جملة، مع فلترة المحتوى.
class GroupStoryGame extends GameDefinition {
  const GroupStoryGame();

  @override
  String get key => GameKeys.groupStory;

  @override
  Widget buildRound(BuildContext context, GameRoundContext ctx) => _StoryRoundView(ctx: ctx);

  @override
  Widget? buildRoundResult(BuildContext context, GameRoundContext ctx) {
    final AppLocalizations l10n = context.l10n;
    final Map<String, dynamic>? result = ctx.state.round?.result;
    final List<dynamic> lines = (result?['lines'] as List<dynamic>?) ?? <dynamic>[];
    final String? best = result?['best'] as String?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(l10n.t('group_story'),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ...lines.map((dynamic raw) {
          final Map<String, dynamic> line =
              Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
          final bool isBest = line['user_id'] == best;
          return Card(
            color: isBest ? Theme.of(context).colorScheme.tertiaryContainer : null,
            child: ListTile(
              leading: isBest ? const Text('🏆', style: TextStyle(fontSize: 22)) : null,
              title: Text('${line['text']}'),
              subtitle: Text('${line['nickname']}'),
            ),
          );
        }),
      ],
    );
  }
}

class _StoryRoundView extends StatefulWidget {
  const _StoryRoundView({required this.ctx});
  final GameRoundContext ctx;

  @override
  State<_StoryRoundView> createState() => _StoryRoundViewState();
}

class _StoryRoundViewState extends State<_StoryRoundView> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;

  GameRound get _round => widget.ctx.state.round!;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _write() async {
    final AppLocalizations l10n = context.l10n;
    final String text = _controller.text.trim();
    final String? problem = ContentFilter.validate(text, maxLength: 200);
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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final GameRound round = _round;

    if (round.stage == 'write') {
      if (widget.ctx.state.hasSubmitted) {
        return GameRoundScaffold(
          round: round,
          title: l10n.t('group_story'),
          child: const WaitingForOthers(),
        );
      }
      return GameRoundScaffold(
        round: round,
        title: l10n.t('story_write'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('${round.prompt['opening'] ?? ''}',
                      style: Theme.of(context).textTheme.bodyLarge),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLength: 200,
                maxLines: 3,
                decoration: InputDecoration(labelText: l10n.t('story_write')),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _write,
                icon: const Icon(Icons.send),
                label: Text(l10n.t('submit')),
              ),
            ],
          ),
        ),
      );
    }

    return GameRoundScaffold(
      round: round,
      title: l10n.t('story_vote'),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: round.ballot.map((Map<String, dynamic> line) {
          final String userId = '${line['user_id']}';
          final bool isMe = userId == widget.ctx.myUserId;
          return Card(
            child: ListTile(
              title: Text('${line['text']}'),
              subtitle: Text('${line['nickname']}'),
              trailing: isMe
                  ? null
                  : IconButton.filled(
                      onPressed: widget.ctx.state.hasVoted
                          ? null
                          : () => widget.ctx.controller
                              .castVote(kind: 'story_line', targetUser: userId),
                      icon: const Icon(Icons.favorite_outline),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
