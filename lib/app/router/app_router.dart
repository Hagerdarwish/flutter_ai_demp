import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/meeting_import/presentation/pages/import_meeting_page.dart';
import '../../features/meetings/presentation/pages/meetings_page.dart';
import '../../features/meetings/presentation/pages/meeting_details_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // A ChangeNotifier that pings GoRouter whenever auth state changes.
  final notifier = _AuthChangeNotifier(ref);

  final router = GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(firebaseAuthUserProvider);
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.valueOrNull != null;

      final location = state.uri.path;
      final isSplash = location == RouteNames.splash;
      final isAuthRoute = location == RouteNames.login ||
          location == RouteNames.register ||
          location == RouteNames.forgotPassword;

      if (isSplash) {
        if (isLoading) return null; // Stay on splash while auth resolves
        return isLoggedIn ? RouteNames.home : RouteNames.login;
      }

      if (isLoading) return null;

      if (isLoggedIn && isAuthRoute) return RouteNames.home;
      if (!isLoggedIn && !isAuthRoute) return RouteNames.login;
      return null;
    },
    routes: [
      // Splash — handles its own navigation based on auth state
      GoRoute(
        path: RouteNames.splash,
        builder: (_, __) => const SplashPage(),
      ),

      // Auth
      GoRoute(
        path: RouteNames.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
      ),

      // Main app shell (bottom nav)
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder: (_, __) => const HomePage(),
          ),
          GoRoute(
            path: RouteNames.meetings,
            builder: (_, __) => const MeetingsPage(),
          ),
          GoRoute(
            path: RouteNames.tasks,
            builder: (_, __) => const TasksPage(),
          ),
          GoRoute(
            path: RouteNames.settings,
            builder: (_, __) => const SettingsPage(),
          ),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(
        path: RouteNames.importMeeting,
        builder: (_, __) => const ImportMeetingPage(),
      ),
      GoRoute(
        path: RouteNames.meetingDetails,
        builder: (context, state) {
          final meetingId = state.pathParameters['meetingId']!;
          return MeetingDetailsPage(meetingId: meetingId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );

  ref.onDispose(notifier.dispose);
  return router;
});

/// Bridges Riverpod's auth stream into a [ChangeNotifier] so GoRouter
/// re-evaluates its redirect whenever auth state changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AsyncValue>(firebaseAuthUserProvider, (_, __) {
      notifyListeners();
    });
  }
}

/// Splash page that listens to the Firebase auth stream directly
/// and navigates as soon as auth state is known.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The router's redirect + refreshListenable handles navigation away from
    // splash once auth resolves. Just show the loading UI here.
    ref.watch(firebaseAuthUserProvider); // keep provider alive

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            const Text(
              'MeetFlow AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Meeting Intelligence',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFF4F46E5),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom navigation shell
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    final navItems = [
      (icon: Icons.home_rounded, label: 'Home', path: RouteNames.home),
      (icon: Icons.meeting_room_rounded, label: 'Meetings', path: RouteNames.meetings),
      (icon: Icons.task_alt_rounded, label: 'Tasks', path: RouteNames.tasks),
      (icon: Icons.settings_rounded, label: 'Settings', path: RouteNames.settings),
    ];

    int selectedIndex = navItems.indexWhere((item) => location.startsWith(item.path));
    if (selectedIndex < 0) selectedIndex = 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => context.go(navItems[index].path),
        destinations: navItems
            .map((item) => NavigationDestination(icon: Icon(item.icon), label: item.label))
            .toList(),
      ),
    );
  }
}
