// ============================================================
//  اختبار تكامل — لمّتنا
//
//  يتطلب مشروع Supabase حقيقيًا (مجاني) ومتغيرات البيئة:
//
//   flutter test integration_test/app_test.dart \
//     --dart-define-from-file=env.json
//
//  يغطي: الإقلاع، اختيار اللغة، الدخول كضيف، إعداد الملف،
//  إنشاء غرفة، ظهور رمز الغرفة، ثم المغادرة.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lametna/app/app.dart';
import 'package:lametna/core/network/env.dart';
import 'package:lametna/core/storage/local_prefs.dart';
import 'package:lametna/providers/core_providers.dart';
import 'package:lametna/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!Env.isConfigured) {
      fail('اضبط SUPABASE_URL و SUPABASE_ANON_KEY عبر --dart-define-from-file=env.json');
    }
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await SupabaseService.initialize();
  });

  Future<void> launch(WidgetTester tester) async {
    final LocalPrefs prefs = await LocalPrefs.create();
    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[localPrefsProvider.overrideWithValue(prefs)],
      child: const LametnaApp(),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  testWidgets('المسار الكامل: لغة → ضيف → ملف شخصي → غرفة', (WidgetTester tester) async {
    await launch(tester);

    // 1) اختيار اللغة
    expect(find.text('العربية'), findsWidgets);
    await tester.tap(find.text('العربية').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 2) الدخول كضيف
    expect(find.text('الدخول كضيف'), findsOneWidget);
    await tester.tap(find.text('الدخول كضيف'));
    await tester.pumpAndSettle(const Duration(seconds: 6));

    // 3) إعداد الملف الشخصي
    expect(find.text('إعداد الملف الشخصي'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'لاعب اختبار');
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // 4) الصفحة الرئيسية
    expect(find.text('إنشاء غرفة'), findsWidgets);

    // 5) إنشاء غرفة
    await tester.tap(find.text('إنشاء غرفة').first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.widgetWithText(FilledButton, 'إنشاء غرفة'));
    await tester.pumpAndSettle(const Duration(seconds: 6));

    // 6) رمز الغرفة من 6 خانات ظاهر
    expect(find.text('شارك هذا الرمز مع أصدقائك'), findsOneWidget);

    // 7) المغادرة
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
