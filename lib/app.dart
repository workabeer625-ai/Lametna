import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class LametnaApp extends StatefulWidget {
  const LametnaApp({super.key});

  @override
  State<LametnaApp> createState() => _LametnaAppState();
}

class _LametnaAppState extends State<LametnaApp> {
  final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'لمتنا',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
        builder: (BuildContext context, Widget? child) {
          // The whole product is Arabic-first.
          return Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery.withClampedTextScaling(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.2,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
