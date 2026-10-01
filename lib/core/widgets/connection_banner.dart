import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../providers/core_providers.dart';
import '../../services/realtime_service.dart';

/// شريط علوي يظهر عند انقطاع الشبكة أو انقطاع Realtime.
///
/// بتصميم كبسولة متدرّجة عائمة بدل الشريط المسطّح القديم.
class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key, this.realtimeStatus});

  final RealtimeStatus? realtimeStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool online = ref.watch(isOnlineProvider);
    final bool realtimeDown = realtimeStatus == RealtimeStatus.disconnected ||
        realtimeStatus == RealtimeStatus.error;

    if (online && !realtimeDown) return const SizedBox.shrink();

    final bool isOffline = !online;
    final Color tone = isOffline ? AppColors.danger : AppColors.amber;

    return SafeArea(
      bottom: false,
      child: AnimatedSlide(
        offset: Offset.zero,
        duration: AppTheme.medium,
        curve: AppTheme.ease,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppGradients.from(tone),
              borderRadius: BorderRadius.circular(100),
              boxShadow: AppTheme.glow(tone, opacity: 0.32, blur: 20, y: 8),
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: isOffline
                      ? const Icon(Icons.wifi_off_rounded,
                          size: 17, color: AppColors.white)
                      : const CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    isOffline
                        ? context.l10n.t('no_internet')
                        : context.l10n.t('reconnecting'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
