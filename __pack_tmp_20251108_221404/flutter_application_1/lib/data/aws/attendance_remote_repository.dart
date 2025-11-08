// lib/data/aws/attendance_remote_repository.dart
//
// [20-11] AWS 스텁 토글을 --dart-define 로 외부 제어 (파일 단일 변경/완결)
//  - AWS_MOCK=true|false      : 모의 성공 토글 (기본 false -> not_implemented 유지)
//  - AWS_DELAY_MS=정수밀리초 : 모든 메서드에 인위적 지연 (기본 0)
//
// 실행 예:
//  - 기본(차단/지연없음): flutter run --dart-define=APP_FLAVOR=prod
//  - 모의성공:           flutter run --dart-define=APP_FLAVOR=prod --dart-define=AWS_MOCK=true
//  - 모의성공+200ms지연: flutter run --dart-define=APP_FLAVOR=prod --dart-define=AWS_MOCK=true --dart-define=AWS_DELAY_MS=200
//
// 안전 기본값:
//  - MOCK=false, DELAY=0 → 실수로 prod 실행해도 네트워크 동작/성공 경로로 착각할 일 없음(항상 not_implemented).

import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../core/result.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/value/date_range.dart';

import 'dto/attendance_dto.dart';

// ======= ENV 파싱 (컴파일 타임 상수 문자열을 런타임에서 해석) =======
// ※ Dart 스타일 가이드: lowerCamelCase
const String _envMockRaw = String.fromEnvironment('AWS_MOCK', defaultValue: 'false');
const String _envDelayRaw = String.fromEnvironment('AWS_DELAY_MS', defaultValue: '0');

bool _parseBool(String raw) {
  switch (raw.trim().toLowerCase()) {
    case '1':
    case 't':
    case 'true':
    case 'y':
    case 'yes':
      return true;
    default:
      return false;
  }
}

int _parseInt(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return 0;
  final v = int.tryParse(s);
  return v == null ? 0 : (v < 0 ? 0 : v);
}

// 외부 주입값(최초 접근 시 고정)
final bool kAwsMock = _parseBool(_envMockRaw);
final int  kAwsDelayMs = _parseInt(_envDelayRaw);
bool _kLogged = false; // 한 번만 로깅

class AttendanceRemoteRepository implements AttendanceRepository {
  const AttendanceRemoteRepository();

  Result<T> _notImplemented<T>(String method) {
    return Result.failure(
      'not_implemented',
      'AWS remote repository is not implemented yet: $method',
    );
  }

  Future<void> _maybeDelay() async {
    if (kAwsDelayMs > 0) {
      await Future.delayed(Duration(milliseconds: kAwsDelayMs));
    }
  }

  void _logOnce() {
    if (_kLogged) return;
    _kLogged = true;
    debugPrint('🌐 [AWS-Stub] MOCK=$kAwsMock, DELAY_MS=$kAwsDelayMs');
  }

  @override
  Future<Result<String>> save(AttendanceRecord record) async {
    _logOnce();
    await _maybeDelay();

    // DTO 변환/로깅(네트워크 호출 없음)
    try {
      final dto = AttendanceDto.fromEntity(record);
      final json = dto.toJson();
      debugPrint('📤 [AWS:save] payload => $json');
    } catch (e, st) {
      debugPrint('❗ [AWS:save] DTO convert error: $e\n$st');
      return _notImplemented<String>('save(dtof)');
    }

    if (kAwsMock) {
      debugPrint('✅ [AWS:save] MOCK SUCCESS (no network)');
      return Result.success(record.id);
    }
    return _notImplemented<String>('save');
  }

  @override
  Future<Result<AttendanceRecord?>> getById(String id) async {
    _logOnce();
    await _maybeDelay();

    if (kAwsMock) {
      debugPrint('✅ [AWS:getById] MOCK SUCCESS (no network)');
      return Result.success<AttendanceRecord?>(null);
    }
    return _notImplemented<AttendanceRecord?>('getById');
  }

  @override
  Future<Result<List<AttendanceRecord>>> listByStudent(
    String studentId, {
    DateRange? range,
  }) async {
    _logOnce();
    await _maybeDelay();

    if (kAwsMock) {
      debugPrint('✅ [AWS:listByStudent] MOCK SUCCESS (no network)');
      return Result.success<List<AttendanceRecord>>(<AttendanceRecord>[]);
    }
    return _notImplemented<List<AttendanceRecord>>('listByStudent');
  }

  @override
  Future<Result<List<AttendanceRecord>>> listByClass(
    String classId, {
    DateRange? range,
  }) async {
    _logOnce();
    await _maybeDelay();

    if (kAwsMock) {
      debugPrint('✅ [AWS:listByClass] MOCK SUCCESS (no network)');
      return Result.success<List<AttendanceRecord>>(<AttendanceRecord>[]);
    }
    return _notImplemented<List<AttendanceRecord>>('listByClass');
  }

  @override
  Future<Result<void>> delete(String id) async {
    _logOnce();
    await _maybeDelay();

    if (kAwsMock) {
      debugPrint('✅ [AWS:delete] MOCK SUCCESS (no network)');
      return Result.success<void>(null);
    }
    return _notImplemented<void>('delete');
  }

  @override
  Future<Result<void>> upsertBatch(List<AttendanceRecord> records) async {
    _logOnce();
    await _maybeDelay();

    if (kAwsMock) {
      debugPrint('✅ [AWS:upsertBatch] MOCK SUCCESS (no network) count=${records.length}');
      return Result.success<void>(null);
    }
    return _notImplemented<void>('upsertBatch');
  }
}
