import 'package:shared_preferences/shared_preferences.dart';

/// تخزين محلي غير حسّاس: اللغة، الثيم، آخر اسم مستعار، تفضيلات الواجهة.
/// ⚠️ لا تُخزَّن هنا كلمات مرور ولا رموز جلسات ولا أدوار مافيا.
class LocalPrefs {
  LocalPrefs(this._prefs);

  final SharedPreferences _prefs;

  static const String _kLocale = 'locale';
  static const String _kThemeMode = 'theme_mode';
  static const String _kNickname = 'last_nickname';
  static const String _kAvatar = 'last_avatar';
  static const String _kOnboarded = 'onboarded';
  static const String _kLastRoomCode = 'last_room_code';
  static const String _kNotifications = 'notifications_enabled';

  static Future<LocalPrefs> create() async =>
      LocalPrefs(await SharedPreferences.getInstance());

  String? get locale => _prefs.getString(_kLocale);
  Future<void> setLocale(String value) => _prefs.setString(_kLocale, value);

  String get themeMode => _prefs.getString(_kThemeMode) ?? 'system';
  Future<void> setThemeMode(String value) => _prefs.setString(_kThemeMode, value);

  String? get lastNickname => _prefs.getString(_kNickname);
  Future<void> setLastNickname(String value) => _prefs.setString(_kNickname, value);

  String? get lastAvatar => _prefs.getString(_kAvatar);
  Future<void> setLastAvatar(String value) => _prefs.setString(_kAvatar, value);

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded(bool value) => _prefs.setBool(_kOnboarded, value);

  String? get lastRoomCode => _prefs.getString(_kLastRoomCode);
  Future<void> setLastRoomCode(String? value) => value == null
      ? _prefs.remove(_kLastRoomCode)
      : _prefs.setString(_kLastRoomCode, value);

  bool get notificationsEnabled => _prefs.getBool(_kNotifications) ?? true;
  Future<void> setNotificationsEnabled(bool v) => _prefs.setBool(_kNotifications, v);

  Future<void> clearSessionData() async {
    await _prefs.remove(_kLastRoomCode);
  }
}
