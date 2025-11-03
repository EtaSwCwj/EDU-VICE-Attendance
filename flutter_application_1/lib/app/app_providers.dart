// lib/app/app_providers.dart
//
// [20-15] 전역 DI 래퍼: RecordAttendanceUseCase 주입 추가 (UI 연결은 다음 단계)
// 목적:
//  - UI가 직접 Repository에 접근하지 않고 UseCase를 거치도록 준비.
//  - 기존 Repository 주입 구조는 그대로 유지하면서, UseCase만 한 줄로 얹는다.
//
// 히스토리 요약:
//  - [20-0] 파일 추가
//  - [20-1] main.dart 연결
//  - [20-2] app_env.dart 추가
//  - [20-3] 환경 분기(dev/prod)
//  - [20-5] AppFlavor 로깅
//  - [20-7] prod → AWS 스텁 바인딩
//  - [20-11] AWS 스텁에 --dart-define 토글 도입(AWS_MOCK, AWS_DELAY_MS)
//  - [20-13] 실제 주입 클래스/환경 경고 로깅
//  - [20-15] RecordAttendanceUseCase 주입 추가(이 단계)

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../app/app_env.dart'; // currentFlavor
import '../domain/repositories/attendance_repository.dart';
import '../domain/usecases/record_attendance.dart'; // [20-15] 추가
import '../data/local/attendance_local_repository.dart';
import '../data/aws/attendance_remote_repository.dart';

// AWS 스텁의 토글 값 읽기 위해 import (kAwsMock, kAwsDelayMs)
import '../data/aws/attendance_remote_repository.dart' as aws_stub_show;

class AppProviders extends StatelessWidget {
  final Widget child;
  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // 실행 환경 1차 로깅
    debugPrint('✅ AppFlavor = ${currentFlavor.name}');

    final repo = _buildAttendanceRepository();

    // 주입 직전, 구현 타입/환경 경고 로깅
    _logRepositoryBinding(repo);

    return MultiProvider(
      providers: [
        // Repository 주입(이미 사용 중)
        Provider<AttendanceRepository>.value(value: repo),

        // [20-15] UseCase 주입: 위에서 주입된 Repository를 읽어 생성
        Provider<RecordAttendanceUseCase>(
          create: (ctx) =>
              RecordAttendanceUseCase(ctx.read<AttendanceRepository>()),
        ),
      ],
      child: child,
    );
  }
}

void _logRepositoryBinding(AttendanceRepository repo) {
  final typeName = repo.runtimeType.toString();

  // 공통 정보
  debugPrint('🔧 AttendanceRepository binding => $typeName');

  if (currentFlavor.isDev && repo is AttendanceLocalRepository) {
    debugPrint('🟢 DEV: Local(Sembast) repository in use.');
  }

  if (currentFlavor.isProd) {
    if (repo is AttendanceRemoteRepository) {
      // AWS 스텁 토글도 함께 표시
      debugPrint(
          '🌐 PROD: Remote(AWS Stub) bound. MOCK=${aws_stub_show.kAwsMock}, DELAY_MS=${aws_stub_show.kAwsDelayMs}');
      if (!aws_stub_show.kAwsMock) {
        debugPrint(
            '⚠️ PROD warning: AWS stub MOCK=false → 모든 호출은 not_implemented 실패를 반환합니다.');
      }
    } else if (repo is AttendanceLocalRepository) {
      debugPrint(
          '⚠️ PROD warning: Local repository bound in PROD. (임시 설정: 실제 배포 전 반드시 원격으로 전환 필요)');
    }
  }
}

/// 환경 플래그에 따른 구현 선택
AttendanceRepository _buildAttendanceRepository() {
  switch (currentFlavor) {
    case AppFlavor.dev:
      return AttendanceLocalRepository();
    case AppFlavor.prod:
      // 현재는 AWS 스텁으로 연결(실 구현 전 단계)
      return const AttendanceRemoteRepository();
  }
}
