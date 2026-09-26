import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lametna/app/localization/app_localizations.dart';
import 'package:lametna/core/storage/local_prefs.dart';
import 'package:lametna/providers/core_providers.dart';
import 'package:lametna/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalPrefs prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await LocalPrefs.create();
  });

  ProviderContainer container() => ProviderContainer(
        overrides: <Override>[localPrefsProvider.overrideWithValue(prefs)],
      );

  test('اللغة الافتراضية عربية ولم تُختر بعد', () {
    final ProviderContainer c = container();
    addTearDown(c.dispose);
    final SettingsState state = c.read(settingsProvider);
    expect(state.locale, 'ar');
    expect(state.localeChosen, isFalse);
  });

  test('تغيير اللغة يُحفظ محليًا ويصبح localeChosen صحيحًا', () async {
    final ProviderContainer c = container();
    addTearDown(c.dispose);
    await c.read(settingsProvider.notifier).setLocale('en');
    expect(c.read(settingsProvider).locale, 'en');
    expect(c.read(settingsProvider).localeChosen, isTrue);
    expect(prefs.locale, 'en');
  });

  test('تغيير الثيم يُحفظ محليًا', () async {
    final ProviderContainer c = container();
    addTearDown(c.dispose);
    await c.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark);
    expect(c.read(settingsProvider).themeMode, ThemeMode.dark);
    expect(prefs.themeMode, 'dark');
  });

  test('التخزين المحلي يحفظ التفضيلات فقط', () async {
    await prefs.setLastNickname('أبو علي');
    await prefs.setLastRoomCode('ABC123');
    expect(prefs.lastNickname, 'أبو علي');
    expect(prefs.lastRoomCode, 'ABC123');
    // لا توجد واجهة أصلًا لحفظ كلمة مرور أو رمز جلسة محليًا
    await prefs.setLastRoomCode(null);
    expect(prefs.lastRoomCode, isNull);
  });

  testWidgets('شاشة اختيار اللغة تعرض الخيارين', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[localPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: <Locale>[Locale('ar'), Locale('en')],
        home: _LanguagePreview(),
      ),
    ));
    await tester.pump();
    expect(find.text('العربية'), findsWidgets);
    expect(find.text('English'), findsWidgets);
  });
}

class _LanguagePreview extends StatelessWidget {
  const _LanguagePreview();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: <Widget>[
            Text(context.l10n.t('arabic')),
            Text(context.l10n.t('english')),
          ],
        ),
      );
}
