import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/unauthenticated_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'config/web_config.dart';
import 'config/api_config.dart';
import 'services/backend_health_service.dart';
import 'services/version_service.dart';

// Global state for user data
class UserData {
  static String? userName;
  static String? desiredName;
  static Map<String, dynamic>? fullUserData;

  /// Check if user is authenticated
  static bool get isAuthenticated {
    return userName != null && userName!.isNotEmpty;
  }

  /// Clear all user data on logout
  static void logout() {
    userName = null;
    desiredName = null;
    fullUserData = null;
  }
}

/// Widget that verifies backend health before rendering authenticated content
class _AuthenticatedRouteGuard extends StatefulWidget {
  final Widget child;
  final BuildContext context;

  const _AuthenticatedRouteGuard({required this.child, required this.context});

  @override
  State<_AuthenticatedRouteGuard> createState() =>
      _AuthenticatedRouteGuardState();
}

class _AuthenticatedRouteGuardState extends State<_AuthenticatedRouteGuard> {
  late Future<bool> _healthCheckFuture;

  @override
  void initState() {
    super.initState();
    _healthCheckFuture = BackendHealthService.isBackendHealthy();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _healthCheckFuture,
      builder: (context, snapshot) {
        // While checking backend health
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Verifying Backend'),
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Checking backend service...'),
                ],
              ),
            ),
          );
        }

        // Backend health check failed or returned false
        if (snapshot.hasError || snapshot.data == false) {
          // Clear user authentication since backend is down
          UserData.logout();

          // Schedule redirect after this frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              GoRouter.of(context).go('/login');
              BackendHealthService.showBackendUnavailableDialog(context);
            }
          });

          return Scaffold(
            appBar: AppBar(
              title: const Text('Service Unavailable'),
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Backend service is not available'),
                  const SizedBox(height: 8),
                  const Text('Please try again later'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      GoRouter.of(context).go('/login');
                    },
                    child: const Text('Return to Login'),
                  ),
                ],
              ),
            ),
          );
        }

        // Backend is healthy, render the child
        return widget.child;
      },
    );
  }
}

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Flutter web for clean URLs (removes # from URLs)
  configureWebApp();

  // Check for app updates before starting
  final needsUpdate = await VersionService.checkForUpdates(
    apiBaseUrl: ApiConfig.baseUrl,
    forceCheck: true,
  );

  // If update detected, the page will reload automatically
  if (needsUpdate) {
    await VersionService.refreshPage();
    return;
  }

  // No update needed, proceed with app startup
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        // Routes that don't require authentication
        final publicRoutes = [
          '/login',
          '/forgot-password',
          '/reset-password',
          '/unauthenticated',
        ];
        final isPublicRoute = publicRoutes.contains(state.matchedLocation);

        // Allow access to public routes regardless of auth status
        if (isPublicRoute) {
          return null;
        }

        // If user is not authenticated, redirect to unauthenticated page
        if (!UserData.isAuthenticated) {
          return '/unauthenticated';
        }

        // User is authenticated, allow navigation to protected routes
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/pending-approval',
          builder: (context, state) {
            // PROTECTED ROUTE: Requires authentication
            if (!UserData.isAuthenticated) {
              return const UnauthenticatedScreen();
            }
            return _AuthenticatedRouteGuard(
              context: context,
              child: PendingApprovalScreen(userName: UserData.userName),
            );
          },
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            // PROTECTED ROUTE: Requires authentication
            if (!UserData.isAuthenticated) {
              return const UnauthenticatedScreen();
            }
            return _AuthenticatedRouteGuard(
              context: context,
              child: HomeScreen(
                userName: UserData.userName,
                desiredName: UserData.desiredName,
              ),
            );
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) {
            // PROTECTED ROUTE: Requires authentication
            if (!UserData.isAuthenticated) {
              return const UnauthenticatedScreen();
            }
            return _AuthenticatedRouteGuard(
              context: context,
              child: const ProfileScreen(),
            );
          },
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final token = state.uri.queryParameters['token'];
            return ResetPasswordScreen(token: token);
          },
        ),
        GoRoute(
          path: '/unauthenticated',
          builder: (context, state) => const UnauthenticatedScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Learn by Doing v1',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20), // Forest green
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
      ),
      routerConfig: router,
    );
  }
}
