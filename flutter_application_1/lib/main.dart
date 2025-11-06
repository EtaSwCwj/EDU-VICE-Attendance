// lib/main.dart
//
// 루트 엔트리: AppProviders로 감싸고, 로그인 여부에 따라 화면 전환

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app_providers.dart';
import 'app/home_shell.dart';

import 'features/auth/login_page.dart';
import 'shared/services/auth_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const flavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev');

    return AppProviders(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EDU-VICE Attendance',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
        ),
        home: Stack(
          children: [
            _RootByAuth(), // ← 로그인/홈 전환
            if (flavor == 'dev')
              const Positioned(left: 8, top: 8, child: _DevBadge()),
          ],
        ),
      ),
    );
  }
}

class _RootByAuth extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!auth.isSignedIn) {
      return const LoginPage();
    }
    // role 결정: membership의 role 사용(없으면 student로 폴백)
    final role = auth.currentMembership?.role ?? 'student';
    return HomeShell(role: role);
  }
}

class _DevBadge extends StatelessWidget {
  const _DevBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        // withOpacity() deprec → withValues(alpha: …)
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          'FLAVOR: dev',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}
