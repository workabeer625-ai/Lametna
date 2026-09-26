import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/content_filter.dart';
import '../../../models/models.dart';
import '../engine/game_definition.dart';
import 'game_scaffold.dart';

/// الألعاب ذات الإجابة الواحدة: صح/خطأ، خمن الكلمة، أكمل المثل، من أنا.
/// الإجابة الصحيحة تبقى على الخادم (عمود `secret_data` محجوب عن العملاء)،
/// والمطابقة تتم في `resolve_round` مع قبول روايات ولهجات متعددة.
class _SingleAnswerGame extends GameDefinition {
  const _SingleAnswerGame({
    required this.gameKey,
    required this.titleKey,
    required this.hintKey,
    this.choicesFromPrompt = false,
    this.progressiveHints = false,
  });

  final String gameKey;
  final String titleKey;
  final String hintKey;
  final bool choicesFromPrompt;
  final bool progressiveHints;

  @override
  String get key => gameKey;

  @override
  Widget buildRound(BuildContext context, GameRoundContext ctx) => _SingleAnswerRoundView(
        ctx: ctx,
        titleKey: titleKey,
        hintKey: hintKey,
        choicesFromPrompt: choicesFromPrompt,
        progressiveHints: progressiveHints,
      );

  @override
  Widget? buildRoundResult(BuildContext context, GameRoundContext ctx) =>
      _SingleAnswerResultView(ctx: ctx);
}

class TrueFalseGame extends _SingleAnswerGame {
  const TrueFalseGame()
      : super(
          gameKey: GameKeys.trueFalse,
          titleKey: 'true_false',
          hintKey: 'true_false',
          choicesFromPrompt: true,
        );
}

class GuessWordGame extends _SingleAnswerGame {
  const GuessWordGame()
      : super(
          gameKey: GameKeys.guessWord,
          titleKey: 'guess_word',
          hintKey: 'guess_hint',
          progressiveHints: true,
        );
}

class ProverbsGame extends _SingleAnswerGame {
  const ProverbsGame()
      : super(
          gameKey: GameKeys.proverbs,
          titleKey: 'proverbs',
          hintKey: 'proverbs_hint',
        );
}

class WhoAmIGame extends _SingleAnswerGame {
  const WhoAmIGame()
      : super(
          gameKey: GameKeys.whoAmI,
          titleKey: 'who_am_i',
          hintKey: 'who_am_i_hint',
        );
}

// ---------------------------------------------------------------------------

class _SingleAnswerRoundView extends StatefulWidget {
  const _SingleAnswerRoundView({
    required this.ctx,
    required this.titleKey,
    required this.hintKey,
    required this.choicesFromPrompt,
    required this.progressiveHints,
  });

  final GameRoundContext ctx;
  final String titleKey;
  final String hintKey;
  final bool choicesFromPrompt;
  final bool progressiveHints;

  @override
  State<_SingleAnswerRoundView> createState() => _SingleAnswerRoundViewState();
}

class _SingleAnswerRoundViewState extends State<_SingleAnswerRoundView> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;

  GameRound get _round => widget.ctx.state.round!;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(String value) async {
    final AppLocalizations l10n = context.l10n;
    final String answer = value.trim();
    final String? problem =
        ContentFilter.validate(answer, maxLength: AppConstants.maxAnswerLength);
    if (problem != null) {
      context.showSnack(
          ErrorMapper.map(Exception(problem)).localized(l10n.languageCode), error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.ctx.controller.submitAnswer(<String, dynamic>{'value': answer});
    } catch (e) {
      if (mounted) {
        context.showSnack(ErrorMapper.map(e).localized(l10n.languageCode), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// التلميحات تُكشف تدريجيًا حسب الزمن المنقضي من مدة الجولة (نفس المعطيات
  /// عند كل اللاعبين لأنها محسوبة من أوقات الخادم).
  int _visibleHints() {
    final GameRound round = _round;
    if (round.startsAt == null) return 1;
    final int total = round.endsAt.difference(round.startsAt!).inSeconds;
    if (total <= 0) return round.hints.length;
    final int elapsed = DateTime.now().toUtc().difference(round.startsAt!.toUtc()).inSeconds;
    final int step = (total / (round.hints.length + 1)).ceil();
    return (elapsed ~/ step + 1).clamp(1, round.hints.length);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final GameRound round = _round;

    if (widget.ctx.state.hasSubmitted) {
      return GameRoundScaffold(
        round: round,
        title: l10n.t(widget.titleKey),
        child: const WaitingForOthers(),
      );
    }

    final List<String> choices = round.choices;

    return GameRoundScaffold(
      round: round,
      title: round.questionBody ?? l10n.t(widget.titleKey),
      subtitle: l10n.t(widget.hintKey),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            if (widget.progressiveHints && round.hints.isNotEmpty)
              ...List<Widget>.generate(_visibleHints(), (int i) {
                return Card(
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
                    ),
                    title: Text(round.hints[i]),
                  ),
                );
              }),
            const SizedBox(height: 12),
            if (widget.choicesFromPrompt && choices.isNotEmpty)
              Column(
                children: choices
                    .map((String choice) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: FilledButton.tonal(
                            onPressed: _busy ? null : () => _submit(choice),
                            child: Text(choice, style: const TextStyle(fontSize: 18)),
                          ),
                        ))
                    .toList(),
              )
            else
              Column(
                children: <Widget>[
                  TextField(
                    controller: _controller,
                    maxLength: AppConstants.maxAnswerLength,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _busy ? null : _submit,
                    decoration: InputDecoration(
                      labelText: l10n.t('guess_hint'),
                      prefixIcon: const Icon(Icons.lightbulb_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _submit(_controller.text),
                    icon: _busy
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    label: Text(l10n.t('submit')),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SingleAnswerResultView extends StatelessWidget {
  const _SingleAnswerResultView({required this.ctx});
  final GameRoundContext ctx;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final GameRound round = ctx.state.round!;
    final List<dynamic> answers =
        (round.result?['answers'] as List<dynamic>?) ?? <dynamic>[];
    final String? correct = round.result?['correct_answer'] as String?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        if (correct != null)
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(l10n.t('correct_answer')),
              subtitle: Text(correct,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
        const SizedBox(height: 8),
        ...answers.map((dynamic raw) {
          final Map<String, dynamic> a =
              Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
          final bool isCorrect = (a['correct'] ?? false) as bool;
          return Card(
            child: ListTile(
              leading: Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Theme.of(context).colorScheme.error,
              ),
              title: Text('${a['nickname']}'),
              subtitle: Text('${a['value'] ?? ''}'),
              trailing: Text('+${a['points']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ],
    );
  }
}
