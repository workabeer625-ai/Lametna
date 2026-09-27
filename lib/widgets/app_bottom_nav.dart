import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class NavItem {
  const NavItem({required this.icon, required this.activeIcon, required this.label});
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating frosted navigation bar with a gliding glow indicator.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    required this.accent,
  });

  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.op(0.45),
              blurRadius: 30,
              offset: const Offset(0, 14),
              spreadRadius: -8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white.op(0.07),
                border: Border.all(color: Colors.white.op(0.13)),
              ),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double slot = constraints.maxWidth / items.length;
                  // RTL: the first item sits on the right edge.
                  final double right = index * slot;

                  return Stack(
                    children: <Widget>[
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutBack,
                        right: right,
                        top: 0,
                        bottom: 0,
                        width: slot,
                        child: Center(
                          child: AnimatedContainer(
                            duration: AppTheme.medium,
                            width: slot - 16,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: <Color>[accent.op(0.30), accent.op(0.10)],
                              ),
                              border: Border.all(color: accent.op(0.38)),
                              boxShadow: AppTheme.glow(accent, opacity: 0.35, blur: 20, y: 6),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          for (int i = 0; i < items.length; i++)
                            Expanded(
                              child: _NavButton(
                                item: items[i],
                                selected: i == index,
                                accent: accent,
                                onTap: () {
                                  if (i == index) return;
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
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? Colors.white : AppColors.inkMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedScale(
            scale: selected ? 1.06 : 1.0,
            duration: AppTheme.medium,
            curve: Curves.easeOutBack,
            child: Icon(
              selected ? item.activeIcon : item.icon,
              size: 21,
              color: color,
            ),
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
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}
