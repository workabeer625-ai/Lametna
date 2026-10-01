import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../providers/core_providers.dart';
import '../extensions/duration_ext.dart';
import '../utils/server_clock.dart';

/// مؤقت الجولة — يعتمد على `ends_at` القادم من الخادم وعلى فارق
/// ساعة الخادم، ولا يثق بساعة الجهاز إطلاقًا.
class CountdownBar extends ConsumerWidget {
  const CountdownBar({
    super.key,
    required this.endsAt,
    required this.totalSeconds,
    this.label,
  });

  final DateTime endsAt;
  final int totalSeconds;
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(tickerProvider);
    final ServerClock clock = ref.watch(serverClockProvider);
    final Duration remaining = clock.remaining(endsAt);
    final double progress = totalSeconds <= 0
        ? 0
        : (remaining.inMilliseconds / (totalSeconds * 1000)).clamp(0.0, 1.0);

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? AppColors.inkLight : AppColors.inkDark;
    final bool urgent = remaining.inSeconds <= 10;
    final Color color = urgent
        ? AppColors.danger
        : (remaining.inSeconds <= 30 ? AppColors.amber : AppColors.green);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.white.op(0.05) : AppColors.white.op(0.62),
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        border:
            Border.all(color: (isDark ? AppColors.white : AppColors.coffee).op(0.10)),
        boxShadow: urgent ? AppTheme.glow(color, opacity: 0.26, blur: 20, y: 6) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  label ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(urgent ? Icons.timer_rounded : Icons.timer_outlined,
                      size: 16, color: color),
                  const SizedBox(width: 5),
                  Text(
                    remaining.mmss,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: color,
                      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: progress, end: progress),
              duration: const Duration(milliseconds: 400),
              builder: (_, double value, __) => Stack(
                children: <Widget>[
                  Container(height: 9, color: color.op(0.14)),
                  FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(
                      height: 9,
                      decoration: BoxDecoration(
                        gradient: AppGradients.from(color),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
