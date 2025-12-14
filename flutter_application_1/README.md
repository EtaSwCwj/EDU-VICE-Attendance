# EDU-VICE Attendance - 리팩토링 버전

## 🎯 주요 개선사항

### 1. Clean Architecture 적용
- **Domain Layer**: 비즈니스 로직과 엔티티 분리
- **Data Layer**: Repository 패턴으로 데이터 소스 추상화
- **Presentation Layer**: UI와 상태 관리 분리

### 2. 의존성 주입 (Dependency Injection)
- `get_it` 패키지를 사용한 중앙 집중식 DI 컨테이너
- 테스트 용이성 향상
- 느슨한 결합(Loose Coupling)

### 3. 에러 핸들링 표준화
- `dartz` 패키지의 `Either` 타입 사용
- `Failure`와 `Exception` 분리
- 일관된 에러 처리 패턴

### 4. 환경 설정 분리
- Development, Staging, Production 환경 분리
- `AppConfig` 클래스로 중앙 관리
- 환경별 로깅 및 Mock 데이터 제어

### 5. 동기화 매니저
- `SyncManager`로 로컬-원격 동기화 중앙 관리
- 네트워크 연결 상태 자동 감지
- 재시도 로직 및 큐 관리

## 📁 개선된 프로젝트 구조

\`\`\`
lib/
├── config/
│   └── app_config.dart          # 환경 설정
│
├── core/
│   ├── di/
│   │   └── injection_container.dart  # DI 컨테이너
│   ├── error/
│   │   ├── failures.dart        # Failure 클래스들
│   │   └── exceptions.dart      # Exception 클래스들
│   ├── network/
│   │   ├── network_info.dart    # 네트워크 상태 확인
│   │   └── sync_manager.dart    # 동기화 매니저
│   └── utils/
│
├── features/
│   └── {feature_name}/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── {feature}_local_datasource.dart
│       │   │   └── {feature}_remote_datasource.dart
│       │   ├── models/
│       │   │   └── {feature}_model.dart  # DTO
│       │   └── repositories/
│       │       └── {feature}_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── {feature}_entity.dart
│       │   ├── repositories/
│       │   │   └── {feature}_repository.dart  # 인터페이스
│       │   └── usecases/
│       │       └── {use_case}.dart
│       └── presentation/
│           ├── pages/
│           ├── widgets/
│           └── providers/
│
└── main.dart
\`\`\`

## 🚀 시작하기

### 1. 의존성 설치

\`\`\`bash
flutter pub get
\`\`\`

### 2. 환경 설정

기본적으로 Development 환경으로 실행됩니다.
다른 환경으로 실행하려면:

\`\`\`bash
# Staging
flutter run --dart-define=ENV=staging

# Production
flutter run --dart-define=ENV=production
\`\`\`

### 3. 코드 생성 (필요시)

DI 어노테이션 사용 시:

\`\`\`bash
flutter pub run build_runner build --delete-conflicting-outputs
\`\`\`

## 📝 Feature 추가 가이드

새로운 기능을 추가할 때는 다음 템플릿을 따르세요:

### 1. Domain Layer

\`\`\`dart
// lib/features/my_feature/domain/entities/my_entity.dart
import 'package:equatable/equatable.dart';

class MyEntity extends Equatable {
  final String id;
  final String name;

  const MyEntity({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

// lib/features/my_feature/domain/repositories/my_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/my_entity.dart';

abstract class MyRepository {
  Future<Either<Failure, MyEntity>> getEntity(String id);
  Future<Either<Failure, void>> saveEntity(MyEntity entity);
}

// lib/features/my_feature/domain/usecases/get_entity.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/my_entity.dart';
import '../repositories/my_repository.dart';

class GetEntity {
  final MyRepository repository;

  GetEntity(this.repository);

  Future<Either<Failure, MyEntity>> call(String id) {
    return repository.getEntity(id);
  }
}
\`\`\`

### 2. Data Layer

\`\`\`dart
// lib/features/my_feature/data/models/my_model.dart
import '../../domain/entities/my_entity.dart';

class MyModel extends MyEntity {
  const MyModel({required super.id, required super.name});

  factory MyModel.fromJson(Map<String, dynamic> json) {
    return MyModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  factory MyModel.fromEntity(MyEntity entity) {
    return MyModel(id: entity.id, name: entity.name);
  }
}

// lib/features/my_feature/data/repositories/my_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/my_entity.dart';
import '../../domain/repositories/my_repository.dart';
import '../datasources/my_local_datasource.dart';
import '../datasources/my_remote_datasource.dart';

class MyRepositoryImpl implements MyRepository {
  final MyLocalDataSource localDataSource;
  final MyRemoteDataSource remoteDataSource;

  MyRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, MyEntity>> getEntity(String id) async {
    try {
      final entity = await remoteDataSource.getEntity(id);
      await localDataSource.cacheEntity(entity);
      return Right(entity);
    } on NetworkException {
      try {
        final cachedEntity = await localDataSource.getEntity(id);
        return Right(cachedEntity);
      } on CacheException {
        return const Left(CacheFailure());
      }
    } on ServerException {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> saveEntity(MyEntity entity) async {
    try {
      await localDataSource.saveEntity(entity);
      await remoteDataSource.saveEntity(entity);
      return const Right(null);
    } on ServerException {
      return const Left(ServerFailure());
    } on CacheException {
      return const Left(CacheFailure());
    }
  }
}
\`\`\`

### 3. Presentation Layer

\`\`\`dart
// lib/features/my_feature/presentation/providers/my_provider.dart
import 'package:flutter/foundation.dart';
import '../../domain/entities/my_entity.dart';
import '../../domain/usecases/get_entity.dart';

class MyProvider extends ChangeNotifier {
  final GetEntity getEntity;

  MyProvider({required this.getEntity});

  MyEntity? _entity;
  bool _isLoading = false;
  String? _errorMessage;

  MyEntity? get entity => _entity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchEntity(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await getEntity(id);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (entity) {
        _entity = entity;
        _isLoading = false;
        notifyListeners();
      },
    );
  }
}
\`\`\`

### 4. DI 등록

\`\`\`dart
// lib/core/di/injection_container.dart에 추가

// Data Sources
getIt.registerLazySingleton<MyLocalDataSource>(
  () => MyLocalDataSourceImpl(getIt()),
);
getIt.registerLazySingleton<MyRemoteDataSource>(
  () => MyRemoteDataSourceImpl(),
);

// Repository
getIt.registerLazySingleton<MyRepository>(
  () => MyRepositoryImpl(
    localDataSource: getIt(),
    remoteDataSource: getIt(),
  ),
);

// Use Cases
getIt.registerLazySingleton<GetEntity>(
  () => GetEntity(getIt()),
);

// Provider
getIt.registerFactory<MyProvider>(
  () => MyProvider(getEntity: getIt()),
);
\`\`\`

## 🧪 테스트

### Unit Test 예시

\`\`\`dart
// test/features/my_feature/domain/usecases/get_entity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';

@GenerateMocks([MyRepository])
void main() {
  late GetEntity usecase;
  late MockMyRepository mockRepository;

  setUp(() {
    mockRepository = MockMyRepository();
    usecase = GetEntity(mockRepository);
  });

  test('should get entity from repository', () async {
    // Arrange
    const tId = '1';
    const tEntity = MyEntity(id: '1', name: 'Test');
    when(mockRepository.getEntity(tId))
        .thenAnswer((_) async => const Right(tEntity));

    // Act
    final result = await usecase(tId);

    // Assert
    expect(result, const Right(tEntity));
    verify(mockRepository.getEntity(tId));
    verifyNoMoreInteractions(mockRepository);
  });
}
\`\`\`

## 📊 마이그레이션 체크리스트

기존 프로젝트에서 리팩토링된 구조로 전환하려면:

- [ ] `pubspec.yaml` 의존성 업데이트
- [ ] `injection_container.dart` 설정
- [ ] 각 feature를 새 구조로 이동
  - [ ] attendance
  - [ ] assignments
  - [ ] homework
  - [ ] lessons
  - [ ] progress
  - [ ] teacher
  - [ ] student_assignments
- [ ] `main.dart`에서 DI 초기화 호출
- [ ] Mock 데이터를 환경 설정으로 제어
- [ ] 기존 Provider를 새 구조로 변경
- [ ] 테스트 작성

## 🔧 개발 팁

### 로깅

\`\`\`dart
final logger = getIt<Logger>();
logger.d('Debug message');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message');
\`\`\`

### 네트워크 상태 확인

\`\`\`dart
final networkInfo = getIt<NetworkInfo>();
final isConnected = await networkInfo.isConnected;

// 실시간 감지
networkInfo.onConnectivityChanged.listen((isConnected) {
  print('Network status: $isConnected');
});
\`\`\`

### 동기화

\`\`\`dart
final syncManager = getIt<SyncManager>();

// 동기화 작업 예약
syncManager.scheduleSync(SyncTask(
  id: 'task-1',
  operation: SyncOperation.create,
  entityType: 'attendance',
  data: {'key': 'value'},
));

// 모든 작업 동기화
await syncManager.syncAll();
\`\`\`

## 📚 참고 자료

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Reso Coder Clean Architecture Tutorial](https://resocoder.com/flutter-clean-architecture-tdd/)

## 🤝 기여

버그 리포트나 기능 제안은 이슈로 등록해주세요.

## 📄 라이선스

MIT License
