import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/connection_banner.dart';

/// هيكل التنقل السفلي — شريط زجاجي عائم بمؤشّر متوهّج.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    final List<_NavSpec> items = <_NavSpec>[
      _NavSpec(Icons.home_outlined, Icons.home_rounded, l10n.t('home')),
      _NavSpec(Icons.sports_esports_outlined, Icons.sports_esports_rounded,
          l10n.t('games')),
      _NavSpec(Icons.leaderboard_outlined, Icons.leaderboard_rounded,
          l10n.t('leaderboard')),
      _NavSpec(Icons.person_outline_rounded, Icons.person_rounded,
          l10n.t('profile')),
    ];

    return Scaffold(
      body: Column(
        children: <Widget>[
          const ConnectionBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: _GlassNavBar(
        items: items,
        index: navigationShell.currentIndex,
        onChanged: (int index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.items,
    required this.index,
    required this.onChanged,
  });

  final List<_NavSpec> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color accent = theme.colorScheme.primary;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppTheme.lift(isDark),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: isDark
                      ? Colors.white.op(0.06)
                      : AppColors.white.op(0.82),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.op(0.12)
                        : AppColors.coffee.op(0.08),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints c) {
                    final double slot = c.maxWidth / items.length;
                    final double offset = index * slot;

                    return Stack(
                      children: <Widget>[
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutBack,
                          right: isRtl ? offset : null,
                          left: isRtl ? null : offset,
                          top: 0,
                          bottom: 0,
                          width: slot,
                          child: Center(
                            child: Container(
                              width: slot - 14,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: <Color>[
                                    accent.op(isDark ? 0.28 : 0.16),
                                    accent.op(isDark ? 0.10 : 0.06),
                                  ],
                                ),
                                border: Border.all(color: accent.op(0.32)),
                                boxShadow: AppTheme.glow(accent,
                                    opacity: 0.25, blur: 18, y: 6),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            for (int i = 0; i < items.length; i++)
                              Expanded(
                                child: _NavButton(
                                  spec: items[i],
                                  selected: i == index,
                                  accent: accent,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    onChanged(i);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.spec,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = selected
        ? accent
        : (theme.brightness == Brightness.dark
            ? AppColors.mutedLight
            : AppColors.mutedDark);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedScale(
            scale: selected ? 1.08 : 1.0,
            duration: AppTheme.medium,
            curve: Curves.easeOutBack,
            child: Icon(selected ? spec.activeIcon : spec.icon, size: 22, color: color),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: AppTheme.fast,
            style: TextStyle(
              fontFamily: AppTheme.fontBody,
              fontSize: selected ? 11 : 10.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
              height: 1.1,
            ),
            child: Text(spec.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
