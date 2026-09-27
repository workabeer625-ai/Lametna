import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/content_filter.dart';
import '../../../core/widgets/design_kit.dart';
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    if (widget.ctx.state.hasSubmitted) {
      return GameRoundScaffold(
        round: round,
        title: '${l10n.t('apo_letter')}: ${round.letter ?? ''}',
        accent: AppColors.teal,
        child: WaitingForOthers(
          submittedCount: null,
          totalCount: widget.ctx.state.alivePlayers.length,
        ),
      );
    }

    return GameRoundScaffold(
      round: round,
      title: l10n.t('apo_instructions'),
      accent: AppColors.teal,
      child: Column(
        children: <Widget>[
          const SizedBox(height: 4),
          _LetterBadge(letter: round.letter ?? '?'),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: round.categories.length,
              itemBuilder: (_, int i) {
                final String category = round.categories[i];
                final Color tone =
                    AppColors.playful[(i * 3) % AppColors.playful.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FadeInUp(
                    delay: Duration(milliseconds: 40 * i),
                    offset: 8,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 4, 14, 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.white.op(0.05)
                            : AppColors.white.op(0.68),
                        borderRadius: BorderRadius.circular(AppTheme.rMd),
                        border: Border.all(color: tone.op(0.26)),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              gradient: AppGradients.from(tone),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(Icons.edit_rounded,
                                size: 16, color: AppColors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controllerFor(category),
                              maxLength: AppConstants.maxAnswerLength,
                              textInputAction:
                                  i == round.categories.length - 1
                                      ? TextInputAction.done
                                      : TextInputAction.next,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: ink),
                              decoration: InputDecoration(
                                hintText: l10n.category(category),
                                hintStyle: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: muted),
                                counterText: '',
                                isDense: true,
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
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
          child: GradientButton(
            label: l10n.t('submit'),
            icon: Icons.send_rounded,
            height: 56,
            loading: _busy,
            colors: <Color>[
              AppColors.lighten(AppColors.teal, 0.1),
              AppColors.deepen(AppColors.teal, 0.14),
            ],
            onTap: _busy ? null : _submit,
          ),
        ),
      ),
    );
  }
}

/// حرف الجولة داخل دائرة ذهبية متوهّجة.
class _LetterBadge extends StatelessWidget {
  const _LetterBadge({required this.letter});
  final String letter;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.7, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (_, double scale, Widget? child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: AppGradients.gold,
            shape: BoxShape.circle,
            boxShadow:
                AppTheme.glow(AppColors.gold, opacity: 0.42, blur: 30, y: 12),
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: AppColors.espresso,
            ),
          ),
        ),
      );
}

class _ApoResultView extends StatelessWidget {
  const _ApoResultView({required this.ctx});
  final GameRoundContext ctx;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;

    final GameRound round = ctx.state.round!;
    final List<dynamic> answers =
        (round.result?['answers'] as List<dynamic>?) ?? <dynamic>[];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: <Widget>[
        Center(child: _LetterBadge(letter: round.letter ?? '?')),
        const SizedBox(height: 18),
        ...List<Widget>.generate(answers.length, (int i) {
          final Map<String, dynamic> a =
              Map<String, dynamic>.from(answers[i] as Map<dynamic, dynamic>);
          final Map<String, dynamic> payload = Map<String, dynamic>.from(
              (a['payload'] ?? <String, dynamic>{}) as Map<dynamic, dynamic>);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FadeInUp(
              delay: Duration(milliseconds: 40 * (i < 8 ? i : 8)),
              offset: 10,
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${a['nickname']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: ink),
                          ),
                        ),
                        GlassPill(
                          dense: true,
                          label: '+${a['points']} ${l10n.t('points')}',
                          color: AppColors.gold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: round.categories
                          .where((String c) =>
                              (payload[c] ?? '').toString().isNotEmpty)
                          .map((String c) => GlassPill(
                                dense: true,
                                label: '${l10n.category(c)}: ${payload[c]}',
                                color: AppColors.forSeed(c),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
