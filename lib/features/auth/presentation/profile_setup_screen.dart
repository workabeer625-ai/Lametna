import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_avatar.dart';
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
    final AsyncValue<Profile?> profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('setup_profile')),
        automaticallyImplyLeading: false,
      ),
      body: profileAsync.when(
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

          final AsyncValue<List<AvatarOption>> avatars = ref.watch(avatarsProvider);
          final AsyncValue<List<Country>> countries = ref.watch(countriesProvider);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Center(child: AppAvatar(avatarKey: _avatarKey, size: 92)),
                const SizedBox(height: 20),
                TextField(
                  controller: _nickname,
                  maxLength: AppConstants.maxNicknameLength,
                  decoration: InputDecoration(
                    labelText: l10n.t('nickname'),
                    hintText: l10n.t('nickname_hint'),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                Text(l10n.t('choose_avatar'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                avatars.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _avatarGridFallback(),
                  data: (List<AvatarOption> list) => _avatarGrid(
                    list.map((AvatarOption a) => a.key).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                countries.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (List<Country> list) => DropdownButtonFormField<String?>(
                    initialValue: _countryCode,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.t('country_optional'),
                      prefixIcon: const Icon(Icons.public),
                    ),
                    items: <DropdownMenuItem<String?>>[
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.t('optional')),
                      ),
                      ...list.map((Country c) => DropdownMenuItem<String?>(
                            value: c.code,
                            child: Text('${c.flagEmoji}  ${c.name(l10n.languageCode)}'),
                          )),
                    ],
                    onChanged: (String? v) => setState(() => _countryCode = v),
                  ),
                ),
                SwitchListTile(
                  value: _showCountry,
                  onChanged: _countryCode == null
                      ? null
                      : (bool v) => setState(() => _showCountry = v),
                  title: Text(l10n.t('show_country')),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : () => _save(profile),
                  child: _busy
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.t('save')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _avatarGridFallback() => _avatarGrid(BuiltInAvatars.keys);

  Widget _avatarGrid(List<String> keys) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: keys.map((String key) {
          final bool selected = key == _avatarKey;
          return GestureDetector(
            onTap: () => setState(() => _avatarKey = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: AppAvatar(avatarKey: key, size: 56),
            ),
          );
        }).toList(),
      );
}
