// lib/features/attendance/domain/repositories/attendance_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/attendance_record.dart';

/// 출석 Repository 인터페이스
abstract class AttendanceRepository {
  /// 출석 기록
  Future<Either<Failure, AttendanceRecord>> recordAttendance({
    required String academyId,
    required String classId,
    required String studentId,
    required AttendanceStatus status,
    required String recordedBy,
    String? subjectId,
    GeoMeta? geo,
    String? notes,
  });

  /// 특정 학생의 출석 기록 조회
  Future<Either<Failure, List<AttendanceRecord>>> getAttendanceByStudent({
    required String studentId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// 특정 반의 출석 기록 조회
  Future<Either<Failure, List<AttendanceRecord>>> getAttendanceByClass({
    required String classId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// 특정 날짜의 출석 기록 조회
  Future<Either<Failure, List<AttendanceRecord>>> getAttendanceByDate({
    required String academyId,
    required DateTime date,
  });

  /// 출석 기록 수정
  Future<Either<Failure, AttendanceRecord>> updateAttendance({
    required String recordId,
    AttendanceStatus? status,
    String? notes,
  });

  /// 출석 기록 삭제
  Future<Either<Failure, void>> deleteAttendance(String recordId);

  /// 로컬과 원격 동기화
  Future<Either<Failure, void>> syncAttendance();
}
