// lib/app/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/services/auth_state.dart';
import '../features/auth/login_page.dart';
import '../features/home/dashboard_pages.dart';
import '../features/home/teacher_home_shell.dart';
import '../features/teacher_homework/teacher_homework_page.dart';

/// go_router를 AuthState에 연결해서:
/// - 미로그인 → /login
/// - 로그인하면 → /home (역할별 진입)
/// - 교사용 과제 화면: /teacher/homework (탭 내부에서도 접근)
class AppRouter {
  static GoRouter create(AuthState auth) {
    return GoRouter(
      debugLogDiagnostics: false,
      initialLocation: '/login',
      refreshListenable: auth, // 로그인/로그아웃 시 라우터 갱신
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
            final role = auth.currentMembership?.role; // 'teacher' | 'owner' | 'student' 등
            switch (role) {
              case 'teacher':
                return const TeacherHomeShell();        // 교사용 홈(탭 포함)
              case 'owner':
                return const OwnerDashboardPage();      // 원장 대시보드(스텁)
              case 'student':
                // 학생 홈이 별도 클래스가 없으니, 우선 대시보드로 연결(필요시 학생 홈으로 교체)
                return const TeacherHomeShell();        // 임시: 학생도 동일 쉘 사용
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
