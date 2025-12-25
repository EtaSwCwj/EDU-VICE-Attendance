// lib/features/attendance/domain/usecases/record_attendance.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

/// 출석 기록 Use Case
class RecordAttendance {
  final AttendanceRepository repository;

  RecordAttendance(this.repository);

  Future<Either<Failure, AttendanceRecord>> call(RecordAttendanceParams params) {
    return repository.recordAttendance(
      academyId: params.academyId,
      classId: params.classId,
      studentId: params.studentId,
      status: params.status,
      recordedBy: params.recordedBy,
      subjectId: params.subjectId,
      geo: params.geo,
      notes: params.notes,
    );
  }
}

/// 파라미터 클래스
class RecordAttendanceParams extends Equatable {
  final String academyId;
  final String classId;
  final String studentId;
  final AttendanceStatus status;
  final String recordedBy;
  final String? subjectId;
  final GeoMeta? geo;
  final String? notes;

  const RecordAttendanceParams({
    required this.academyId,
    required this.classId,
    required this.studentId,
    required this.status,
    required this.recordedBy,
    this.subjectId,
    this.geo,
    this.notes,
  });

  @override
  List<Object?> get props => [
        academyId,
        classId,
        studentId,
        status,
        recordedBy,
        subjectId,
        geo,
        notes,
      ];
}
