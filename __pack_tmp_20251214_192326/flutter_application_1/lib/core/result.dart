// lib/core/result.dart
//
// 데이터 접근 계층(로컬 저장소/AWS/HTTP 등)에서 공통으로 사용하는 결과 타입.
// - 성공: Result.success(data)
// - 실패: Result.failure(code, message, cause?, stackTrace?)
//
// 사용 예)
//   final r = await repo.save(...);
//   if (r.isSuccess) { print(r.data); } else { print('${r.code}: ${r.message}'); }

class Result<T> {
  final T? data;
  final String? code;     // e.g., not_found, invalid_payload, storage_unavailable, quota_exceeded, unknown
  final String? message;
  final Object? cause;
  final StackTrace? stackTrace;

  const Result._({
    this.data,
    this.code,
    this.message,
    this.cause,
    this.stackTrace,
  });

  bool get isSuccess => code == null;
  bool get isFailure => code != null;

  /// 성공 결과를 생성
  static Result<T> success<T>(T data) => Result._(data: data);

  /// 실패 결과를 생성
  static Result<T> failure<T>(
    String code,
    String message, {
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return Result._(
      code: code,
      message: message,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// 성공일 때만 값을 변환(실패면 에러 상태 그대로 전파)
  Result<R> map<R>(R Function(T value) transform) {
    if (isFailure) {
      return Result<R>._(
        code: code,
        message: message,
        cause: cause,
        stackTrace: stackTrace,
      );
    }
    return Result.success<R>(transform(data as T));
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'Result<Success>(data: $data)';
    }
    return 'Result<Failure>(code: $code, message: $message, cause: $cause)';
  }
}
