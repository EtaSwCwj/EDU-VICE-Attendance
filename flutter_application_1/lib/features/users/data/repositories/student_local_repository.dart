import 'package:sembast/sembast.dart';
import '../../domain/entities/user.dart';

class StudentLocalRepository {
  final Database _db;
  final _store = StoreRef<String, Map<String, dynamic>>('students');

  StudentLocalRepository(this._db);

  Future<List<Student>> getAll() async {
    final records = await _store.find(_db);
    return records
        .map((r) => _studentFromJson(r.value))
        .where((s) => s.isActive)
        .toList();
  }

  Future<Student?> getById(String id) async {
    final record = await _store.record(id).get(_db);
    if (record == null) return null;
    return _studentFromJson(record);
  }

  Future<List<Student>> getByTeacher(String teacherId) async {
    final records = await _store.find(_db);
    return records
        .map((r) => _studentFromJson(r.value))
        .where((s) => s.assignedTeacherIds.contains(teacherId) && s.isActive)
        .toList();
  }

  Future<void> save(Student student) async {
    await _store.record(student.id).put(_db, _studentToJson(student));
  }

  Future<void> delete(String id) async {
    await _store.record(id).delete(_db);
  }

  Future<void> softDelete(String id) async {
    final record = await _store.record(id).get(_db);
    if (record != null) {
      record['isActive'] = false;
      await _store.record(id).put(_db, record);
    }
  }

  Student _studentFromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      academyId: json['academyId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      assignedTeacherIds: (json['assignedTeacherIds'] as List).cast<String>(),
      enrolledAt: DateTime.parse(json['enrolledAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _studentToJson(Student student) {
    return {
      'id': student.id,
      'academyId': student.academyId,
      'name': student.name,
      'phone': student.phone,
      'email': student.email,
      'age': student.age,
      'gender': student.gender,
      'assignedTeacherIds': student.assignedTeacherIds,
      'enrolledAt': student.enrolledAt.toIso8601String(),
      'isActive': student.isActive,
    };
  }
}
