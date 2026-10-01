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

  /// رابط تحميل التطبيق — يظهر داخل رسالة الدعوة إن ضُبط.
  /// اضبطه في env.json: "APP_DOWNLOAD_URL": "https://..."
  static const String downloadUrl =
      String.fromEnvironment('APP_DOWNLOAD_URL', defaultValue: '');

  static bool get hasDownloadUrl => downloadUrl.startsWith('http');

  /// أصل روابط الدعوة القابلة للنقر (صفحة الهبوط في مجلد landing/).
  /// اضبطه في env.json: "APP_LINK_BASE": "https://lametna.vercel.app"
  /// الرابط الناتج: https://lametna.vercel.app/r/AB12CD
  static const String linkBase =
      String.fromEnvironment('APP_LINK_BASE', defaultValue: '');

  static bool get hasLinkBase => linkBase.startsWith('http');

  /// رابط دعوة غرفة جاهز للمشاركة، أو سلسلة فارغة إن لم يُضبط APP_LINK_BASE.
  static String roomLink(String code) {
    if (!hasLinkBase) return '';
    final String base = linkBase.endsWith('/')
        ? linkBase.substring(0, linkBase.length - 1)
        : linkBase;
    return '$base/r/$code';
  }

  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') && supabaseAnonKey.length > 20;

  static bool get isProduction => appEnv == 'prod';

  /// رسالة واضحة عند نسيان ضبط المتغيرات بدل انهيار غامض.
  static String get missingConfigMessage =>
      'لم يتم ضبط SUPABASE_URL / SUPABASE_ANON_KEY.\n'
      'شغّل التطبيق بـ --dart-define-from-file=env.json (انظر .env.example).';
}
