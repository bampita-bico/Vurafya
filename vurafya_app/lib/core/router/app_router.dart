import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/nutrition/screens/nutrition_screen.dart';
import '../../features/medical/screens/medical_screen.dart';
import '../../features/pharmacy/screens/pharmacy_screen.dart';
import '../../features/barter/screens/barter_screen.dart';
import '../../features/labor/screens/labor_screen.dart';
import '../../features/game/screens/game_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final profileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final loading = profileAsync.isLoading;
      final loggedIn = profileAsync.valueOrNull != null;
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (loading) return null;
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (_, s) => _fade(s, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (_, s) => _fade(s, const RegisterScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, s) => _fade(s, const HomeScreen()),
          ),
          GoRoute(
            path: '/nutrition',
            pageBuilder: (_, s) => _fade(s, const NutritionScreen()),
          ),
          GoRoute(
            path: '/medical',
            pageBuilder: (_, s) => _fade(s, const MedicalScreen()),
          ),
          GoRoute(
            path: '/pharmacy',
            pageBuilder: (_, s) => _fade(s, const PharmacyScreen()),
          ),
          GoRoute(
            path: '/barter',
            pageBuilder: (_, s) => _fade(s, const BarterScreen()),
          ),
          GoRoute(
            path: '/labor',
            pageBuilder: (_, s) => _fade(s, const LaborScreen()),
          ),
          GoRoute(
            path: '/game',
            pageBuilder: (_, s) => _fade(s, const GameScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, s) => _fade(s, const ProfileScreen()),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
