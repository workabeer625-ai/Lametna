import '../constants/app_constants.dart';

/// تحققات مشتركة بين شاشات الإدخال.
class Validators {
  const Validators._();

  static final RegExp _email = RegExp(r'^[\w\.\-\+]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
  static final RegExp _roomCode = RegExp(r'^[A-Z0-9]{6}$');

  static bool isEmail(String value) => _email.hasMatch(value.trim());

  static bool isStrongEnoughPassword(String value) => value.length >= 8;

  static bool isRoomCode(String value) =>
      _roomCode.hasMatch(value.trim().toUpperCase());

  static bool isNickname(String value) {
    final String v = value.trim();
    return v.length >= AppConstants.minNicknameLength &&
        v.length <= AppConstants.maxNicknameLength;
  }

  static String normalizeRoomCode(String value) =>
      value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}
