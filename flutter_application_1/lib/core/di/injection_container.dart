// lib/core/di/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../../config/app_config.dart';
import '../network/network_info.dart';
import '../network/sync_manager.dart';
import '../../data/local/sembast_database.dart';

// Features - AWS Repositories
import '../../features/lessons/domain/repositories/lesson_repository.dart';
import '../../features/lessons/data/repositories/lesson_aws_repository.dart';
import '../../features/books/data/repositories/book_aws_repository.dart';
import '../../features/homework/data/repositories/assignment_aws_repository.dart';
import '../../features/users/data/repositories/student_aws_repository.dart';

// Features - Local Repositories (fallback)
import '../../features/lessons/data/repositories/lesson_local_repository.dart';
import '../../features/books/data/repositories/book_local_repository.dart';

final getIt = GetIt.instance;

/// 의존성 주입 초기화
Future<void> setupDependencies({AppConfig? config}) async {
  // ========== Core ==========
  // Config
  getIt.registerLazySingleton<AppConfig>(
    () => config ?? AppConfig.fromEnvironment(),
  );

  // Logger
  getIt.registerLazySingleton<Logger>(() => Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 50,
          colors: true,
          printEmojis: true,
        ),
      ));

  // Network Info
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt()),
  );

  // Sync Manager
  getIt.registerLazySingleton<SyncManager>(
    () => SyncManager(getIt()),
  );

  // Shared Preferences (비동기 초기화)
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Local Database (로컬 캐시/fallback용)
  final database = AppDatabase();
  await database.database;
  getIt.registerLazySingleton<AppDatabase>(() => database);

  final db = await database.database;
  getIt.registerLazySingleton(() => db);

  // ========== Amplify API 사용 (DataStore 대신 GraphQL API) ==========
  // DataStore는 Windows 미지원, GraphQL API는 모든 플랫폼 지원

  // ========== AWS Repositories ==========
  // Book Repository (AWS)
  getIt.registerLazySingleton<BookAwsRepository>(() => BookAwsRepository());

  // Lesson Repository (AWS - implements LessonRepository interface)
  getIt.registerLazySingleton<LessonRepository>(() => LessonAwsRepository());
  getIt.registerLazySingleton<LessonAwsRepository>(() => LessonAwsRepository());

  // Assignment Repository (AWS)
  getIt.registerLazySingleton<AssignmentAwsRepository>(() => AssignmentAwsRepository());

  // Student Repository (AWS)
  getIt.registerLazySingleton<StudentAwsRepository>(() => StudentAwsRepository());

  // ========== Local Repositories (fallback/offline용) ==========
  // BookLocalRepository는 로컬 캐시/fallback 용도로만 사용
  // seedDefaultBooks()는 제거 - AWS에서 실제 데이터 사용
  getIt.registerLazySingleton<BookLocalRepository>(() => BookLocalRepository(db));

  getIt.registerLazySingleton<LessonLocalRepository>(
    () => LessonLocalRepository(getIt()),
  );

  safePrint('[DI] Dependencies initialized with AWS repositories');
}

/// 의존성 주입 정리
Future<void> disposeDependencies() async {
  try {
    final syncManager = getIt<SyncManager>();
    syncManager.dispose();
  } catch (e) {
    safePrint('[DI] SyncManager dispose error: $e');
  }

  await getIt.reset();
}
