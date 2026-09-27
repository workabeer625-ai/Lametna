import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/aurora_background.dart';
import 'catalog_screen.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'settings_screen.dart';

/// Root shell: aurora canvas + floating glass navigation.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final PageController _pages = PageController();
  int _index = 0;

  static const List<NavItem> _items = <NavItem>[
    NavItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'الرئيسية',
    ),
    NavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'الألعاب',
    ),
    NavItem(
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events_rounded,
      label: 'الترتيب',
    ),
    NavItem(
      icon: Icons.tune_outlined,
      activeIcon: Icons.tune_rounded,
      label: 'الإعدادات',
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int i) {
    setState(() => _index = i);
    _pages.animateToPage(
      i,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        colors: <Color>[
          state.accent,
          const Color(0xFF4C1D95),
          const Color(0xFFD946EF),
          const Color(0xFF22D3EE),
        ],
        animate: !state.reduceMotion,
        child: Stack(
          children: <Widget>[
            PageView(
              controller: _pages,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                HomeScreen(onSeeAllGames: () => _go(1)),
                const CatalogScreen(),
                const LeaderboardScreen(),
                const SettingsScreen(),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomNav(
                items: _items,
                index: _index,
                accent: state.accent,
                onChanged: _go,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
