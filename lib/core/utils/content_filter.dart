/// فلترة أولية على الجهاز قبل الإرسال — الفلترة النهائية دائمًا على الخادم.
///
/// الهدف هنا تجربة مستخدم أسرع (رسالة فورية) وليس الأمان؛ الأمان في
/// دوال قاعدة البيانات `send_message` و `submit_answer`.
class ContentFilter {
  const ContentFilter._();

  static final RegExp _link = RegExp(
    r'(https?:\/\/|www\.|t\.me\/|wa\.me\/|[a-z0-9-]+\.(com|net|org|xyz|ru|top|link|click|info)(\/|\s|$))',
    caseSensitive: false,
  );

  static const List<String> _blocked = <String>[
    'كلب', 'حمار', 'غبي', 'حقير', 'قذر', 'خنزير', 'تافه', 'يلعن',
    'idiot', 'stupid', 'moron',
  ];

  /// توحيد الحروف العربية لتفادي الالتفاف على الفلتر.
  static String normalizeArabic(String input) {
    const Map<String, String> map = <String, String>{
      'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ى': 'ي', 'ؤ': 'و', 'ئ': 'ي', 'ة': 'ه',
    };
    String out = input.replaceAll(RegExp(r'[\u064B-\u0652\u0640]'), '');
    map.forEach((String k, String v) => out = out.replaceAll(k, v));
    return out.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool containsLink(String text) => _link.hasMatch(text);

  static bool containsBannedWord(String text) {
    final String normalized = normalizeArabic(text);
    return _blocked.any((String w) => normalized.contains(normalizeArabic(w)));
  }

  /// null يعني نص مقبول، وإلا مفتاح رسالة الخطأ.
  static String? validate(String text, {int maxLength = 300}) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return 'BAD_LENGTH';
    if (trimmed.length > maxLength) return 'BAD_LENGTH';
    if (containsLink(trimmed)) return 'LINKS_NOT_ALLOWED';
    if (containsBannedWord(trimmed)) return 'BLOCKED_CONTENT';
    return null;
  }
}
