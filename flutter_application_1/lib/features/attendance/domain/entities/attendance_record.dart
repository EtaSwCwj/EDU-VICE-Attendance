// lib/features/attendance/domain/entities/attendance_record.dart
import 'package:equatable/equatable.dart';

/// 출석 상태
enum AttendanceStatus {
  present,
  late,
  absent,
  earlyLeave,
}

/// enum <-> 문자열 변환
extension AttendanceStatusX on AttendanceStatus {
  String toServerString() {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.late:
        return 'late';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.earlyLeave:
        return 'early_leave';
    }
  }

  static AttendanceStatus fromString(String s) {
    switch (s) {
      case 'present':
        return AttendanceStatus.present;
      case 'late':
        return AttendanceStatus.late;
      case 'absent':
        return AttendanceStatus.absent;
      case 'early_leave':
        return AttendanceStatus.earlyLeave;
      default:
        throw ArgumentError('Unknown AttendanceStatus: $s');
    }
  }
}

/// 위치 메타데이터
class GeoMeta extends Equatable {
  final double lat;
  final double lng;
  final double? accuracyMeters;

  const GeoMeta({
    required this.lat,
    required this.lng,
    this.accuracyMeters,
  });

  @override
  List<Object?> get props => [lat, lng, accuracyMeters];
}

/// 출석 레코드 엔티티 (도메인 모델)
class AttendanceRecord extends Equatable {
  final String id;
  final String academyId;
  final String classId;
  final String studentId;
  final String? subjectId;
  final AttendanceStatus status;
  final DateTime recordedAt;
  final String recordedBy;
  final GeoMeta? geo;
  final String? notes;

  const AttendanceRecord({
    required this.id,
    required this.academyId,
    required this.classId,
    required this.studentId,
    this.subjectId,
    required this.status,
    required this.recordedAt,
    required this.recordedBy,
    this.geo,
    this.notes,
  });

  /// 복사본 생성
  AttendanceRecord copyWith({
    String? id,
    String? academyId,
    String? classId,
    String? studentId,
    String? subjectId,
    AttendanceStatus? status,
    DateTime? recordedAt,
    String? recordedBy,
    GeoMeta? geo,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      classId: classId ?? this.classId,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      status: status ?? this.status,
      recordedAt: recordedAt ?? this.recordedAt,
      recordedBy: recordedBy ?? this.recordedBy,
      geo: geo ?? this.geo,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        academyId,
        classId,
        studentId,
        subjectId,
        status,
        recordedAt,
        recordedBy,
        geo,
        notes,
      ];
}
