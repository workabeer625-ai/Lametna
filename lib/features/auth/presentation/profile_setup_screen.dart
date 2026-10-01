import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/design_kit.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/catalog_provider.dart';
import '../../../providers/core_providers.dart';

/// إعداد الملف الشخصي: اسم مستعار + صورة رمزية جاهزة + دولة اختيارية.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController _nickname = TextEditingController();
  String? _avatarKey;
  String? _countryCode;
  bool _showCountry = false;
  bool _busy = false;
  bool _initialised = false;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  void _seedFrom(Profile profile) {
    if (_initialised) return;
    _initialised = true;
    final bool autoName = profile.nickname.startsWith('ضيف-') ||
        profile.nickname.startsWith('لاعب-');
    _nickname.text = autoName
        ? (ref.read(localPrefsProvider).lastNickname ?? '')
        : profile.nickname;
    _avatarKey = profile.avatarKey ?? BuiltInAvatars.keys.first;
    _countryCode = profile.countryCode;
    _showCountry = profile.showCountry;
  }

  Future<void> _save(Profile profile) async {
    final AppLocalizations l10n = context.l10n;
    if (!Validators.isNickname(_nickname.text)) {
      context.showSnack(l10n.t('nickname_too_short'), error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(profileProvider.notifier).save(profile.copyWith(
            nickname: _nickname.text.trim(),
            avatarKey: _avatarKey,
            countryCode: _countryCode,
            showCountry: _showCountry && _countryCode != null,
          ));
      await ref.read(localPrefsProvider).setLastNickname(_nickname.text.trim());
      if (_avatarKey != null) {
        await ref.read(localPrefsProvider).setLastAvatar(_avatarKey!);
      }
      if (!mounted) return;
      context.showSnack(l10n.t('profile_saved'));
      context.go('/home');
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final Color muted = isDark ? AppColors.mutedLight : AppColors.mutedDark;

    final AsyncValue<Profile?> profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              ScreenHeader(title: l10n.t('setup_profile')),
              Expanded(
                child: profileAsync.when(
                  loading: () => const LoadingView(),
                  error: (Object e, _) => ErrorView(
                    error: e,
                    onRetry: () => ref.read(profileProvider.notifier).refresh(),
                  ),
                  data: (Profile? profile) {
                    if (profile == null) {
                      return EmptyView(message: l10n.t('sign_in'));
                    }
                    _seedFrom(profile);

                    final AsyncValue<List<AvatarOption>> avatars =
                        ref.watch(avatarsProvider);
                    final AsyncValue<List<Country>> countries =
                        ref.watch(countriesProvider);

                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      children: <Widget>[
                        // ── المعاينة ──────────────────────────
                        FadeInUp(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppGradients.gold,
                                boxShadow: AppTheme.glow(AppColors.gold,
                                    opacity: 0.4, blur: 30, y: 12),
                              ),
                              child: AppAvatar(avatarKey: _avatarKey, size: 96),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ── الاسم ─────────────────────────────
                        FadeInUp(
                          delay: const Duration(milliseconds: 70),
                          child: TextField(
                            controller: _nickname,
                            maxLength: AppConstants.maxNicknameLength,
                            style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              labelText: l10n.t('nickname'),
                              hintText: l10n.t('nickname_hint'),
                              prefixIcon: const Icon(Icons.badge_outlined),
                              counterText: '',
                            ),
                          ),
                        ),

                        // ── الأفاتار ──────────────────────────
                        const SizedBox(height: 20),
                        FadeInUp(
                          delay: const Duration(milliseconds: 120),
                          child: SectionHeader(title: l10n.t('choose_avatar')),
                        ),
                        const SizedBox(height: 12),
                        FadeInUp(
                          delay: const Duration(milliseconds: 160),
                          child: avatars.when(
                            loading: () =>
                                const Center(child: CircularProgressIndicator()),
                            error: (_, __) => _avatarGrid(BuiltInAvatars.keys),
                            data: (List<AvatarOption> list) => _avatarGrid(
                              list.map((AvatarOption a) => a.key).toList(),
                            ),
                          ),
                        ),

                        // ── الدولة ────────────────────────────
                        const SizedBox(height: 22),
                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: countries.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (List<Country> list) => GlassCard(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: _countryCode,
                                  isExpanded: true,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.rSm),
                                  dropdownColor:
                                      isDark ? AppColors.darkCard : AppColors.cream,
                                  icon: Icon(Icons.expand_more_rounded, color: muted),
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontBody,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: ink,
                                  ),
                                  hint: Text(
                                    l10n.t('country_optional'),
                                    style: TextStyle(fontSize: 14, color: muted),
                                  ),
                                  items: <DropdownMenuItem<String?>>[
                                    DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text(l10n.t('optional'),
                                          style: TextStyle(color: muted)),
                                    ),
                                    ...list.map((Country c) =>
                                        DropdownMenuItem<String?>(
                                          value: c.code,
                                          child: Text(
                                              '${c.flagEmoji}  ${c.name(l10n.languageCode)}'),
                                        )),
                                  ],
                                  onChanged: (String? v) =>
                                      setState(() => _countryCode = v),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeInUp(
                          delay: const Duration(milliseconds: 240),
                          child: GlassCard(
                            padding: const EdgeInsets.fromLTRB(16, 6, 10, 6),
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.public_rounded, size: 19, color: muted),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.t('show_country'),
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: ink),
                                  ),
                                ),
                                Switch(
                                  value: _showCountry,
                                  onChanged: _countryCode == null
                                      ? null
                                      : (bool v) => setState(() => _showCountry = v),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),
                        FadeInUp(
                          delay: const Duration(milliseconds: 280),
                          child: GradientButton(
                            label: l10n.t('save'),
                            icon: Icons.check_rounded,
                            height: 58,
                            loading: _busy,
                            onTap: _busy ? null : () => _save(profile),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarGrid(List<String> keys) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: keys.map((String key) {
        final bool selected = key == _avatarKey;
        return Pressable(
          onTap: () => setState(() => _avatarKey = key),
          child: AnimatedContainer(
            duration: AppTheme.fast,
            curve: AppTheme.ease,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: selected ? AppGradients.gold : null,
              color: selected
                  ? null
                  : (isDark ? AppColors.white.op(0.05) : AppColors.white.op(0.5)),
              boxShadow: selected
                  ? AppTheme.glow(AppColors.gold, opacity: 0.35, blur: 18, y: 6)
                  : null,
            ),
            child: AppAvatar(avatarKey: key, size: 56),
          ),
        );
      }).toList(),
    );
  }
}
