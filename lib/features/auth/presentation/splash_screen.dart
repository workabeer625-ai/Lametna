import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// شاشة البداية — تعرض الهوية بينما يقرر الموجّه الوجهة التالية.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppColors.coffee, AppColors.green],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const LametnaLogo(size: 110),
              const SizedBox(height: 24),
              Text(
                AppConstants.appNameAr,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.beige,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  context.l10n.t('slogan'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.gold,
                      ),
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شعار بسيط مرسوم بالكود (لا حاجة لملف صورة كبير).
class LametnaLogo extends StatelessWidget {
  const LametnaLogo({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.beige,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text('☕', style: TextStyle(fontSize: size * 0.5)),
      );
}
