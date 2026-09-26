import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';
import 'core_providers.dart';

final StreamProvider<AuthState> authStateProvider = StreamProvider<AuthState>((Ref ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final Provider<User?> currentUserProvider = Provider<User?>((Ref ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

final Provider<bool> isSignedInProvider =
    Provider<bool>((Ref ref) => ref.watch(currentUserProvider) != null);

/// ملف المستخدم الحالي — يُعاد تحميله عند تغيّر حالة المصادقة.
class ProfileController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    ref.watch(authStateProvider);
    final User? user = ref.watch(supabaseClientProvider).auth.currentUser;
    if (user == null) return null;
    return ref.read(supabaseServiceProvider).fetchProfile(user.id);
  }

  Future<void> refresh() async {
    state = const AsyncValue<Profile?>.loading();
    state = await AsyncValue.guard(() => ref.read(supabaseServiceProvider).fetchProfile());
  }

  Future<void> save(Profile profile) async {
    final SupabaseService service = ref.read(supabaseServiceProvider);
    state = await AsyncValue.guard(() => service.updateProfile(profile));
  }

  bool get needsSetup {
    final Profile? p = state.valueOrNull;
    if (p == null) return false;
    return p.avatarKey == null || p.nickname.startsWith('ضيف-') || p.nickname.startsWith('لاعب-');
  }
}

final AsyncNotifierProvider<ProfileController, Profile?> profileProvider =
    AsyncNotifierProvider<ProfileController, Profile?>(ProfileController.new);

/// إجراءات المصادقة (تُستخدم من الشاشات).
class AuthActions {
  const AuthActions(this._ref);
  final Ref _ref;

  SupabaseService get _service => _ref.read(supabaseServiceProvider);

  Future<void> signIn(String email, String password) async {
    await _service.signInWithEmail(email: email, password: password);
    await _ref.read(profileProvider.notifier).refresh();
  }

  Future<void> signUp(String email, String password, String nickname, String locale) async {
    await _service.signUpWithEmail(
        email: email, password: password, nickname: nickname, locale: locale);
    await _ref.read(profileProvider.notifier).refresh();
  }

  Future<void> signInAsGuest(String? nickname, String locale) async {
    await _service.signInAsGuest(nickname: nickname, locale: locale);
    await _ref.read(profileProvider.notifier).refresh();
  }

  Future<void> resetPassword(String email) => _service.sendPasswordReset(email);

  Future<void> signOut() async {
    await _service.signOut();
    _ref.invalidate(profileProvider);
  }

  Future<void> deleteAccount() async {
    await _service.deleteAccount();
    await _service.signOut();
    _ref.invalidate(profileProvider);
  }
}

final Provider<AuthActions> authActionsProvider =
    Provider<AuthActions>((Ref ref) => AuthActions(ref));
