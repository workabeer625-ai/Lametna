/// إعدادات البيئة — تُمرَّر عبر --dart-define أو --dart-define-from-file.
///
/// مثال:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// ⚠️ لا تضع هنا إلا المفتاح العام (anon). مفتاح service_role
/// يبقى داخل Supabase فقط ولا يُشحن مع التطبيق أبدًا.
class Env {
  const Env._();

  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static const String appEnv =
      String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') && supabaseAnonKey.length > 20;

  static bool get isProduction => appEnv == 'prod';

  /// رسالة واضحة عند نسيان ضبط المتغيرات بدل انهيار غامض.
  static String get missingConfigMessage =>
      'لم يتم ضبط SUPABASE_URL / SUPABASE_ANON_KEY.\n'
      'شغّل التطبيق بـ --dart-define-from-file=env.json (انظر .env.example).';
}
