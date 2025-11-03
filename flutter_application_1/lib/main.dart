// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app_router.dart';
import 'app/app_providers.dart';
import 'app/app_env.dart'; // DEV/PROD 플래이버 확인
import 'shared/services/auth_state.dart';

// 플랫폼별 MockStorage 구현(조건부 임포트)
import 'shared/services/storage/mock_storage_io.dart'
  if (dart.library.html) 'shared/services/storage/mock_storage_web.dart' as storage;

// 유스케이스 호출
import 'domain/usecases/record_attendance.dart';
import 'domain/entities/attendance_record.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await storage.MockStorage.ensureSeeded();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: ChangeNotifierProvider(
        create: (_) => AuthState(),
        builder: (ctx, _) {
          final auth = ctx.watch<AuthState>();
          final router = createRouter(auth);

          // ===== DEV 전역 플로팅 버튼 핸들러 =====
          Future<void> devQuickSave(BuildContext context) async {
            final uc = context.read<RecordAttendanceUseCase>();
            final messenger = ScaffoldMessenger.of(context);

            final now = DateTime.now().toUtc();
            final ts = now.millisecondsSinceEpoch.toString();

            final record = AttendanceRecord(
              id: 'dev-$ts',
              academyId: 'academy-dev',
              classId: 'class-dev',
              studentId: 'student-dev',
              subjectId: null,
              status: AttendanceStatus.present,
              recordedAt: now,
              createdAt: now,
              updatedAt: now,
              notes: 'dev quick save',
              geo: null,
              recordedBy: 'dev-quick',
              source: 'dev-overlay',
            );

            final result = await uc(record);
            final ok = result.isSuccess;

            final msg = ok ? 'DEV 저장 성공' : 'DEV 저장 실패';
            messenger.showSnackBar(
              SnackBar(
                content: Text(msg),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          // ✅ Directionality 보장: MaterialApp.router 안의 builder에서 오버레이 구성
          return MaterialApp.router(
            //debugShowCheckedModeBanner: false,
            title: 'EDU-VICE',
            routerConfig: router,
            builder: (context, child) {
              // 기본 화면 (Router 출력)
              Widget body = child ?? const SizedBox.shrink();

              // DEV 배지 + DEV 버튼은 오버레이로 동일하게 제공
              if (currentFlavor.isDev) {
                body = Stack(
                  children: [
                    // DEV 배지
                    Banner(
                      message: 'DEV',
                      location: BannerLocation.topStart,
                      color: Colors.redAccent.withValues(alpha: 0.85),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      child: body,
                    ),
                    // 우하단 DEV 퀵세이브 버튼
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: FloatingActionButton(
                          heroTag: 'dev_quick_save',
                          mini: true,
                          onPressed: () => devQuickSave(context),
                          tooltip: 'DEV 저장(샘플)',
                          child: const Text(
                            'DEV',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              // PROD: 오버레이 없이 본문만
              return body;
            },
          );
        },
      ),
    );
  }
}
