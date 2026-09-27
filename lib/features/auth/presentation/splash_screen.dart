import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/design_kit.dart';

/// شاشة البداية — تعرض الهوية بينما يقرر الموجّه الوجهة التالية.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        intensity: 1.2,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const FadeInUp(
                offset: 0,
                scaleFrom: 0.7,
                duration: Duration(milliseconds: 900),
                child: LametnaLogo(size: 128),
              ),
              const SizedBox(height: 26),
              FadeInUp(
                delay: const Duration(milliseconds: 220),
                child: BrandWordmark(
                  text: AppConstants.appNameAr,
                  fontSize: 42,
                ),
              ),
              const SizedBox(height: 10),
              FadeInUp(
                delay: const Duration(milliseconds: 360),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    context.l10n.t('slogan'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 44),
              FadeInUp(
                delay: const Duration(milliseconds: 520),
                child: const _GoldPulse(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// مؤشّر تحميل ذهبي نابض بدل الدائرة التقليدية.
class _GoldPulse extends StatefulWidget {
  const _GoldPulse();

  @override
  State<_GoldPulse> createState() => _GoldPulseState();
}

class _GoldPulseState extends State<_GoldPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      height: 12,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int i = 0; i < 3; i++)
                Builder(
                  builder: (BuildContext context) {
                    final double phase = (_c.value + i * 0.22) % 1.0;
                    final double bump =
                        (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
                    return Container(
                      width: 10 + bump * 4,
                      height: 10 + bump * 4,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          AppColors.gold.op(0.35),
                          AppColors.goldLight,
                          bump,
                        ),
                        boxShadow: AppTheme.glow(
                          AppColors.gold,
                          opacity: 0.5 * bump,
                          blur: 14,
                          y: 0,
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

/// شعار «لمّتنا» — فنجان القهوة داخل هالة ذهبية متوهّجة (مرسوم بالكود).
class LametnaLogo extends StatelessWidget {
  const LametnaLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          BrandMark(size: size),
          Container(
            width: size * 0.66,
            height: size * 0.66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isDark
                    ? const <Color>[AppColors.mocha, AppColors.espresso]
                    : const <Color>[AppColors.cream, AppColors.sand],
              ),
              border: Border.all(color: AppColors.gold.op(0.55), width: 1.5),
              boxShadow: AppTheme.glow(AppColors.gold, opacity: 0.35, blur: 26, y: 10),
            ),
            alignment: Alignment.center,
            child: Text('☕', style: TextStyle(fontSize: size * 0.3)),
          ),
        ],
      ),
    );
  }
}
