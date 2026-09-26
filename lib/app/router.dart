import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/language_screen.dart';
import '../features/auth/presentation/profile_setup_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/common/presentation/status_screens.dart';
import '../features/home/presentation/games_list_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/leaderboard/presentation/leaderboard_screen.dart';
import '../features/legal/presentation/legal_screens.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/rooms/presentation/create_room_screen.dart';
import '../features/rooms/presentation/join_room_screen.dart';
import '../features/rooms/presentation/public_rooms_screen.dart';
import '../features/rooms/presentation/room_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// يحوّل Riverpod provider إلى Listenable حتى يعيد GoRouter تقييم redirect.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(settingsProvider, (_, __) => notifyListeners());
  }
}

final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final _RouterRefresh refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: refresh,
    errorBuilder: (_, GoRouterState state) => const NotFoundScreen(),
    redirect: (BuildContext context, GoRouterState state) {
      final bool localeChosen = ref.read(settingsProvider).localeChosen;
      final bool signedIn = ref.read(isSignedInProvider);
      final String path = state.matchedLocation;

      const Set<String> publicPaths = <String>{
        '/', '/language', '/welcome', '/sign-in', '/sign-up',
        '/privacy', '/terms', '/rules', '/no-internet',
      };

      if (path == '/') {
        if (!localeChosen) return '/language';
        return signedIn ? '/home' : '/welcome';
      }
      if (!localeChosen && path != '/language') return '/language';
      if (!signedIn && !publicPaths.contains(path)) return '/welcome';
      if (signedIn && <String>{'/welcome', '/sign-in', '/sign-up'}.contains(path)) {
        return '/home';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/language', builder: (_, __) => const LanguageScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/sign-up', builder: (_, __) => const SignUpScreen()),
      GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/privacy', builder: (_, __) => const PrivacyScreen()),
      GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
      GoRoute(path: '/rules', builder: (_, __) => const RulesScreen()),
      GoRoute(path: '/no-internet', builder: (_, __) => const NoInternetScreen()),
      GoRoute(
        path: '/create-room',
        builder: (_, GoRouterState state) =>
            CreateRoomScreen(initialGameKey: state.uri.queryParameters['game']),
      ),
      GoRoute(
        path: '/join',
        builder: (_, GoRouterState state) =>
            JoinRoomScreen(initialCode: state.uri.queryParameters['code']),
      ),
      GoRoute(
        path: '/public-rooms',
        builder: (_, GoRouterState state) =>
            PublicRoomsScreen(gameKey: state.uri.queryParameters['game']),
      ),
      GoRoute(
        path: '/room/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, GoRouterState state) =>
            RoomScreen(roomId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        builder: (_, __, StatefulNavigationShell shell) => HomeShell(navigationShell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: <RouteBase>[
              GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(path: '/games', builder: (_, __) => const GamesListScreen()),
          ]),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
          ]),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
