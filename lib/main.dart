import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/network/env.dart';
import 'core/storage/local_prefs.dart';
import 'features/common/presentation/status_screens.dart';
import 'providers/core_providers.dart';
import 'services/supabase_service.dart';

/// نقطة الدخول.
///
/// البيئة تُمرَّر عند البناء:
///   flutter run --dart-define-from-file=env.json
/// ولا يوجد أي مفتاح سري داخل التطبيق — فقط رابط المشروع والمفتاح العام.
Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // تسجيل أخطاء بسيط بلا خدمة مدفوعة (يمكن لاحقًا وصله بـ Sentry المجاني).
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };

    if (!Env.isConfigured) {
      runApp(const MissingConfigScreen());
      return;
    }

    await SupabaseService.initialize();
    final LocalPrefs prefs = await LocalPrefs.create();

    runApp(
      ProviderScope(
        overrides: <Override>[
          localPrefsProvider.overrideWithValue(prefs),
        ],
        child: const LametnaApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}
