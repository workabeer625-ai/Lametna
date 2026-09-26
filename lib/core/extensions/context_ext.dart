import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  Size get screen => MediaQuery.sizeOf(this);
  bool get isSmallPhone => MediaQuery.sizeOf(this).width < 360;
  bool get isTablet => MediaQuery.sizeOf(this).width >= 600;
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  void showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(this).colorScheme.error : null,
        duration: const Duration(seconds: 3),
      ));
  }
}
