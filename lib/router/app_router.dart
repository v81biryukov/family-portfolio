import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/assets_screen.dart';
import '../screens/add_asset_screen.dart';
import '../screens/edit_asset_screen.dart';
import '../screens/exchange_rates_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/auth_callback_screen.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

// Router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  
  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == Routes.login;
      final isAuthCallback = state.matchedLocation == Routes.authCallback;
      final isSplash = state.matchedLocation == Routes.splash;
      
      // Allow splash and auth callback without authentication
      if (isSplash || isAuthCallback) return null;
      
      // Redirect to login if not authenticated
      if (!isAuthenticated && !isLoggingIn) {
        return Routes.login;
      }
      
      // Redirect to dashboard if authenticated and trying to access login
      if (isAuthenticated && isLoggingIn) {
        return Routes.dashboard;
      }
      
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth callback for OAuth
      GoRoute(
        path: Routes.authCallback,
        builder: (context, state) => AuthCallbackScreen(
          code: state.uri.queryParameters['code'],
        ),
      ),
      
      // Login
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Add Asset (outside shell - no bottom nav)
      GoRoute(
        path: Routes.addAsset,
        builder: (context, state) => const AddAssetScreen(),
      ),
      
      // Edit Asset (outside shell - no bottom nav)
      GoRoute(
        path: '${Routes.editAsset}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditAssetScreen(assetId: id);
        },
      ),
      
      // Main shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(
            child: navigationShell,
          );
        },
        branches: [
          // Dashboard branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          
          // Assets branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.assets,
                builder: (context, state) => const AssetsScreen(),
              ),
            ],
          ),
          
          // Exchange Rates branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.exchangeRates,
                builder: (context, state) => const ExchangeRatesScreen(),
              ),
            ],
          ),
          
          // Settings branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.error?.toString() ?? 'Unknown error'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(Routes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
