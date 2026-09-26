import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

/// يحوّل أخطاء Postgres/Supabase إلى رسائل عربية/إنجليزية واضحة.
///
/// أكواد الأخطاء تُرفع من دوال قاعدة البيانات بصيغة `raise exception 'CODE'`.
class ErrorMapper {
  const ErrorMapper._();

  static const Map<String, List<String>> _messages = <String, List<String>>{
    'AUTH_REQUIRED': ['يجب تسجيل الدخول أولًا.', 'You need to sign in first.'],
    'USER_BANNED': ['حسابك محظور من استخدام الغرف.', 'Your account is banned.'],
    'GAME_NOT_FOUND': ['اللعبة غير متاحة.', 'Game not available.'],
    'TOO_MANY_ROOMS': ['لديك غرفتان مفتوحتان بالفعل. أغلق واحدة أولًا.',
                       'You already host 2 open rooms. Close one first.'],
    'ROOM_NOT_FOUND': ['لا توجد غرفة بهذا الرمز.', 'No room with this code.'],
    'ROOM_CLOSED': ['هذه الغرفة مغلقة.', 'This room is closed.'],
    'ROOM_FULL': ['الغرفة ممتلئة.', 'The room is full.'],
    'ROOM_BANNED': ['أنت محظور من هذه الغرفة.', 'You are banned from this room.'],
    'WRONG_PASSWORD': ['كلمة مرور الغرفة غير صحيحة.', 'Wrong room password.'],
    'GAME_IN_PROGRESS': ['المباراة بدأت — يمكنك الدخول كمتفرج.',
                         'The match already started — you can join as a spectator.'],
    'NOT_HOST': ['هذا الإجراء للمضيف فقط.', 'Host only action.'],
    'NOT_A_MEMBER': ['لست عضوًا في هذه الغرفة.', 'You are not in this room.'],
    'NOT_ENOUGH_PLAYERS': ['عدد اللاعبين غير كافٍ لبدء المباراة.',
                           'Not enough players to start.'],
    'PLAYERS_NOT_READY': ['بعض اللاعبين غير جاهزين.', 'Some players are not ready.'],
    'ALREADY_STARTED': ['المباراة بدأت بالفعل.', 'The match already started.'],
    'ALREADY_SUBMITTED': ['لقد أرسلت إجابتك بالفعل.', 'You already submitted.'],
    'TIME_OVER': ['انتهى الوقت.', 'Time is over.'],
    'ROUND_CLOSED': ['انتهت الجولة.', 'The round is over.'],
    'NOT_ALIVE': ['لا يمكنك اللعب بعد خروجك.', 'You are out of this match.'],
    'DEAD_CANNOT_VOTE': ['اللاعب الخارج لا يصوّت.', 'Eliminated players cannot vote.'],
    'DEAD_CANNOT_ACT': ['اللاعب الخارج لا ينفذ أفعالًا.', 'Eliminated players cannot act.'],
    'DEAD_CANNOT_SPEAK': ['اللاعب الخارج لا يكتب في الدردشة العامة.',
                          'Eliminated players cannot use public chat.'],
    'CANNOT_VOTE_SELF': ['لا يمكنك التصويت على نفسك.', 'You cannot vote for yourself.'],
    'ACTION_NOT_ALLOWED': ['هذا الفعل غير مسموح لدورك.', 'Your role cannot do that.'],
    'ACTION_ALREADY_SUBMITTED': ['نفذت فعلك لهذه الليلة.', 'You already acted tonight.'],
    'TARGET_NOT_ALIVE': ['الهدف غير موجود في اللعبة.', 'Target is not alive.'],
    'RATE_LIMITED': ['أرسلت رسائل كثيرة. انتظر قليلًا.', 'Too many messages. Slow down.'],
    'MUTED': ['تم كتمك في هذه الغرفة.', 'You are muted in this room.'],
    'BLOCKED_CONTENT': ['الرسالة تحتوي على كلمات ممنوعة.', 'Message contains banned words.'],
    'LINKS_NOT_ALLOWED': ['الروابط ممنوعة في الدردشة.', 'Links are not allowed.'],
    'BAD_LENGTH': ['طول النص غير مناسب.', 'Invalid text length.'],
    'ANSWER_TOO_LONG': ['الإجابة طويلة جدًا.', 'Answer is too long.'],
    'NO_CONTENT_FOR_GAME': ['لا يوجد محتوى كافٍ لهذه اللعبة بعد.',
                            'Not enough content for this game yet.'],
    'FORBIDDEN': ['ليس لديك صلاحية.', 'You are not allowed to do that.'],
  };

  static AppException map(Object error) {
    if (error is AppException) return error;
    if (error is SocketException) return NetworkException(error);

    if (error is AuthException) {
      final String m = error.message.toLowerCase();
      if (m.contains('invalid login')) {
        return const AppException('INVALID_CREDENTIALS',
            messageAr: 'البريد أو كلمة المرور غير صحيحة.',
            messageEn: 'Invalid email or password.');
      }
      if (m.contains('already registered') || m.contains('user already')) {
        return const AppException('EMAIL_TAKEN',
            messageAr: 'هذا البريد مسجل بالفعل.',
            messageEn: 'This email is already registered.');
      }
      return AppException('AUTH_ERROR',
          messageAr: 'تعذر إتمام العملية: ${error.message}',
          messageEn: error.message, cause: error);
    }

    if (error is PostgrestException) {
      final String code = _extractCode(error.message);
      final List<String>? known = _messages[code];
      if (known != null) {
        return AppException(code, messageAr: known[0], messageEn: known[1], cause: error);
      }
      if (error.code == '23505') {
        return const AppException('DUPLICATE',
            messageAr: 'هذه القيمة مستخدمة بالفعل.', messageEn: 'This value already exists.');
      }
      if (error.code == '42501' || error.message.contains('row-level security')) {
        return const AppException('FORBIDDEN',
            messageAr: 'ليس لديك صلاحية لهذا الإجراء.', messageEn: 'You are not allowed.');
      }
      return AppException('SERVER_ERROR',
          messageAr: 'حدث خطأ في الخادم. حاول مرة أخرى.',
          messageEn: 'Server error. Please try again.', cause: error);
    }

    return AppException('UNKNOWN',
        messageAr: 'حدث خطأ غير متوقع.', messageEn: 'Unexpected error.', cause: error);
  }

  /// أكواد الأخطاء تصل مثل: `SOME_CODE` أو مغلفة برسالة Postgres.
  static String _extractCode(String message) {
    final RegExpMatch? m = RegExp(r'\b([A-Z][A-Z0-9_]{3,})\b').firstMatch(message);
    return m?.group(1) ?? message;
  }
}
