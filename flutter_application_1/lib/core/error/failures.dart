// lib/core/error/failures.dart
import 'package:equatable/equatable.dart';

/// 비즈니스 로직 실패를 나타내는 추상 클래스
abstract class Failure extends Equatable {
  final String message;
  final dynamic error;

  const Failure(this.message, [this.error]);

  @override
  List<Object?> get props => [message, error];
}

/// 서버 관련 실패
class ServerFailure extends Failure {
  const ServerFailure([String message = '서버 오류가 발생했습니다', dynamic error])
      : super(message, error);
}

/// 네트워크 관련 실패
class NetworkFailure extends Failure {
  const NetworkFailure([String message = '네트워크 연결을 확인해주세요', dynamic error])
      : super(message, error);
}

/// 캐시(로컬) 관련 실패
class CacheFailure extends Failure {
  const CacheFailure([String message = '로컬 데이터 오류가 발생했습니다', dynamic error])
      : super(message, error);
}

/// 인증 관련 실패
class AuthFailure extends Failure {
  const AuthFailure([String message = '인증에 실패했습니다', dynamic error])
      : super(message, error);
}

/// 권한 관련 실패
class PermissionFailure extends Failure {
  const PermissionFailure([String message = '권한이 없습니다', dynamic error])
      : super(message, error);
}

/// 검증 관련 실패
class ValidationFailure extends Failure {
  const ValidationFailure([String message = '입력값이 올바르지 않습니다', dynamic error])
      : super(message, error);
}

/// 데이터를 찾을 수 없음
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = '데이터를 찾을 수 없습니다', dynamic error])
      : super(message, error);
}
