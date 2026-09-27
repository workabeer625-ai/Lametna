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

/// القصة الجماعية — كتابة جملة ثم تصويت على أفضل جملة، مع فلترة المحتوى.
class GroupStoryGame extends GameDefinition {
  const GroupStoryGame({
    this.gameKey = GameKeys.groupStory,
    this.titleKey = 'group_story',
  });

  /// يسمح لألعاب أخرى بإعادة استخدام المحرك نفسه (مثل «أفضل جواب»).
  final String gameKey;
  final String titleKey;

  @override
  String get key => gameKey;

  @override
  Widget buildRound(BuildContext context, GameRoundContext ctx) => _StoryRoundView(ctx: ctx);

  @override
  Widget? buildRoundResult(BuildContext context, GameRoundContext ctx) {
    final AppLocalizations l10n = context.l10n;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    final Map<String, dynamic>? result = ctx.state.round?.result;
    final List<dynamic> lines = (result?['lines'] as List<dynamic>?) ?? <dynamic>[];
    final String? best = result?['best'] as String?;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      children: <Widget>[
        Text(
          l10n.t(titleKey),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: ink,
          ),
        ),
        const SizedBox(height: 16),
        ...List<Widget>.generate(lines.length, (int i) {
          final Map<String, dynamic> line =
              Map<String, dynamic>.from(lines[i] as Map<dynamic, dynamic>);
          final bool isBest = line['user_id'] == best;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FadeInUp(
              delay: Duration(milliseconds: 40 * (i < 8 ? i : 8)),
              offset: 10,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: isBest
                      ? AppColors.gold.op(isDark ? 0.16 : 0.12)
                      : (isDark
                          ? AppColors.white.op(0.05)
                          : AppColors.white.op(0.64)),
                  borderRadius: BorderRadius.circular(AppTheme.rMd),
                  border: Border.all(
                    color: isBest
                        ? AppColors.gold.op(0.45)
                        : (isDark ? AppColors.white : AppColors.coffee).op(0.10),
                  ),
                  boxShadow: isBest
                      ? AppTheme.glow(AppColors.gold,
                          opacity: 0.22, blur: 18, y: 6)
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (isBest) ...<Widget>[
                      const Text('🏆', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${line['text']}',
                            style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                fontWeight: FontWeight.w700,
                                color: ink),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${line['nickname']}',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: muted),
                          ),
                        ],
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

/// أفضل جواب — نفس محرك «القصة الجماعية»: كتابة ثم تصويت.
class BestAnswerGame extends GroupStoryGame {
  const BestAnswerGame()
      : super(gameKey: GameKeys.bestAnswer, titleKey: 'best_answer');
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    if (round.stage == 'write') {
      if (widget.ctx.state.hasSubmitted) {
        return GameRoundScaffold(
          round: round,
          title: l10n.t('group_story'),
          accent: AppColors.teal,
          child: const WaitingForOthers(),
        );
      }
      return GameRoundScaffold(
        round: round,
        title: l10n.t('story_write'),
        accent: AppColors.teal,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          child: Column(
            children: <Widget>[
              FadeInUp(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppGradients.coffee,
                    borderRadius: BorderRadius.circular(AppTheme.rLg),
                    boxShadow: AppTheme.glow(AppColors.coffee,
                        opacity: 0.26, blur: 22, y: 8),
                  ),
                  child: Text(
                    '${round.prompt['opening'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: TextField(
                  controller: _controller,
                  maxLength: 200,
                  maxLines: 3,
                  style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                      color: ink),
                  decoration: InputDecoration(
                    hintText: l10n.t('story_write'),
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
                colors: <Color>[
                  AppColors.lighten(AppColors.teal, 0.1),
                  AppColors.deepen(AppColors.teal, 0.14),
                ],
                onTap: _busy ? null : _write,
              ),
            ],
          ),
        ),
      );
    }

    return GameRoundScaffold(
      round: round,
      title: l10n.t('story_vote'),
      accent: AppColors.rose,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: List<Widget>.generate(round.ballot.length, (int i) {
          final Map<String, dynamic> line = round.ballot[i];
          final String userId = '${line['user_id']}';
          final bool isMe = userId == widget.ctx.myUserId;
          final bool voted = widget.ctx.state.hasVoted;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FadeInUp(
              delay: Duration(milliseconds: 40 * (i < 8 ? i : 8)),
              offset: 10,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.white.op(0.05)
                      : AppColors.white.op(0.66),
                  borderRadius: BorderRadius.circular(AppTheme.rMd),
                  border: Border.all(
                      color: (isDark ? AppColors.white : AppColors.coffee)
                          .op(0.10)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${line['text']}',
                            style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                fontWeight: FontWeight.w700,
                                color: ink),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${line['nickname']}',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: muted),
                          ),
                        ],
                      ),
                    ),
                    if (!isMe) ...<Widget>[
                      const SizedBox(width: 10),
                      Pressable(
                        onTap: voted
                            ? null
                            : () => widget.ctx.controller.castVote(
                                kind: 'story_line', targetUser: userId),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: voted
                                ? null
                                : AppGradients.from(AppColors.rose),
                            color: voted ? AppColors.mutedDark.op(0.18) : null,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            voted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: voted ? muted : AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
