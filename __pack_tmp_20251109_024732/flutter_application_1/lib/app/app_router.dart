// lib/app/app_router.dart
import 'package:go_router/go_router.dart';

import '../shared/services/auth_state.dart';
import '../features/auth/login_page.dart';
import '../features/home/teacher_home_shell.dart';
import '../features/home/student_home_shell.dart';
import '../features/home/owner_home_shell.dart';
import '../features/teacher_homework/teacher_homework_page.dart';

/// 역할 가드 & 홈쉘 분리 라우터
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
        // 로그인
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginPage(),
        ),

        // /home → 역할별 전용 홈셸로 분기
        GoRoute(
          path: '/home',
          builder: (_, __) {
            final role = auth.currentMembership?.role ?? '';
            switch (role) {
              case 'teacher':
                return const TeacherHomeShell();
              case 'student':
                return const StudentHomeShell();
              case 'owner':
                return const OwnerHomeShell();
              default:
                // 알 수 없는 역할은 최소 권한(학생) 셸로
                return const StudentHomeShell();
            }
          },
        ),

        // ── 교사 전용 네임스페이스 예시 ──────────────────────────────────
        GoRoute(
          path: '/teacher/homework',
          // 역할 가드: 교사 외 접근 시 자신의 홈으로 회수
          redirect: (_, __) {
            if ((auth.currentMembership?.role ?? '') != 'teacher') {
              return '/home';
            }
            return null;
          },
          builder: (_, __) => const TeacherHomeworkPage(),
        ),

        // 필요 시 /student/*, /owner/* 네임스페이스도 같은 방식으로 확장
      ],
    );
  }
}
