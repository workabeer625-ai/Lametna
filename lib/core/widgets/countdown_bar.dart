import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color color = remaining.inSeconds <= 10
        ? colors.error
        : (remaining.inSeconds <= 30 ? Colors.orange : colors.primary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(label ?? '', style: Theme.of(context).textTheme.labelLarge),
            Row(
              children: <Widget>[
                Icon(Icons.timer_outlined, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  remaining.mmss,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                      ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: progress, end: progress),
            duration: const Duration(milliseconds: 400),
            builder: (_, double value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ),
      ],
    );
  }
}
