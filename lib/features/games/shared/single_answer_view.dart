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

// --- ألعاب الاختيار من متعدد (ترحيل 0012) ---

class CapitalsGame extends _SingleAnswerGame {
  const CapitalsGame()
      : super(
          gameKey: GameKeys.capitals,
          titleKey: 'capitals',
          hintKey: 'capitals_hint',
          choicesFromPrompt: true,
        );
}

class FlagsGame extends _SingleAnswerGame {
  const FlagsGame()
      : super(
          gameKey: GameKeys.flags,
          titleKey: 'flags',
          hintKey: 'flags_hint',
          choicesFromPrompt: true,
        );
}

class IslamicGame extends _SingleAnswerGame {
  const IslamicGame()
      : super(
          gameKey: GameKeys.islamic,
          titleKey: 'islamic',
          hintKey: 'islamic_hint',
          choicesFromPrompt: true,
        );
}

class SportsGame extends _SingleAnswerGame {
  const SportsGame()
      : super(
          gameKey: GameKeys.sports,
          titleKey: 'sports',
          hintKey: 'sports_hint',
          choicesFromPrompt: true,
        );
}

class HistoryGame extends _SingleAnswerGame {
  const HistoryGame()
      : super(
          gameKey: GameKeys.history,
          titleKey: 'history',
          hintKey: 'history_hint',
          choicesFromPrompt: true,
        );
}

// --- ألعاب الإجابة النصية (ترحيل 0012) ---

class RiddlesGame extends _SingleAnswerGame {
  const RiddlesGame()
      : super(
          gameKey: GameKeys.riddles,
          titleKey: 'riddles',
          hintKey: 'riddles_hint',
          progressiveHints: true,
        );
}

class EmojiPuzzleGame extends _SingleAnswerGame {
  const EmojiPuzzleGame()
      : super(
          gameKey: GameKeys.emojiPuzzle,
          titleKey: 'emoji_puzzle',
          hintKey: 'emoji_puzzle_hint',
          progressiveHints: true,
        );
}

class NeverHaveIGame extends _SingleAnswerGame {
  const NeverHaveIGame()
      : super(
          gameKey: GameKeys.neverHaveI,
          titleKey: 'never_have_i',
          hintKey: 'never_have_i_hint',
          choicesFromPrompt: true,
        );
}

class WouldYouRatherGame extends _SingleAnswerGame {
  const WouldYouRatherGame()
      : super(
          gameKey: GameKeys.wouldYouRather,
          titleKey: 'would_you_rather',
          hintKey: 'would_you_rather_hint',
          choicesFromPrompt: true,
        );
}

class FastMathGame extends _SingleAnswerGame {
  const FastMathGame()
      : super(
          gameKey: GameKeys.fastMath,
          titleKey: 'fast_math',
          hintKey: 'fast_math_hint',
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

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
      badge: l10n.t(widget.titleKey),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        child: Column(
          children: <Widget>[
            // ── التلميحات ────────────────────────────────────
            if (widget.progressiveHints && round.hints.isNotEmpty)
              ...List<Widget>.generate(_visibleHints(), (int i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FadeInUp(
                    offset: 8,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                      decoration: BoxDecoration(
                        color: AppColors.gold.op(isDark ? 0.12 : 0.10),
                        borderRadius: BorderRadius.circular(AppTheme.rSm),
                        border: Border.all(color: AppColors.gold.op(0.25)),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              gradient: AppGradients.gold,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: AppColors.espresso,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              round.hints[i],
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 6),

            // ── الإجابات ─────────────────────────────────────
            if (widget.choicesFromPrompt && choices.isNotEmpty)
              Column(
                children: List<Widget>.generate(choices.length, (int i) {
                  final Color tone = AppColors
                      .playful[(i * 2) % AppColors.playful.length];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FadeInUp(
                      delay: Duration(milliseconds: 40 * i),
                      offset: 10,
                      child: _ChoiceTile(
                        index: i,
                        label: choices[i],
                        tone: tone,
                        enabled: !_busy,
                        onTap: () => _submit(choices[i]),
                      ),
                    ),
                  );
                }),
              )
            else
              Column(
                children: <Widget>[
                  GlassCard(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: TextField(
                      controller: _controller,
                      maxLength: AppConstants.maxAnswerLength,
                      textInputAction: TextInputAction.done,
                      onSubmitted: _busy ? null : _submit,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.t('guess_hint'),
                        hintStyle: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: muted),
                        counterText: '',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GradientButton(
                    label: l10n.t('submit'),
                    icon: Icons.send_rounded,
                    height: 56,
                    loading: _busy,
                    onTap: _busy ? null : () => _submit(_controller.text),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// زرّ خيار كبير بحرف مميّز وتدرّج لوني.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.index,
    required this.label,
    required this.tone,
    required this.enabled,
    required this.onTap,
  });

  final int index;
  final String label;
  final Color tone;
  final bool enabled;
  final VoidCallback onTap;

  static const List<String> _letters = <String>['أ', 'ب', 'ج', 'د', 'هـ', 'و'];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Pressable(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.white.op(0.06) : AppColors.white.op(0.7),
            borderRadius: BorderRadius.circular(AppTheme.rMd),
            border: Border.all(color: tone.op(0.3)),
            boxShadow: AppTheme.glow(tone, opacity: 0.14, blur: 16, y: 6),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppGradients.from(tone),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  index < _letters.length ? _letters[index] : '${index + 1}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ),
            ],
          ),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    final GameRound round = ctx.state.round!;
    final List<dynamic> answers =
        (round.result?['answers'] as List<dynamic>?) ?? <dynamic>[];
    final String? correct = round.result?['correct_answer'] as String?;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        if (correct != null)
          FadeInUp(
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                gradient: AppGradients.green,
                borderRadius: BorderRadius.circular(AppTheme.rLg),
                boxShadow: AppTheme.glow(AppColors.green,
                    opacity: 0.34, blur: 26, y: 10),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.verified_rounded,
                          size: 18, color: AppColors.white),
                      const SizedBox(width: 8),
                      Text(
                        l10n.t('correct_answer'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white.op(0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    correct,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
        ...List<Widget>.generate(answers.length, (int i) {
          final Map<String, dynamic> a =
              Map<String, dynamic>.from(answers[i] as Map<dynamic, dynamic>);
          final bool isCorrect = (a['correct'] ?? false) as bool;
          final Color tone = isCorrect ? AppColors.green : AppColors.danger;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FadeInUp(
              delay: Duration(milliseconds: 40 * (i < 8 ? i : 8)),
              offset: 10,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.white.op(0.05)
                      : AppColors.white.op(0.62),
                  borderRadius: BorderRadius.circular(AppTheme.rMd),
                  border: Border.all(color: tone.op(0.28)),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: tone.op(0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCorrect ? Icons.check_rounded : Icons.close_rounded,
                        size: 18,
                        color: tone,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${a['nickname']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${a['value'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${a['points']}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: tone,
                      ),
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
