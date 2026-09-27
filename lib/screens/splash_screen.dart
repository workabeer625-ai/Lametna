import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/brand.dart';
import '../widgets/fade_in.dart';
import 'home_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        Nav.replace(context, const HomeShell());
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                child: BrandMark(size: 132),
              ),
              const SizedBox(height: 26),
              const FadeInUp(
                delay: Duration(milliseconds: 260),
                child: BrandWordmark(fontSize: 46),
              ),
              const SizedBox(height: 8),
              FadeInUp(
                delay: const Duration(milliseconds: 420),
                child: Text(
                  'لمّتكم… تبدأ من هنا',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 44),
              FadeInUp(
                delay: const Duration(milliseconds: 620),
                child: SizedBox(
                  width: 168,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (BuildContext context, Widget? _) {
                        return Stack(
                          children: <Widget>[
                            Container(height: 5, color: Colors.white.op(0.10)),
                            FractionallySizedBox(
                              widthFactor: Curves.easeInOut.transform(_c.value),
                              child: Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                    colors: <Color>[
                                      AppColors.violetLight,
                                      AppColors.cyan,
                                    ],
                                  ),
                                  boxShadow: AppTheme.glow(
                                    AppColors.violet,
                                    opacity: 0.6,
                                    blur: 14,
                                    y: 0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
