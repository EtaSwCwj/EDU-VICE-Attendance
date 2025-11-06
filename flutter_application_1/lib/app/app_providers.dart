// lib/app/app_providers.dart
//
// 전역 Provider 트리 (Auth + Subjects + Assignments + Progress)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ── Auth ───────────────────────────────────────────────
import '../shared/services/auth_state.dart';

// ── Subjects ───────────────────────────────────────────
import '../features/subjects/subjects_repository.dart';
import '../features/subjects/local_subjects_repository.dart';
import '../features/subjects/subjects_provider.dart';

// ── Assignments ────────────────────────────────────────
import '../features/assignments/assignments_repository.dart';
import '../features/assignments/local_assignments_repository.dart';
import '../features/assignments/assignments_provider.dart';

// ── Progress (진도 타임라인) ────────────────────────────
import '../features/progress/progress_repository.dart';
import '../features/progress/local_progress_repository.dart';
import '../features/progress/progress_provider.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 현재는 모두 로컬(mock) 리포지토리로 주입
    final SubjectsRepository subjectsRepo = LocalSubjectsRepository();
    final AssignmentsRepository assignmentsRepo = LocalAssignmentsRepository();
    final ProgressRepository progressRepo = LocalProgressRepository();

    return MultiProvider(
      providers: [
        // Auth
        ChangeNotifierProvider<AuthState>(create: (_) => AuthState()),

        // Subjects
        Provider<SubjectsRepository>.value(value: subjectsRepo),
        ChangeNotifierProvider<SubjectsProvider>(
          create: (ctx) => SubjectsProvider(ctx.read<SubjectsRepository>()),
        ),

        // Assignments
        Provider<AssignmentsRepository>.value(value: assignmentsRepo),
        ChangeNotifierProvider<AssignmentsProvider>(
          create: (ctx) => AssignmentsProvider(ctx.read<AssignmentsRepository>()),
        ),

        // Progress
        Provider<ProgressRepository>.value(value: progressRepo),
        ChangeNotifierProvider<ProgressProvider>(
          create: (ctx) => ProgressProvider(ctx.read<ProgressRepository>()),
        ),
      ],
      child: child,
    );
  }
}
