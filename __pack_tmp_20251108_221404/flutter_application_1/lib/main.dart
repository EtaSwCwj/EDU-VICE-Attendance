// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'shared/services/auth_state.dart';
import 'shared/theme/app_theme.dart';
import 'app/app_router.dart';

void main() {
  runApp(const EduViceApp());
}

class EduViceApp extends StatelessWidget {
  const EduViceApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 전역 AuthState 주입
    return ChangeNotifierProvider<AuthState>(
      create: (_) => AuthState(),
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final router = AppRouter.create(auth); // go_router 구성(AuthState 연동)

    return MaterialApp.router(
      title: 'EDU-VICE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light, // 프로젝트 기존 테마 사용
      routerConfig: router,
    );
  }
}
