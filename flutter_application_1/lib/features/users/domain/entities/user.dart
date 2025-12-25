import 'package:equatable/equatable.dart';

class Student extends Equatable {
  final String id;
  final String academyId;
  final String name;
  final String? phone;
  final String? email;
  final int? age;
  final String? gender;
  final List<String> assignedTeacherIds; // 담당 선생님들
  final DateTime enrolledAt;
  final bool isActive;

  const Student({
    required this.id,
    required this.academyId,
    required this.name,
    this.phone,
    this.email,
    this.age,
    this.gender,
    required this.assignedTeacherIds,
    required this.enrolledAt,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id];
}

class Teacher extends Equatable {
  final String id;
  final String academyId;
  final String name;
  final String phone;
  final String email;
  final List<String> subjects; // 담당 과목들
  final DateTime joinedAt;
  final bool isActive;

  const Teacher({
    required this.id,
    required this.academyId,
    required this.name,
    required this.phone,
    required this.email,
    required this.subjects,
    required this.joinedAt,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id];
}

class Academy extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final int studentCount;
  final DateTime createdAt;

  const Academy({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.studentCount,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}
