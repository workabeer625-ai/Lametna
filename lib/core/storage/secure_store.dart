import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// تخزين مشفّر للبيانات الحساسة فقط (لا كلمات مرور بشكل صريح).
/// Supabase يدير رمز الجلسة بنفسه؛ هذا للاستخدامات الإضافية.
class SecureStore {
  const SecureStore([this._storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  )]);

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<void> delete(String key) => _storage.delete(key: key);
  Future<void> clear() => _storage.deleteAll();
}
