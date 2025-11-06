// lib/app/app_router.dart
import 'package:go_router/go_router.dart';

import '../shared/services/auth_state.dart';
import '../features/auth/login_page.dart';
import '../features/home/dashboard_pages.dart';
import '../features/home/teacher_home_shell.dart';
import '../features/teacher_homework/teacher_homework_page.dart';

class AppRouter {
  static GoRouter create(AuthState auth) {
    return GoRouter(
      debugLogDiagnostics: false,
      initialLocation: '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        final signedIn = auth.isSignedIn;
        final atLogin = state.matchedLocation == '/login';
        if (!signedIn && !atLogin) return '/login';
        if (signedIn && atLogin) return '/home';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginPage(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) {
            final role = auth.currentMembership?.role;
            switch (role) {
              case 'teacher':
                return const TeacherHomeShell();
              case 'owner':
                return const OwnerDashboardPage();
              case 'student':
                return const TeacherHomeShell(); // 임시
              default:
                return const TeacherHomeShell();
            }
          },
        ),
        GoRoute(
          path: '/teacher/homework',
          builder: (_, __) => const TeacherHomeworkPage(),
        ),
      ],
    );
  }
}
