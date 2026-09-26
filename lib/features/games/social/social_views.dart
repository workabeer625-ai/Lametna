import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/content_filter.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../models/models.dart';
import '../engine/game_definition.dart';
import '../shared/game_scaffold.dart';

/// ألعاب اللمّة والتفاعل: «مين فينا؟» و«من صاحب الاعتراف؟» و«صراحة».
///
/// كلها تشترك في لبنتين فقط:
///   • [_TextStage]       : كتابة نص قصير وإرساله كإجابة.
///   • [_PlayerVoteStage] : اختيار لاعب من القائمة والتصويت له.
/// المنطق والنقاط والكشف تتم كلها في `resolve_round` على الخادم.

// ===========================================================================
//  مين فينا؟  —  تصويت مباشر على لاعب
// ===========================================================================
class MostLikelyGame extends GameDefinition {
  const MostLikelyGame();

  @override
  String get key => GameKeys.mostLikely;

  @override
  Widget buildRound(BuildContext context, GameRoundContext ctx) => _PlayerVoteStage(
        ctx: ctx,
        title: ctx.state.round?.questionBody ?? context.l10n.t('most_likely'),
        voteKind: 'best_answer',
        allowSelf: true,
      );

  @override
  Widget? buildRoundResult(BuildContext context, GameRoundContext ctx) =>
      _TallyResult(ctx: ctx);
}

// ===========================================================================
//  من صاحب الاعتراف؟  —  كتابة ثم تخمين صاحب الاعتراف
// ===========================================================================
class ConfessionsGame extends GameDefinition {
  const ConfessionsGame();

  @override
  String get key => GameKeys.confessions;

  @override
  Widget buildRound(BuildContext context, GameRoundContext ctx) {
    final GameRound? round = ctx.state.round;
    if (round == null) return const SizedBox.shrink();

    if (round.stage == 'write') {
      return _TextStage(
        ctx: ctx,
        title: context.l10n.t('confessions'),
        prompt: round.questionBody ?? '',
        hint: context.l10n.t('confessions_write'),
        maxLength: 160,
      );
    }
    return _PlayerVoteStage(
      ctx: ctx,
      title: context.l10n.t('confessions_guess'),
      highlight: '${round.prompt['confession'] ?? ''}',
      voteKind: 'best_answer',
      allowSelf: false,
    );
  }

  @override
  Widget? buildRoundResult(BuildContext context, GameRoundContext ctx) {
    final AppLocalizations l10n = context.l10n;
    final Map<String, dynamic>? result = ctx.state.round?.result;
    if (result == null) return null;
    return _SimpleResult(
      emoji: '🤫',
      title: l10n.t('confessions_author'),
      big: '${result['author_nickname'] ?? '—'}',
      body: '${result['confession'] ?? ''}',
    );
  }
}

// ===========================================================================
//  صراحة  —  كرسي الاعتراف ثم تقييم الجواب
// ===========================================================================
class TruthGame extends GameDefinition {
  const TruthGame();

  @override
  String get key => GameKeys.truth;

  @override
  Widget buildRound(BuildContext context, GameRoundContext ctx) {
    final AppLocalizations l10n = context.l10n;
    final GameRound? round = ctx.state.round;
    if (round == null) return const SizedBox.shrink();

    final String? spotlight = round.prompt['spotlight'] as String?;
    final bool isMe = spotlight != null && spotlight == ctx.myUserId;

    if (round.stage == 'spotlight') {
      if (!isMe) {
        return GameRoundScaffold(
          round: round,
          title: l10n.t('truth'),
          subtitle: '${round.prompt['spotlight_nickname'] ?? ''}',
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('💬', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(round.questionBody ?? '',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Text(l10n.t('truth_waiting'),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        );
      }
      return _TextStage(
        ctx: ctx,
        title: l10n.t('truth_your_turn'),
        prompt: round.questionBody ?? '',
        hint: l10n.t('truth_answer_hint'),
        maxLength: 200,
      );
    }

    // --- مرحلة التقييم ---
    return GameRoundScaffold(
      round: round,
      title: l10n.t('truth_rate'),
      subtitle: '${round.prompt['spotlight_nickname'] ?? ''}',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(round.questionBody ?? '',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 10),
                  Text('${round.prompt['answer_text'] ?? ''}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isMe)
            Center(child: Text(l10n.t('truth_waiting_rate')))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: ctx.state.hasVoted
                      ? null
                      : () => _rate(context, ctx, true),
                  icon: const Icon(Icons.thumb_up),
                  label: Text(l10n.t('truth_like')),
                ),
                OutlinedButton.icon(
                  onPressed: ctx.state.hasVoted
                      ? null
                      : () => _rate(context, ctx, false),
                  icon: const Icon(Icons.thumb_down),
                  label: Text(l10n.t('truth_dislike')),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static Future<void> _rate(
      BuildContext context, GameRoundContext ctx, bool liked) async {
    try {
      await ctx.controller.castVote(kind: 'validate_answer', value: liked);
    } catch (e) {
      if (context.mounted) {
        context.showSnack(ErrorMapper.map(e).localized(context.l10n.languageCode),
            error: true);
      }
    }
  }

  @override
  Widget? buildRoundResult(BuildContext context, GameRoundContext ctx) {
    final AppLocalizations l10n = context.l10n;
    final Map<String, dynamic>? result = ctx.state.round?.result;
    if (result == null) return null;
    return _SimpleResult(
      emoji: '💬',
      title: '${result['spotlight_nickname'] ?? ''}',
      big: '${result['answer_text'] ?? ''}',
      body: '${l10n.t('truth_likes')}: ${result['likes'] ?? 0}',
    );
  }
}

// ===========================================================================
//  لبنات مشتركة
// ===========================================================================

/// مرحلة كتابة نص قصير (اعتراف / جواب صراحة).
class _TextStage extends StatefulWidget {
  const _TextStage({
    required this.ctx,
    required this.title,
    required this.prompt,
    required this.hint,
    this.maxLength = 160,
  });

  final GameRoundContext ctx;
  final String title;
  final String prompt;
  final String hint;
  final int maxLength;

  @override
  State<_TextStage> createState() => _TextStageState();
}

class _TextStageState extends State<_TextStage> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = context.l10n;
    final String text = _controller.text.trim();
    final String? problem = ContentFilter.validate(text, maxLength: widget.maxLength);
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
    final GameRound round = widget.ctx.state.round!;

    if (widget.ctx.state.hasSubmitted) {
      return GameRoundScaffold(
        round: round,
        title: widget.title,
        child: const WaitingForOthers(),
      );
    }

    return GameRoundScaffold(
      round: round,
      title: widget.title,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(widget.prompt,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLength: widget.maxLength,
              maxLines: 3,
              decoration: InputDecoration(labelText: widget.hint),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.send),
              label: Text(l10n.t('submit')),
            ),
          ],
        ),
      ),
    );
  }
}

/// مرحلة اختيار لاعب والتصويت له.
class _PlayerVoteStage extends StatelessWidget {
  const _PlayerVoteStage({
    required this.ctx,
    required this.title,
    required this.voteKind,
    required this.allowSelf,
    this.highlight,
  });

  final GameRoundContext ctx;
  final String title;
  final String voteKind;
  final bool allowSelf;
  final String? highlight;

  Future<void> _vote(BuildContext context, String userId) async {
    try {
      await ctx.controller.castVote(kind: voteKind, targetUser: userId);
    } catch (e) {
      if (context.mounted) {
        context.showSnack(ErrorMapper.map(e).localized(context.l10n.languageCode),
            error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final GameRound round = ctx.state.round!;
    final List<RoomPlayer> players = ctx.state.activePlayers;

    return GameRoundScaffold(
      round: round,
      title: title,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (highlight != null && highlight!.isNotEmpty)
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(highlight!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          if (ctx.state.hasVoted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(child: Text(l10n.t('waiting_others'))),
            ),
          ...players.map((RoomPlayer p) {
            final bool isMe = p.userId == ctx.myUserId;
            final bool disabled = ctx.state.hasVoted || (isMe && !allowSelf);
            return Card(
              child: ListTile(
                leading: AppAvatar(avatarKey: p.avatarKey, size: 40),
                title: Text(p.nickname,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: FilledButton(
                  onPressed: disabled ? null : () => _vote(context, p.userId),
                  child: Text(l10n.t('vote')),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// نتيجة على شكل جدول أصوات (مين فينا؟).
class _TallyResult extends StatelessWidget {
  const _TallyResult({required this.ctx});
  final GameRoundContext ctx;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Map<String, dynamic>? result = ctx.state.round?.result;
    final List<dynamic> votes = (result?['votes'] as List<dynamic>?) ?? <dynamic>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('${result?['body'] ?? ''}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('🏆 ${result?['winner_nickname'] ?? '—'}',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...votes.map((dynamic raw) {
          final Map<String, dynamic> v =
              Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
          return Card(
            child: ListTile(
              title: Text('${v['nickname'] ?? ''}'),
              trailing: Text('${v['count'] ?? 0} ${l10n.t('vote')}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ],
    );
  }
}

/// نتيجة بسيطة: رمز + عنوان + نص بارز.
class _SimpleResult extends StatelessWidget {
  const _SimpleResult({
    required this.emoji,
    required this.title,
    required this.big,
    required this.body,
  });

  final String emoji;
  final String title;
  final String big;
  final String body;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(big,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
}
