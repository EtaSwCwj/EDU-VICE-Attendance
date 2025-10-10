// lib/domain/repositories/attendance_repository.dart
//
// 출석 레코드에 대한 데이터 접근 인터페이스.
// - 로컬 저장소/서버(AWS) 구현이 동일한 계약으로 교체 가능하도록 정의
// - 모든 결과는 Result<T>로 래핑하여 성공/실패를 일관되게 표현
// - 시간 범위는 DateRange(UTC, start inclusive / end exclusive)를 사용

import '../../core/result.dart';
import '../entities/attendance_record.dart';
import '../value/date_range.dart';

abstract class AttendanceRepository {
  /// 출석 레코드 저장 (없으면 생성, 있으면 갱신)
  /// - 성공: 생성/갱신된 레코드의 id 반환
  /// - 실패: code/message 포함
  Future<Result<String>> save(AttendanceRecord record);

  /// ID로 단건 조회
  /// - 성공: 존재하면 AttendanceRecord, 없으면 null
  Future<Result<AttendanceRecord?>> getById(String id);

  /// 학생 기준 리스트 조회 (옵션: 기간 필터)
  /// - start: 포함, end: 제외 (UTC)
  /// - 정렬 기준: recordedAt 오름차순(권장; 구현체에 위임)
  Future<Result<List<AttendanceRecord>>> listByStudent(
    String studentId, {
    DateRange? range,
  });

  /// 반 기준 리스트 조회 (옵션: 기간 필터)
  /// - start: 포함, end: 제외 (UTC)
  /// - 정렬 기준: recordedAt 오름차순(권장; 구현체에 위임)
  Future<Result<List<AttendanceRecord>>> listByClass(
    String classId, {
    DateRange? range,
  });

  /// 레코드 삭제 (존재하지 않아도 성공으로 처리 가능)
  Future<Result<void>> delete(String id);

  /// 여러 건을 한 번에 upsert (트랜잭션 단위)
  Future<Result<void>> upsertBatch(List<AttendanceRecord> records);
}
