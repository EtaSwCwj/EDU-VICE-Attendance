// 간단 라우터: 로그인 가드 포함
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/login_page.dart';
import '../shared/services/auth_state.dart';
import '../shared/models/account.dart';             // Membership 타입
import 'home_shell.dart';                // ← 추가

GoRouter createRouter(AuthState auth) {
  return GoRouter(
    initialLocation: '/login',
    // auth 상태 변경 시 라우터도 새로고침
    refreshListenable: auth,
    redirect: (ctx, state) {
      final signedIn = auth.isSignedIn;
      final loggingIn = state.matchedLocation == '/login';

      if (!signedIn && !loggingIn) return '/login'; // 미로그인 → 로그인으로
      if (signedIn && loggingIn) return '/home';     // 로그인 상태인데 /login 접근 → 홈
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (ctx, st) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (ctx, st) => const HomeShell(),
      ),
    ],
  );
}

class _HomePage extends StatelessWidget {
  const _HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final memberships = auth.user?.memberships ?? const <Membership>[];
    final current = auth.currentMembership;

    return Scaffold(
      appBar: AppBar(
        title: Text('Home — ${auth.user?.name ?? ""}'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthState>().signOut(),
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 학원/역할 선택 드롭다운
            if (memberships.isNotEmpty) Row(
              children: [
                const Text('소속:'),
                const SizedBox(width: 12),
                DropdownButton<Membership>(
                  value: current ?? memberships.first,
                  items: memberships.map((m) {
                    final name = auth.academyName(m.academyId);
                    final label = '$name / ${m.role}';
                    return DropdownMenuItem(
                      value: m,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (m) {
                    if (m != null) context.read<AuthState>().selectMembership(m);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              current == null
                  ? '소속이 없는 사용자입니다.'
                  : '현재: ${auth.academyName(current.academyId)} / ${current.role}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Center(child: Text('Home (Logged in)')),
          ],
        ),
      ),
    );
  }
}


