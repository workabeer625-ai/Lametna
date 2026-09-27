import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/content_filter.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/design_kit.dart';
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
          accent: AppColors.plum,
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: FadeInUp(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('💬', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 14),
                    Text(
                      round.questionBody ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 18,
                        height: 1.45,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.inkLight
                            : AppColors.inkDark,
                      ),
                    ),
                    const SizedBox(height: 18),
                    GlassPill(
                      icon: Icons.hourglass_bottom_rounded,
                      label: l10n.t('truth_waiting'),
                      color: AppColors.gold,
                    ),
                  ],
                ),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;

    return GameRoundScaffold(
      round: round,
      title: l10n.t('truth_rate'),
      subtitle: '${round.prompt['spotlight_nickname'] ?? ''}',
      accent: AppColors.plum,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: <Widget>[
          FadeInUp(
            child: GlassCard(
              padding: const EdgeInsets.all(18),
              glowColor: AppColors.plum,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    round.questionBody ?? '',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.mutedLight : AppColors.mutedDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${round.prompt['answer_text'] ?? ''}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 19,
                      height: 1.45,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (isMe)
            Center(
              child: GlassPill(
                icon: Icons.hourglass_bottom_rounded,
                label: l10n.t('truth_waiting_rate'),
                color: AppColors.gold,
              ),
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: GradientButton(
                    label: l10n.t('truth_like'),
                    icon: Icons.thumb_up_rounded,
                    height: 54,
                    colors: const <Color>[
                      AppColors.greenLight,
                      AppColors.greenDeep,
                    ],
                    onTap: ctx.state.hasVoted
                        ? null
                        : () => _rate(context, ctx, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GhostButton(
                    label: l10n.t('truth_dislike'),
                    icon: Icons.thumb_down_rounded,
                    height: 54,
                    onTap: ctx.state.hasVoted
                        ? null
                        : () => _rate(context, ctx, false),
                  ),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    if (widget.ctx.state.hasSubmitted) {
      return GameRoundScaffold(
        round: round,
        title: widget.title,
        accent: AppColors.plum,
        child: const WaitingForOthers(),
      );
    }

    return GameRoundScaffold(
      round: round,
      title: widget.title,
      accent: AppColors.plum,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        child: Column(
          children: <Widget>[
            FadeInUp(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppGradients.from(AppColors.plum),
                  borderRadius: BorderRadius.circular(AppTheme.rLg),
                  boxShadow: AppTheme.glow(AppColors.plum,
                      opacity: 0.28, blur: 24, y: 8),
                ),
                child: Text(
                  widget.prompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 17,
                    height: 1.45,
                    fontWeight: FontWeight.w800,
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
                maxLength: widget.maxLength,
                maxLines: 3,
                style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: ink),
                decoration: InputDecoration(
                  hintText: widget.hint,
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
                AppColors.lighten(AppColors.plum, 0.1),
                AppColors.deepen(AppColors.plum, 0.14),
              ],
              onTap: _busy ? null : _submit,
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return GameRoundScaffold(
      round: round,
      title: title,
      accent: AppColors.rose,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: <Widget>[
          if (highlight != null && highlight!.isNotEmpty)
            FadeInUp(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppGradients.from(AppColors.plum),
                  borderRadius: BorderRadius.circular(AppTheme.rLg),
                  boxShadow: AppTheme.glow(AppColors.plum,
                      opacity: 0.28, blur: 24, y: 8),
                ),
                child: Text(
                  highlight!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 17,
                    height: 1.45,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          if (ctx.state.hasVoted)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: GlassPill(
                  icon: Icons.hourglass_bottom_rounded,
                  label: l10n.t('waiting_others'),
                  color: AppColors.gold,
                ),
              ),
            ),
          ...List<Widget>.generate(players.length, (int i) {
            final RoomPlayer p = players[i];
            final bool isMe = p.userId == ctx.myUserId;
            final bool disabled = ctx.state.hasVoted || (isMe && !allowSelf);
            final Color tone = AppColors.forSeed(p.userId);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FadeInUp(
                delay: Duration(milliseconds: 40 * (i < 8 ? i : 8)),
                offset: 10,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.white.op(0.05)
                        : AppColors.white.op(0.66),
                    borderRadius: BorderRadius.circular(AppTheme.rMd),
                    border: Border.all(
                      color: isMe
                          ? AppColors.gold.op(0.35)
                          : (isDark ? AppColors.white : AppColors.coffee)
                              .op(0.10),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.from(tone),
                        ),
                        child: AppAvatar(avatarKey: p.avatarKey, size: 40),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: ink),
                        ),
                      ),
                      Pressable(
                        onTap: disabled ? null : () => _vote(context, p.userId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: disabled
                                ? null
                                : AppGradients.from(AppColors.rose),
                            color:
                                disabled ? AppColors.mutedDark.op(0.18) : null,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            l10n.t('vote'),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: disabled ? muted : AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    final Map<String, dynamic>? result = ctx.state.round?.result;
    final List<dynamic> votes = (result?['votes'] as List<dynamic>?) ?? <dynamic>[];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      children: <Widget>[
        Text(
          '${result?['body'] ?? ''}',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14.5,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: muted),
        ),
        const SizedBox(height: 12),
        FadeInUp(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: AppGradients.gold,
              borderRadius: BorderRadius.circular(100),
              boxShadow:
                  AppTheme.glow(AppColors.gold, opacity: 0.34, blur: 24, y: 10),
            ),
            child: Text(
              '🏆 ${result?['winner_nickname'] ?? '—'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.espresso,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        ...List<Widget>.generate(votes.length, (int i) {
          final Map<String, dynamic> v =
              Map<String, dynamic>.from(votes[i] as Map<dynamic, dynamic>);
          final int count = ((v['count'] ?? 0) as num).toInt();

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FadeInUp(
              delay: Duration(milliseconds: 40 * (i < 8 ? i : 8)),
              offset: 10,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.white.op(0.05)
                      : AppColors.white.op(0.64),
                  borderRadius: BorderRadius.circular(AppTheme.rMd),
                  border: Border.all(
                      color: (isDark ? AppColors.white : AppColors.coffee)
                          .op(0.10)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${v['nickname'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: ink),
                      ),
                    ),
                    GlassPill(
                      dense: true,
                      icon: Icons.how_to_vote_rounded,
                      label: '$count ${l10n.t('vote')}',
                      color: AppColors.rose,
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
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: FadeInUp(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w800, color: muted),
              ),
              const SizedBox(height: 8),
              Text(
                big,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 22,
                  height: 1.4,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
              if (body.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                GlassPill(label: body, color: AppColors.gold),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
