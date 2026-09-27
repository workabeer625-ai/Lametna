import 'package:flutter/material.dart';

/// Shared page transitions so navigation feels consistent everywhere.
class Nav {
  const Nav._();

  static Route<T> route<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 460),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext _, Animation<double> __, Animation<double> ___) => page,
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondary,
        Widget child,
      ) {
        final Animation<double> curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final Animation<double> out = CurvedAnimation(
          parent: secondary,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.045),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
              child: FadeTransition(
                opacity: Tween<double>(begin: 1, end: 0.35).animate(out),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(route<T>(page));
  }

  static Future<T?> replace<T>(BuildContext context, Widget page) {
    return Navigator.of(context).pushReplacement<T, dynamic>(route<T>(page));
  }
}
