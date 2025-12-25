// lib/domain/usecases/record_attendance.dart
//
// [20-14] 출석 저장 유스케이스(스켈레톤, 아직 미연결)
// 역할:
//  - UI → (유스케이스) → Repository 흐름을 위한 얇은 도메인 계층.
//  - 기본 입력 검증만 수행하고, 레포지토리로 위임.
//  - AWS/로컬 여부와 무관: Repository 인터페이스만 의존.
//
// 주의:
//  - 이 단계에서는 파일만 추가. Provider/DI 연결은 다음 단계에서 수행.
//  - 입력(AttendanceRecord) 자체를 크게 변형하지 않는다(정규화는 이후 단계에서).
//
// 향후 확장 포인트:
//  - 타임스탬프 정규화(UTC 보정), 중복 체크, 위치 허용반경 검증, 과목/책/진도 연동 등.

import 'dart:async';

import '../../core/result.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';

class RecordAttendanceUseCase {
  final AttendanceRepository _repo;
  const RecordAttendanceUseCase(this._repo);

  /// 출석 한 건 저장
  /// - 간단한 입력 검증 후 Repository.save 위임
  Future<Result<String>> call(AttendanceRecord record) async {
    final err = _validate(record);
    if (err != null) {
      return Result.failure('invalid_input', err);
    }
    // 이후 단계에서 UTC 보정/필드 정규화 등을 추가 가능
    return _repo.save(record);
  }

  /// 최소 입력 검증
  String? _validate(AttendanceRecord r) {
    if (r.id.isEmpty) return 'id가 비어 있습니다.';
    if (r.academyId.isEmpty) return 'academyId가 비어 있습니다.';
    if (r.classId.isEmpty) return 'classId가 비어 있습니다.';
    if (r.studentId.isEmpty) return 'studentId가 비어 있습니다.';
    // status/recordedAt 같은 핵심 필드 존재 여부는 엔터티 생성 시점에 보장된다고 가정
    // (추가 정책은 이후 단계에서 강화)
    return null;
  }
}
