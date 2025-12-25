# 🔄 마이그레이션 가이드

기존 프로젝트에서 리팩토링된 버전으로 전환하는 단계별 가이드입니다.

## 📋 전체 마이그레이션 프로세스

### Phase 1: 인프라 설정 (1-2일)

#### 1.1 의존성 업데이트

기존 `pubspec.yaml`을 리팩토링된 버전으로 교체합니다.

\`\`\`bash
# 1. pubspec.yaml 백업
cp pubspec.yaml pubspec.yaml.backup

# 2. 새 pubspec.yaml 복사
# (리팩토링된 버전의 pubspec.yaml 사용)

# 3. 의존성 설치
flutter pub get
\`\`\`

#### 1.2 Core 디렉토리 추가

\`\`\`bash
# Core 디렉토리 생성
mkdir -p lib/core/{error,network,di,utils,constants}
mkdir -p lib/config
\`\`\`

다음 파일들을 복사:
- `lib/core/error/failures.dart`
- `lib/core/error/exceptions.dart`
- `lib/core/network/network_info.dart`
- `lib/core/network/sync_manager.dart`
- `lib/core/di/injection_container.dart`
- `lib/config/app_config.dart`

#### 1.3 main.dart 업데이트

\`\`\`dart
// 기존 main.dart
void main() {
  runApp(MyApp());
}

// 새 main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final config = AppConfig.fromEnvironment();
  await setupDependencies(config: config);
  
  runApp(EVAttendanceApp(config: config));
}
\`\`\`

### Phase 2: Feature별 리팩토링 (2-3주)

각 feature를 하나씩 Clean Architecture 구조로 변환합니다.

#### 2.1 Attendance Feature 리팩토링 (예시)

**Step 1: 디렉토리 구조 생성**

\`\`\`bash
mkdir -p lib/features/attendance/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{pages,widgets,providers}}
\`\`\`

**Step 2: Domain Layer 이동**

기존 파일:
\`\`\`
lib/domain/entities/attendance_record.dart
lib/domain/repositories/attendance_repository.dart
lib/domain/usecases/record_attendance.dart
\`\`\`

새 위치:
\`\`\`
lib/features/attendance/domain/entities/attendance_record.dart
lib/features/attendance/domain/repositories/attendance_repository.dart
lib/features/attendance/domain/usecases/record_attendance.dart
\`\`\`

**Step 3: Entity에 Equatable 추가**

\`\`\`dart
// Before
class AttendanceRecord {
  final String id;
  final String studentId;
  // ...
}

// After
class AttendanceRecord extends Equatable {
  final String id;
  final String studentId;
  // ...
  
  @override
  List<Object?> get props => [id, studentId, ...];
}
\`\`\`

**Step 4: Repository를 Either로 변환**

\`\`\`dart
// Before
abstract class AttendanceRepository {
  Future<AttendanceRecord> recordAttendance(...);
}

// After
abstract class AttendanceRepository {
  Future<Either<Failure, AttendanceRecord>> recordAttendance(...);
}
\`\`\`

**Step 5: Data Layer 생성**

\`\`\`dart
// lib/features/attendance/data/models/attendance_model.dart
class AttendanceModel extends AttendanceRecord {
  const AttendanceModel({
    required super.id,
    required super.studentId,
    // ...
  });
  
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    // JSON 파싱
  }
  
  Map<String, dynamic> toJson() {
    // JSON 직렬화
  }
}

// lib/features/attendance/data/datasources/attendance_local_datasource.dart
abstract class AttendanceLocalDataSource {
  Future<AttendanceModel> getAttendance(String id);
  Future<void> cacheAttendance(AttendanceModel attendance);
}

// lib/features/attendance/data/datasources/attendance_remote_datasource.dart
abstract class AttendanceRemoteDataSource {
  Future<AttendanceModel> getAttendance(String id);
  Future<void> saveAttendance(AttendanceModel attendance);
}

// lib/features/attendance/data/repositories/attendance_repository_impl.dart
class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceLocalDataSource localDataSource;
  final AttendanceRemoteDataSource remoteDataSource;
  
  AttendanceRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });
  
  @override
  Future<Either<Failure, AttendanceRecord>> recordAttendance(...) async {
    try {
      // 로컬 저장
      await localDataSource.cacheAttendance(model);
      
      // 원격 저장
      final result = await remoteDataSource.saveAttendance(model);
      
      return Right(result);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException {
      return const Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
\`\`\`

**Step 6: Presentation Layer 업데이트**

\`\`\`dart
// lib/features/attendance/presentation/providers/attendance_provider.dart
class AttendanceProvider extends ChangeNotifier {
  final RecordAttendance recordAttendanceUseCase;
  
  AttendanceProvider({required this.recordAttendanceUseCase});
  
  Future<void> recordAttendance(...) async {
    final result = await recordAttendanceUseCase(params);
    
    result.fold(
      (failure) {
        // 에러 처리
        _errorMessage = failure.message;
      },
      (attendance) {
        // 성공 처리
        _attendances.add(attendance);
      },
    );
    
    notifyListeners();
  }
}
\`\`\`

**Step 7: DI 등록**

\`\`\`dart
// lib/core/di/injection_container.dart에 추가

// Data Sources
getIt.registerLazySingleton<AttendanceLocalDataSource>(
  () => AttendanceLocalDataSourceImpl(getIt<SembastDatabase>()),
);

getIt.registerLazySingleton<AttendanceRemoteDataSource>(
  () => AttendanceRemoteDataSourceImpl(),
);

// Repository
getIt.registerLazySingleton<AttendanceRepository>(
  () => AttendanceRepositoryImpl(
    localDataSource: getIt(),
    remoteDataSource: getIt(),
  ),
);

// Use Cases
getIt.registerLazySingleton<RecordAttendance>(
  () => RecordAttendance(getIt()),
);

// Provider
getIt.registerFactory<AttendanceProvider>(
  () => AttendanceProvider(recordAttendanceUseCase: getIt()),
);
\`\`\`

**Step 8: UI에서 사용**

\`\`\`dart
// Before
class AttendancePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AttendanceProvider(),
      child: ...,
    );
  }
}

// After
class AttendancePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<AttendanceProvider>(),
      child: ...,
    );
  }
}
\`\`\`

#### 2.2 다른 Features도 동일한 패턴 적용

- [ ] Assignments
- [ ] Homework
- [ ] Lessons
- [ ] Progress
- [ ] Teacher
- [ ] Student Assignments

### Phase 3: 통합 및 테스트 (1주)

#### 3.1 Mock 데이터 처리

\`\`\`dart
// lib/config/app_config.dart에서 제어
if (config.enableMockData) {
  getIt.registerLazySingleton<AttendanceRemoteDataSource>(
    () => MockAttendanceRemoteDataSource(),
  );
} else {
  getIt.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSourceImpl(),
  );
}
\`\`\`

#### 3.2 동기화 통합

\`\`\`dart
// Repository에서 SyncManager 사용
class AttendanceRepositoryImpl implements AttendanceRepository {
  final SyncManager syncManager;
  
  @override
  Future<Either<Failure, AttendanceRecord>> recordAttendance(...) async {
    // 로컬 저장
    await localDataSource.cacheAttendance(model);
    
    // 동기화 예약
    syncManager.scheduleSync(SyncTask(
      id: model.id,
      operation: SyncOperation.create,
      entityType: 'attendance',
      data: model.toJson(),
    ));
    
    return Right(model);
  }
}

// SyncManager 이벤트 리스닝
syncManager.onSync.listen((task) {
  if (task.entityType == 'attendance') {
    // 원격에 저장
    remoteDataSource.saveAttendance(task.data);
  }
});
\`\`\`

### Phase 4: 최적화 및 개선 (지속적)

#### 4.1 테스트 작성

\`\`\`bash
# 테스트 디렉토리 구조
test/
├── features/
│   └── attendance/
│       ├── data/
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   └── usecases/
│       └── presentation/
│           └── providers/
└── core/
    ├── error/
    └── network/
\`\`\`

#### 4.2 CI/CD 설정

\`\`\`.github/workflows/flutter.yml
name: Flutter CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: flutter analyze
    - run: flutter test
    - run: flutter build apk
\`\`\`

## 🔍 검증 체크리스트

### 코드 품질
- [ ] 모든 feature가 동일한 구조를 따름
- [ ] Either 타입으로 에러 처리
- [ ] DI로 의존성 주입
- [ ] Equatable로 value object 구현

### 기능
- [ ] 기존 기능이 모두 작동함
- [ ] 오프라인 모드 동작 확인
- [ ] 동기화 정상 작동
- [ ] 에러 처리 및 사용자 피드백

### 성능
- [ ] 불필요한 rebuild 없음
- [ ] 메모리 누수 없음
- [ ] 네트워크 요청 최적화

### 테스트
- [ ] Unit test 커버리지 > 80%
- [ ] Widget test 작성
- [ ] Integration test 작성

## 💡 마이그레이션 팁

### 1. 점진적 마이그레이션
한 번에 모든 것을 변경하지 말고, feature별로 점진적으로 마이그레이션하세요.

### 2. 기존 코드 유지
마이그레이션 중에도 앱이 작동해야 합니다. 기존 코드를 주석 처리하지 말고 점진적으로 교체하세요.

### 3. 테스트 우선
각 feature를 마이그레이션할 때마다 테스트를 작성하세요.

### 4. 팀 커뮤니케이션
팀원들과 새로운 구조에 대해 충분히 논의하세요.

### 5. 문서화
각 변경사항을 문서화하고, 팀원들이 쉽게 따라할 수 있도록 하세요.

## 🚨 주의사항

### Breaking Changes
- Provider 생성 방식 변경: `create: (_) => getIt<MyProvider>()`
- Repository return 타입 변경: `Future<T>` → `Future<Either<Failure, T>>`
- Entity에 Equatable 상속 필요

### 마이그레이션 중 발생할 수 있는 이슈

1. **Import 경로 변경**
   ```dart
   // Before
   import '../domain/entities/attendance_record.dart';
   
   // After
   import '../features/attendance/domain/entities/attendance_record.dart';
   ```

2. **Null Safety**
   모든 코드가 null safety를 지원해야 합니다.

3. **비동기 초기화**
   DI 컨테이너는 비동기 초기화가 필요합니다.

## 📞 도움이 필요하면

- GitHub Issues에 질문 등록
- 팀 Slack 채널에서 논의
- Code Review 요청

---

마이그레이션에 성공하면 더 깨끗하고 유지보수하기 쉬운 코드베이스를 갖게 됩니다! 💪
