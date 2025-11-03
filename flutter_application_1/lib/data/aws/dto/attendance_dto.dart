// lib/data/aws/dto/attendance_dto.dart
//
// [20-8 fix] AWS 전송용 DTO 스켈레톤 (아직 미사용)
// - meta 의존성 제거(@immutable 제거)
// - createdAt/updatedAt null 허용 및 안전 처리
// - Geo accuracy 참조 제거(정확한 필드명이 불확실하므로 우선 lat/lng만 매핑)
// - toEntity()에 required 'recordedBy' 인자 보완(임시로 source 또는 'remote')
// - Geo 타입은 AttendanceRecord 내 정의(예: GeoMeta)를 사용

import '../../../domain/entities/attendance_record.dart';

class AttendanceDto {
  final String id;
  final String academyId;
  final String classId;
  final String studentId;
  final String? subjectId;
  final String status; // present | late | absent | early_leave
  final String recordedAt; // UTC ISO8601
  final String? createdAt; // UTC ISO8601 (nullable)
  final String? updatedAt; // UTC ISO8601 (nullable)
  final String? notes;
  final double? geoLat;
  final double? geoLng;
  // accuracy는 엔티티 정의가 확정되면 추가
  final String? source;

  const AttendanceDto({
    required this.id,
    required this.academyId,
    required this.classId,
    required this.studentId,
    required this.status,
    required this.recordedAt,
    this.createdAt,
    this.updatedAt,
    this.subjectId,
    this.notes,
    this.geoLat,
    this.geoLng,
    this.source,
  });

  /// 서버(JSON) -> DTO
  factory AttendanceDto.fromJson(Map<String, dynamic> json) {
    return AttendanceDto(
      id: json['id'] as String,
      academyId: json['academy_id'] as String,
      classId: json['class_id'] as String,
      studentId: json['student_id'] as String,
      subjectId: json['subject_id'] as String?,
      status: json['status'] as String,
      recordedAt: json['recorded_at'] as String,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      notes: json['notes'] as String?,
      geoLat: (json['geo_lat'] as num?)?.toDouble(),
      geoLng: (json['geo_lng'] as num?)?.toDouble(),
      source: json['source'] as String?,
    );
  }

  /// DTO -> 서버(JSON)
  Map<String, dynamic> toJson() => {
        'id': id,
        'academy_id': academyId,
        'class_id': classId,
        'student_id': studentId,
        'subject_id': subjectId,
        'status': status, // present | late | absent | early_leave
        'recorded_at': recordedAt, // UTC ISO8601
        'created_at': createdAt,
        'updated_at': updatedAt,
        'notes': notes,
        'geo_lat': geoLat,
        'geo_lng': geoLng,
        'source': source,
      };

  /// 도메인 → DTO
  static AttendanceDto fromEntity(AttendanceRecord e) {
    return AttendanceDto(
      id: e.id,
      academyId: e.academyId,
      classId: e.classId,
      studentId: e.studentId,
      subjectId: e.subjectId,
      status: _statusToWire(e.status),
      recordedAt: e.recordedAt.toUtc().toIso8601String(),
      createdAt: e.createdAt?.toUtc().toIso8601String(),
      updatedAt: e.updatedAt?.toUtc().toIso8601String(),
      notes: e.notes,
      geoLat: e.geo?.lat,
      geoLng: e.geo?.lng,
      source: e.source,
    );
  }

  /// DTO → 도메인
  AttendanceRecord toEntity() {
    return AttendanceRecord(
      id: id,
      academyId: academyId,
      classId: classId,
      studentId: studentId,
      subjectId: subjectId,
      status: _statusFromWire(status),
      recordedAt: DateTime.parse(recordedAt).toUtc(),
      createdAt: createdAt != null ? DateTime.parse(createdAt!).toUtc() : null,
      updatedAt: updatedAt != null ? DateTime.parse(updatedAt!).toUtc() : null,
      notes: notes,
      // Geo: 정확한 타입명이 엔티티 내에서 'GeoMeta'로 보이므로 그 생성자를 사용
      geo: (geoLat != null && geoLng != null)
          ? GeoMeta(lat: geoLat!, lng: geoLng!)
          : null,
      // 엔티티가 recordedBy를 required로 요구하므로 임시로 source 또는 'remote' 사용
      recordedBy: source ?? 'remote',
      source: source,
    );
  }
}

/// 도메인 enum ↔︎ 전송 문자열 매핑
String _statusToWire(AttendanceStatus s) {
  switch (s) {
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

AttendanceStatus _statusFromWire(String v) {
  switch (v) {
    case 'present':
      return AttendanceStatus.present;
    case 'late':
      return AttendanceStatus.late;
    case 'absent':
      return AttendanceStatus.absent;
    case 'early_leave':
      return AttendanceStatus.earlyLeave;
    default:
      // 알 수 없는 값은 보수적으로 absent 처리(서버 계약 확정 시 재조정)
      return AttendanceStatus.absent;
  }
}
