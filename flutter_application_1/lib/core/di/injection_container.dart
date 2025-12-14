// lib/core/di/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import '../../config/app_config.dart';
import '../network/network_info.dart';
import '../network/sync_manager.dart';
import '../../data/local/sembast_database.dart';

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

  // Local Database
  final database = AppDatabase();
  await database.database; // DB 초기화
  getIt.registerLazySingleton<AppDatabase>(() => database);

  // ========== Data Sources ==========
  // TODO: 각 feature의 data source 등록
  // 예: getIt.registerLazySingleton<AttendanceLocalDataSource>(...)

  // ========== Repositories ==========
  // TODO: 각 feature의 repository 등록
  // 예: getIt.registerLazySingleton<AttendanceRepository>(...)

  // ========== Use Cases ==========
  // TODO: 각 feature의 use case 등록
  // 예: getIt.registerLazySingleton<RecordAttendance>(...)

  // ========== Providers / Notifiers ==========
  // TODO: 각 feature의 provider 등록
  // 주의: Provider는 Factory로 등록 (매번 새 인스턴스 생성)
  // 예: getIt.registerFactory<AttendanceNotifier>(...)
}

/// 의존성 주입 정리
Future<void> disposeDependencies() async {
  final syncManager = getIt<SyncManager>();
  syncManager.dispose();

  await getIt.reset();
}
