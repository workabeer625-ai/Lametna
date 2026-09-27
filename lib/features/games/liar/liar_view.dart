import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/content_filter.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/design_kit.dart';
import '../../../providers/core_providers.dart';
import '../../../models/models.dart';
import '../engine/game_definition.dart';
import '../shared/game_scaffold.dart';

/// الكذاب بيننا — الكلمة السرية وتوزيعها يتمّان على الخادم.
/// العميل لا يعرف من هو الكذاب إطلاقًا حتى تُحسم الجولة.
class LiarGame extends GameDefinition {
  const LiarGame({this.gameKey = GameKeys.liar});

  /// يسمح لألعاب أخرى بإعادة استخدام المحرك نفسه (مثل «المهنة السرية»).
  final String gameKey;

  @override
  String get key => gameKey;

  @override
  Widget buildRound(BuildContext context, GameRoundContext ctx) => _LiarRoundView(ctx: ctx);

  @override
  Widget? buildRoundResult(BuildContext context, GameRoundContext ctx) {
    final AppLocalizations l10n = context.l10n;
    final Map<String, dynamic>? result = ctx.state.round?.result;
    if (result == null) return null;
    final bool caught = (result['caught'] ?? false) as bool;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color tone = caught ? AppColors.green : AppColors.plum;

    return Stack(
      children: <Widget>[
        Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: FadeInUp(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(caught ? '🎉' : '🎭', style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 14),
                  Text(
                    caught ? l10n.t('liar_caught') : l10n.t('liar_escaped'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FactCard(
                    label: l10n.t('liar_was'),
                    value: ctx.state
                            .playerById(result['liar'] as String?)
                            ?.nickname ??
                        '—',
                    tone: tone,
                    icon: Icons.person_search_rounded,
                  ),
                  const SizedBox(height: 10),
                  _FactCard(
                    label: l10n.t('liar_your_word'),
                    value: '${result['word'] ?? ''}',
                    tone: AppColors.gold,
                    icon: Icons.key_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (caught) const IgnorePointer(child: ConfettiOverlay()),
      ],
    );
  }
}

/// بطاقة معلومة (اللاعب/الكلمة) في نتيجة الجولة.
class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.label,
    required this.value,
    required this.tone,
    required this.icon,
  });

  final String label;
  final String value;
  final Color tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.white.op(0.05) : AppColors.white.op(0.66),
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        border: Border.all(color: tone.op(0.3)),
        boxShadow: AppTheme.glow(tone, opacity: 0.16, blur: 18, y: 6),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppGradients.from(tone),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700, color: muted),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// المهنة السرية — نفس محرك «الكذاب» بمحتوى مختلف (مهن بدل كلمات).
class SecretJobGame extends LiarGame {
  const SecretJobGame() : super(gameKey: GameKeys.secretJob);
}

/// الجاسوس — نفس المحرك: الجميع يعرفون المكان إلا الجاسوس (كلمته فارغة).
class SpyGame extends LiarGame {
  const SpyGame() : super(gameKey: GameKeys.spy);
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    // --- مرحلة الوصف -------------------------------------------------
    if (round.stage == 'describe') {
      if (widget.ctx.state.hasSubmitted) {
        return GameRoundScaffold(
          round: round,
          title: l10n.t('liar'),
          accent: AppColors.plum,
          child: const WaitingForOthers(),
        );
      }
      return GameRoundScaffold(
        round: round,
        title: l10n.t('liar_describe'),
        subtitle: '${l10n.t('cat_object')}: ${round.prompt['category'] ?? ''}',
        accent: AppColors.plum,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          child: Column(
            children: <Widget>[
              // بطاقة الكلمة السرية — تُقلب بالضغط
              FadeInUp(
                child: _SecretWordCard(roundId: round.id, label: l10n.t('liar_your_word')),
              ),
              const SizedBox(height: 18),
              GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: TextField(
                  controller: _controller,
                  maxLength: 120,
                  maxLines: 2,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: ink),
                  decoration: InputDecoration(
                    hintText: l10n.t('liar_describe'),
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
                onTap: _busy ? null : _describe,
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
      accent: AppColors.rose,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: List<Widget>.generate(ballot.length, (int i) {
          final Map<String, dynamic> entry = ballot[i];
          final String userId = '${entry['user_id']}';
          final bool isMe = userId == widget.ctx.myUserId;
          final Color tone = AppColors.forSeed(userId);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FadeInUp(
              delay: Duration(milliseconds: 40 * (i < 8 ? i : 8)),
              offset: 10,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.white.op(0.05)
                      : AppColors.white.op(0.66),
                  borderRadius: BorderRadius.circular(AppTheme.rMd),
                  border: Border.all(
                    color: isMe
                        ? AppColors.gold.op(0.4)
                        : (isDark ? AppColors.white : AppColors.coffee).op(0.10),
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
                      child: AppAvatar(
                        avatarKey:
                            widget.ctx.state.playerById(userId)?.avatarKey,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${entry['nickname']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: ink),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${entry['text'] ?? ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12.5,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                                color: muted),
                          ),
                        ],
                      ),
                    ),
                    if (!isMe) ...<Widget>[
                      const SizedBox(width: 8),
                      Pressable(
                        onTap: widget.ctx.state.hasVoted
                            ? null
                            : () => _vote(userId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: widget.ctx.state.hasVoted
                                ? null
                                : AppGradients.from(AppColors.rose),
                            color: widget.ctx.state.hasVoted
                                ? AppColors.mutedDark.op(0.2)
                                : null,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            l10n.t('vote'),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: widget.ctx.state.hasVoted
                                  ? muted
                                  : AppColors.white,
                            ),
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

/// بطاقة الكلمة السرية — مقلوبة حتى يضغط اللاعب عليها.
class _SecretWordCard extends StatelessWidget {
  const _SecretWordCard({required this.roundId, required this.label});

  final String roundId;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: FlipCard(
        front: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.coffee,
            borderRadius: BorderRadius.circular(AppTheme.rLg),
            boxShadow: AppTheme.glow(AppColors.coffee,
                opacity: 0.3, blur: 24, y: 10),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.touch_app_rounded, size: 34, color: AppColors.white),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
        back: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.gold,
            borderRadius: BorderRadius.circular(AppTheme.rLg),
            boxShadow:
                AppTheme.glow(AppColors.gold, opacity: 0.36, blur: 28, y: 10),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          child: _MyWord(roundId: roundId),
        ),
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
            height: 32,
            width: 32,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: AppColors.espresso),
          );
        }
        final String word = snapshot.data ?? '';
        // في «الجاسوس» تكون كلمة الجاسوس فارغة — نخبره صراحةً بدوره.
        final String shown =
            word.isEmpty ? context.l10n.t('you_are_the_spy') : word;
        return Text(
          shown,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.espresso,
          ),
        );
      },
    );
  }
}
