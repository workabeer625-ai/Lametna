import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_localizations.dart';
import '../../providers/core_providers.dart';
import '../../services/realtime_service.dart';

/// شريط علوي يظهر عند انقطاع الشبكة أو انقطاع Realtime.
class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key, this.realtimeStatus});

  final RealtimeStatus? realtimeStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool online = ref.watch(isOnlineProvider);
    final bool realtimeDown = realtimeStatus == RealtimeStatus.disconnected ||
        realtimeStatus == RealtimeStatus.error;

    if (online && !realtimeDown) return const SizedBox.shrink();

    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isOffline = !online;
    return Material(
      color: isOffline ? colors.errorContainer : colors.tertiaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 16,
                height: 16,
                child: isOffline
                    ? Icon(Icons.wifi_off, size: 16, color: colors.onErrorContainer)
                    : const CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isOffline
                      ? context.l10n.t('no_internet')
                      : context.l10n.t('reconnecting'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOffline ? colors.onErrorContainer : colors.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
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
