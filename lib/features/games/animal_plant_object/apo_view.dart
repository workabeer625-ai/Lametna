import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/content_filter.dart';
import '../../../models/models.dart';
import '../engine/game_definition.dart';
import '../shared/game_scaffold.dart';

/// جماد، حيوان، نبات — الحرف يأتي من الخادم، والتقييم والنقاط على الخادم.
class AnimalPlantObjectGame extends GameDefinition {
  const AnimalPlantObjectGame();

  @override
  String get key => GameKeys.animalPlantObject;

  @override
  Widget buildRound(BuildContext context, GameRoundContext ctx) =>
      _ApoRoundView(ctx: ctx);

  @override
  Widget? buildRoundResult(BuildContext context, GameRoundContext ctx) =>
      _ApoResultView(ctx: ctx);
}

class _ApoRoundView extends StatefulWidget {
  const _ApoRoundView({required this.ctx});
  final GameRoundContext ctx;

  @override
  State<_ApoRoundView> createState() => _ApoRoundViewState();
}

class _ApoRoundViewState extends State<_ApoRoundView> {
  final Map<String, TextEditingController> _controllers = <String, TextEditingController>{};
  bool _busy = false;

  GameRound get _round => widget.ctx.state.round!;

  TextEditingController _controllerFor(String category) =>
      _controllers.putIfAbsent(category, () => TextEditingController());

  @override
  void dispose() {
    for (final TextEditingController c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = context.l10n;
    final Map<String, dynamic> payload = <String, dynamic>{};

    for (final String category in _round.categories) {
      final String value = _controllerFor(category).text.trim();
      if (value.isEmpty) continue;
      final String? problem =
          ContentFilter.validate(value, maxLength: AppConstants.maxAnswerLength);
      if (problem != null) {
        context.showSnack(
            ErrorMapper.map(Exception(problem)).localized(l10n.languageCode),
            error: true);
        return;
      }
      payload[category] = value;
    }

    setState(() => _busy = true);
    try {
      await widget.ctx.controller.submitAnswer(payload);
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

    if (widget.ctx.state.hasSubmitted) {
      return GameRoundScaffold(
        round: round,
        title: '${l10n.t('apo_letter')}: ${round.letter ?? ''}',
        child: WaitingForOthers(
          submittedCount: null,
          totalCount: widget.ctx.state.alivePlayers.length,
        ),
      );
    }

    return GameRoundScaffold(
      round: round,
      title: l10n.t('apo_instructions'),
      child: Column(
        children: <Widget>[
          _LetterBadge(letter: round.letter ?? '?'),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: round.categories.length,
              itemBuilder: (_, int i) {
                final String category = round.categories[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: _controllerFor(category),
                    maxLength: AppConstants.maxAnswerLength,
                    textInputAction: i == round.categories.length - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.category(category),
                      counterText: '',
                      isDense: true,
                      prefixIcon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      footer: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: Text(l10n.t('submit')),
          ),
        ),
      ),
    );
  }
}

class _LetterBadge extends StatelessWidget {
  const _LetterBadge({required this.letter});
  final String letter;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        builder: (_, double scale, Widget? child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
          ),
          alignment: Alignment.center,
          child: Text(letter,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  )),
        ),
      );
}

class _ApoResultView extends StatelessWidget {
  const _ApoResultView({required this.ctx});
  final GameRoundContext ctx;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final GameRound round = ctx.state.round!;
    final List<dynamic> answers =
        (round.result?['answers'] as List<dynamic>?) ?? <dynamic>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Center(child: _LetterBadge(letter: round.letter ?? '?')),
        const SizedBox(height: 16),
        ...answers.map((dynamic raw) {
          final Map<String, dynamic> a =
              Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
          final Map<String, dynamic> payload = Map<String, dynamic>.from(
              (a['payload'] ?? <String, dynamic>{}) as Map<dynamic, dynamic>);
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text('${a['nickname']}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Chip(
                        label: Text('+${a['points']} ${l10n.t('points')}'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: round.categories
                        .where((String c) => (payload[c] ?? '').toString().isNotEmpty)
                        .map((String c) => Chip(
                              label: Text('${l10n.category(c)}: ${payload[c]}'),
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
