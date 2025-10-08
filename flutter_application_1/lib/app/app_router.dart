// 간단 라우터: /login -> /home
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (ctx, st) => const LoginPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (ctx, st) => const _HomePage(),
    ),
  ],
);

class _HomePage extends StatelessWidget {
  const _HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Home (Logged in)')),
    );
  }
}
