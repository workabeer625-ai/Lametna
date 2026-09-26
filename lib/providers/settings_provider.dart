import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/local_prefs.dart';
import 'core_providers.dart';

@immutable
class SettingsState {
  const SettingsState({
    this.locale = 'ar',
    this.themeMode = ThemeMode.system,
    this.localeChosen = false,
    this.notificationsEnabled = true,
  });

  final String locale;
  final ThemeMode themeMode;
  final bool localeChosen;
  final bool notificationsEnabled;

  bool get isArabic => locale == 'ar';

  SettingsState copyWith({
    String? locale,
    ThemeMode? themeMode,
    bool? localeChosen,
    bool? notificationsEnabled,
  }) =>
      SettingsState(
        locale: locale ?? this.locale,
        themeMode: themeMode ?? this.themeMode,
        localeChosen: localeChosen ?? this.localeChosen,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );
}

ThemeMode _themeModeFrom(String value) => switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

String _themeModeName(ThemeMode mode) => switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final LocalPrefs prefs = ref.watch(localPrefsProvider);
    return SettingsState(
      locale: prefs.locale ?? 'ar',
      themeMode: _themeModeFrom(prefs.themeMode),
      localeChosen: prefs.locale != null,
      notificationsEnabled: prefs.notificationsEnabled,
    );
  }

  Future<void> setLocale(String locale) async {
    await ref.read(localPrefsProvider).setLocale(locale);
    state = state.copyWith(locale: locale, localeChosen: true);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await ref.read(localPrefsProvider).setThemeMode(_themeModeName(mode));
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setNotifications(bool enabled) async {
    await ref.read(localPrefsProvider).setNotificationsEnabled(enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }
}

final NotifierProvider<SettingsController, SettingsState> settingsProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
