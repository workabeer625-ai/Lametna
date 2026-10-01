import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/design_kit.dart';
import '../../../providers/auth_provider.dart';

/// مزايا الحساب الكامل مقارنة بالضيف — تُعرض في ورقة الترقية.
const List<(IconData, String)> _benefitIcons = <(IconData, String)>[
  (Icons.add_circle_outline_rounded, 'benefit_create_rooms'),
  (Icons.emoji_events_outlined, 'benefit_leaderboard'),
  (Icons.restore_rounded, 'benefit_restore'),
  (Icons.devices_rounded, 'benefit_devices'),
];

/// ورقة «أكمل حسابك»: يربط الضيف بريدًا وكلمة مرور بنفس حسابه،
/// فيحتفظ بنقاطه وسجلّه ولا يبدأ من الصفر.
Future<bool> showUpgradeAccountSheet(BuildContext context) async {
  final bool? done = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.espresso.op(0.5),
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: const _UpgradeSheet(),
    ),
  );
  return done ?? false;
}

class _UpgradeSheet extends ConsumerStatefulWidget {
  const _UpgradeSheet();

  @override
  ConsumerState<_UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends ConsumerState<_UpgradeSheet> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  bool get _canSubmit =>
      Validators.isEmail(_email.text.trim()) &&
      Validators.isStrongEnoughPassword(_password.text);

  @override
  void initState() {
    super.initState();
    _email.addListener(_onChanged);
    _password.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _email.removeListener(_onChanged);
    _password.removeListener(_onChanged);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await ref
          .read(authActionsProvider)
          .upgradeGuest(_email.text.trim(), _password.text);
      if (mounted) {
        Navigator.pop(context, true);
        context.showSnack(l10n.t('upgrade_done'));
      }
    } catch (e) {
      if (mounted) {
        context.showSnack(ErrorMapper.map(e).localized(l10n.languageCode),
            error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppTheme.rXl)),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.espresso.op(0.95) : AppColors.cream.op(0.98),
          border: Border(
            top: BorderSide(
                color: (isDark ? AppColors.white : AppColors.coffee).op(0.12)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: AppGradients.gold,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppGradients.green,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppTheme.glow(AppColors.green,
                          opacity: 0.32, blur: 20, y: 8),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        size: 28, color: AppColors.white),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.t('upgrade_title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.t('upgrade_body'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12.5,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      color: muted),
                ),
                const SizedBox(height: 16),

                // ── المزايا ──
                ..._benefitIcons.map(((IconData, String) b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.green.op(0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(b.$1, size: 16, color: AppColors.green),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              l10n.t(b.$2),
                              style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  fontWeight: FontWeight.w700,
                                  color: ink),
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style:
                            TextStyle(color: ink, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: l10n.t('email'),
                          prefixIcon: const Icon(Icons.alternate_email),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        style:
                            TextStyle(color: ink, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: l10n.t('password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          l10n.t('weak_password'),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: muted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: l10n.t('upgrade_cta'),
                  icon: Icons.check_circle_outline_rounded,
                  height: 56,
                  loading: _busy,
                  colors: const <Color>[
                    AppColors.greenLight,
                    AppColors.greenDeep,
                  ],
                  onTap: (_busy || !_canSubmit) ? null : _submit,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed:
                      _busy ? null : () => Navigator.pop(context, false),
                  child: Text(
                    l10n.t('later'),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
