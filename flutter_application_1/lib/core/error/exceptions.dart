// lib/core/error/exceptions.dart

/// 서버 예외
class ServerException implements Exception {
  final String message;
  final dynamic error;

  ServerException([this.message = 'Server error occurred', this.error]);

  @override
  String toString() => 'ServerException: $message';
}

/// 네트워크 예외
class NetworkException implements Exception {
  final String message;
  final dynamic error;

  NetworkException([this.message = 'Network error occurred', this.error]);

  @override
  String toString() => 'NetworkException: $message';
}

/// 캐시 예외
class CacheException implements Exception {
  final String message;
  final dynamic error;

  CacheException([this.message = 'Cache error occurred', this.error]);

  @override
  String toString() => 'CacheException: $message';
}

/// 인증 예외
class AuthException implements Exception {
  final String message;
  final dynamic error;

  AuthException([this.message = 'Authentication failed', this.error]);

  @override
  String toString() => 'AuthException: $message';
}

/// 검증 예외
class ValidationException implements Exception {
  final String message;
  final Map<String, String>? errors;

  ValidationException([this.message = 'Validation failed', this.errors]);

  @override
  String toString() => 'ValidationException: $message';
}
