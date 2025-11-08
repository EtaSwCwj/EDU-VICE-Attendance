// lib/data/local/attendance_local_repository.dart
//
// AttendanceRepository의 로컬 구현(Sembast 기반).
// - Store: 'attendance' (string key -> map document)
// - recordedAt은 UTC ISO8601 문자열로 저장되어 시간 정렬과 범위 필터에 유리함.

import 'package:sembast/sembast.dart';

import '../../core/result.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/value/date_range.dart';
import 'sembast_database.dart';

const String _kAttendanceStore = 'attendance';

class AttendanceLocalRepository implements AttendanceRepository {
  final _store = stringMapStoreFactory.store(_kAttendanceStore);

  Future<Database> _db() => AppDatabase().database;

  @override
  Future<Result<String>> save(AttendanceRecord record) async {
    try {
      final db = await _db();
      final key = record.id;
      // merge: true → 일부 필드만 변경 시에도 누락 필드 유지
      await _store.record(key).put(db, record.toJson(), merge: true);
      return Result.success<String>(key);
    } catch (e, st) {
      return Result.failure<String>(
        'storage_unavailable',
        'Failed to save attendance',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<AttendanceRecord?>> getById(String id) async {
    try {
      final db = await _db();
      final snap = await _store.record(id).getSnapshot(db);
      if (snap == null) {
        // ❗ const 제거 + 제네릭은 메서드 쪽에 명시
        return Result.success<AttendanceRecord?>(null);
      }
      final map = Map<String, dynamic>.from(snap.value);
      return Result.success<AttendanceRecord?>(
        AttendanceRecord.fromJson(map),
      );
    } catch (e, st) {
      return Result.failure<AttendanceRecord?>(
        'storage_unavailable',
        'Failed to get attendance by id',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<List<AttendanceRecord>>> listByStudent(
    String studentId, {
    DateRange? range,
  }) async {
    try {
      final db = await _db();

      final filters = <Filter>[
        Filter.equals('studentId', studentId),
        if (range?.start != null)
          Filter.greaterThanOrEquals(
            'recordedAt',
            range!.start!.toUtc().toIso8601String(),
          ),
        if (range?.end != null)
          Filter.lessThan(
            'recordedAt',
            range!.end!.toUtc().toIso8601String(),
          ),
      ];

      final finder = Finder(
        filter: Filter.and(filters),
        sortOrders: [SortOrder('recordedAt', true)], // ascending
      );

      final snaps = await _store.find(db, finder: finder);
      final records = snaps
          .map((s) =>
              AttendanceRecord.fromJson(Map<String, dynamic>.from(s.value)))
          .toList();

      return Result.success<List<AttendanceRecord>>(records);
    } catch (e, st) {
      return Result.failure<List<AttendanceRecord>>(
        'storage_unavailable',
        'Failed to list by student',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<List<AttendanceRecord>>> listByClass(
    String classId, {
    DateRange? range,
  }) async {
    try {
      final db = await _db();

      final filters = <Filter>[
        Filter.equals('classId', classId),
        if (range?.start != null)
          Filter.greaterThanOrEquals(
            'recordedAt',
            range!.start!.toUtc().toIso8601String(),
          ),
        if (range?.end != null)
          Filter.lessThan(
            'recordedAt',
            range!.end!.toUtc().toIso8601String(),
          ),
      ];

      final finder = Finder(
        filter: Filter.and(filters),
        sortOrders: [SortOrder('recordedAt', true)], // ascending
      );

      final snaps = await _store.find(db, finder: finder);
      final records = snaps
          .map((s) =>
              AttendanceRecord.fromJson(Map<String, dynamic>.from(s.value)))
          .toList();

      return Result.success<List<AttendanceRecord>>(records);
    } catch (e, st) {
      return Result.failure<List<AttendanceRecord>>(
        'storage_unavailable',
        'Failed to list by class',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final db = await _db();
      await _store.record(id).delete(db);
      // ❗ const 제거
      return Result.success<void>(null);
    } catch (e, st) {
      return Result.failure<void>(
        'storage_unavailable',
        'Failed to delete attendance',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> upsertBatch(List<AttendanceRecord> records) async {
    try {
      final db = await _db();
      await db.transaction((txn) async {
        for (final r in records) {
          await _store.record(r.id).put(txn, r.toJson(), merge: true);
        }
      });
      // ❗ const 제거
      return Result.success<void>(null);
    } catch (e, st) {
      return Result.failure<void>(
        'storage_unavailable',
        'Failed to upsert batch',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
