// lib/domain/entities/attendance_record.dart
//
// 출석 레코드 도메인 모델.
// - 기본은 반(class) 단위 출석이지만, 과목별 통계를 위해 subjectId(옵션) 지원
// - 모든 시각은 UTC ISO8601 문자열로 직렬화/역직렬화
// - enum은 소문자/카멜 표기를 혼용:
//    * 코드(열거형): lowerCamelCase (lint 규칙 준수: earlyLeave)
//    * 직렬화 문자열: snake_case ('early_leave') 유지

/// 출석 상태
enum AttendanceStatus {
  present,     // 출석
  late,        // 지각
  absent,      // 결석
  earlyLeave,  // 조퇴 (직렬화 시 'early_leave')
}

/// enum <-> 문자열 변환
AttendanceStatus attendanceStatusFromString(String s) {
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

String attendanceStatusToString(AttendanceStatus s) {
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

/// 위치 메타데이터(선택)
class GeoMeta {
  final double lat;
  final double lng;
  final double? accuracyMeters; // m 단위

  const GeoMeta({
    required this.lat,
    required this.lng,
    this.accuracyMeters,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        if (accuracyMeters != null) 'accuracy': accuracyMeters,
      };

  factory GeoMeta.fromJson(Map<String, dynamic> json) {
    return GeoMeta(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      accuracyMeters: (json['accuracy'] as num?)?.toDouble(),
    );
  }
}

/// 출석 레코드
class AttendanceRecord {
  /// 레코드 ID (임시 생성 허용: 'tmp-xxxx' 형태도 가능, 나중에 서버 ID로 치환)
  final String id;

  /// 학원, 반, 학생 식별자
  final String academyId;
  final String classId;
  final String studentId;

  /// 과목 식별자(선택) — 기본은 반에서 유도 가능하지만, 과목별 조회/통계 최적화용으로 옵션 제공
  final String? subjectId;

  /// 출석 상태
  final AttendanceStatus status;

  /// 기록 시각(UTC)
  final DateTime recordedAt;

  /// 기록자(사용자 id)
  final String recordedBy;

  /// 위치 메타(선택)
  final GeoMeta? geo;

  /// 비고(선택)
  final String? notes;

  /// 메타(선택): 생성/수정 시각(UTC), 출처(local/server 등)
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? source;

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
    this.createdAt,
    this.updatedAt,
    this.source,
  });

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
    DateTime? createdAt,
    DateTime? updatedAt,
    String? source,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
    );
  }

  /// JSON 직렬화 (모든 시각 UTC ISO8601)
  Map<String, dynamic> toJson() => {
        'id': id,
        'academyId': academyId,
        'classId': classId,
        'studentId': studentId,
        if (subjectId != null) 'subjectId': subjectId,
        'status': attendanceStatusToString(status),
        'recordedAt': recordedAt.toUtc().toIso8601String(),
        'recordedBy': recordedBy,
        if (geo != null) 'geo': geo!.toJson(),
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
        if (source != null) 'source': source,
      };

  /// JSON 역직렬화 (문자열 → UTC DateTime)
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      academyId: json['academyId'] as String,
      classId: json['classId'] as String,
      studentId: json['studentId'] as String,
      subjectId: json['subjectId'] as String?,
      status: attendanceStatusFromString(json['status'] as String),
      recordedAt: DateTime.parse(json['recordedAt'] as String).toUtc(),
      recordedBy: json['recordedBy'] as String,
      geo: (json['geo'] != null)
          ? GeoMeta.fromJson(Map<String, dynamic>.from(json['geo'] as Map))
          : null,
      notes: json['notes'] as String?,
      createdAt: (json['createdAt'] != null)
          ? DateTime.parse(json['createdAt'] as String).toUtc()
          : null,
      updatedAt: (json['updatedAt'] != null)
          ? DateTime.parse(json['updatedAt'] as String).toUtc()
          : null,
      source: json['source'] as String?,
    );
  }
}
