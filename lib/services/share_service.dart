import 'package:flutter/services.dart';

/// مشاركة نص عبر ورقة المشاركة الأصلية في النظام (واتساب، تيليجرام، أي تطبيق).
///
/// تستعمل قناة طرق خفيفة مُنفَّذة في `MainActivity.kt` بدل حزمة خارجية،
/// وترجع `false` إن لم تكن متاحة (مثلًا على iOS أو سطح المكتب) ليستعمل
/// المتصل بديلًا مثل النسخ إلى الحافظة.
class ShareService {
  const ShareService._();

  static const MethodChannel _channel = MethodChannel('app.lametna/share');

  /// يفتح ورقة المشاركة. `true` إن فُتحت فعلًا.
  static Future<bool> shareText(String text, {String? title}) async {
    if (text.trim().isEmpty) return false;
    try {
      final bool? ok = await _channel.invokeMethod<bool>(
        'shareText',
        <String, dynamic>{'text': text, 'title': title},
      );
      return ok ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
