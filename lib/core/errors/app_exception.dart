/// أخطاء التطبيق مع رسائل مترجمة ومفهومة للمستخدم.
class AppException implements Exception {
  const AppException(this.code, {this.messageAr, this.messageEn, this.cause});

  final String code;
  final String? messageAr;
  final String? messageEn;
  final Object? cause;

  String localized(String locale) =>
      (locale == 'en' ? messageEn ?? messageAr : messageAr ?? messageEn) ?? code;

  @override
  String toString() => 'AppException($code)';
}

class NetworkException extends AppException {
  const NetworkException([Object? cause])
      : super('NETWORK_ERROR',
            messageAr: 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مجددًا.',
            messageEn: 'No internet connection. Check your network and try again.',
            cause: cause);
}
