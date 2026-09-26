import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lametna/app/localization/app_localizations.dart';
import 'package:lametna/app/theme/app_theme.dart';
import 'package:lametna/core/utils/server_clock.dart';
import 'package:lametna/core/widgets/app_avatar.dart';
import 'package:lametna/core/widgets/countdown_bar.dart';
import 'package:lametna/core/widgets/state_views.dart';
import 'package:lametna/features/auth/presentation/splash_screen.dart';
import 'package:lametna/providers/core_providers.dart';

Widget wrap(Widget child, {String locale = 'ar', List<Override> overrides = const <Override>[]}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: Locale(locale),
      theme: AppTheme.light(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('شاشة البداية تعرض الاسم والشعار', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const SplashScreen()));
    await tester.pump();
    expect(find.text('لمّتنا'), findsOneWidget);
    expect(find.text('لمّتنا تجمعنا… واللعبة تبدأ هنا'), findsOneWidget);
  });

  testWidgets('واجهة العربية تكون RTL والإنجليزية LTR', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      Builder(builder: (BuildContext context) => Text(context.l10n.t('home'))),
    ));
    await tester.pump();
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('الرئيسية'))), TextDirection.rtl);

    await tester.pumpWidget(wrap(
      Builder(builder: (BuildContext context) => Text(context.l10n.t('home'))),
      locale: 'en',
    ));
    await tester.pump();
    expect(find.text('Home'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('Home'))), TextDirection.ltr);
  });

  testWidgets('الصورة الرمزية تسقط إلى رمز تعبيري عند غياب الملف',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const AppAvatar(avatarKey: 'does_not_exist')));
    await tester.pump();
    expect(find.byType(AppAvatar), findsOneWidget);
  });

  testWidgets('المؤقت يعرض الوقت المتبقي بحسب ساعة الخادم',
      (WidgetTester tester) async {
    final DateTime endsAt = DateTime.now().toUtc().add(const Duration(seconds: 45));
    await tester.pumpWidget(wrap(
      CountdownBar(endsAt: endsAt, totalSeconds: 60, label: 'الجولة 1'),
      overrides: <Override>[
        serverClockProvider.overrideWithValue(ServerClock.withOffset(Duration.zero)),
      ],
    ));
    await tester.pump();
    expect(find.textContaining('00:4'), findsOneWidget);
    expect(find.text('الجولة 1'), findsOneWidget);
  });

  testWidgets('المؤقت ينتهي فورًا إذا كانت ساعة الخادم متقدمة',
      (WidgetTester tester) async {
    final DateTime endsAt = DateTime.now().toUtc().add(const Duration(seconds: 20));
    await tester.pumpWidget(wrap(
      CountdownBar(endsAt: endsAt, totalSeconds: 60),
      overrides: <Override>[
        serverClockProvider
            .overrideWithValue(ServerClock.withOffset(const Duration(minutes: 5))),
      ],
    ));
    await tester.pump();
    expect(find.text('00:00'), findsOneWidget);
  });

  testWidgets('ErrorView يترجم كود الخطأ إلى رسالة عربية',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(ErrorView(error: Exception('ROOM_FULL'))));
    await tester.pump();
    expect(find.text('حدث خطأ'), findsOneWidget);
    expect(find.text('الغرفة ممتلئة.'), findsOneWidget);
  });

  testWidgets('EmptyView يعرض رسالة مخصصة', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const EmptyView(message: 'لا توجد غرف')));
    await tester.pump();
    expect(find.text('لا توجد غرف'), findsOneWidget);
  });
}
