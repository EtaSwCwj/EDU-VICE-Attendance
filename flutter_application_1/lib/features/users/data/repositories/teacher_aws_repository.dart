import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../../../../models/ModelProvider.dart' as aws;

/// Teacher 테이블 AWS Repository (Owner 전용)
class TeacherAwsRepository {
  const TeacherAwsRepository();

  /// 전체 선생 조회
  Future<List<aws.Teacher>> getAllTeachers() async {
    try {
      safePrint('[TeacherAwsRepository] Fetching all teachers...');

      final request = ModelQueries.list(aws.Teacher.classType);
      final response = await Amplify.API.query(request: request).response;

      final teachers = response.data?.items.whereType<aws.Teacher>().toList() ?? [];

      safePrint('[TeacherAwsRepository] Fetched ${teachers.length} teachers');
      return teachers;
    } catch (e) {
      safePrint('[TeacherAwsRepository] Error fetching teachers: $e');
      return [];
    }
  }

  /// 선생 조회 (ID로)
  Future<aws.Teacher?> getById(String id) async {
    try {
      safePrint('[TeacherAwsRepository] Fetching teacher by ID: $id');

      final request = ModelQueries.get(aws.Teacher.classType, aws.TeacherModelIdentifier(id: id));
      final response = await Amplify.API.query(request: request).response;

      return response.data;
    } catch (e) {
      safePrint('[TeacherAwsRepository] Error fetching teacher: $e');
      return null;
    }
  }

  /// 선생 생성
  Future<aws.Teacher?> createTeacher({
    required String username,
    required String name,
  }) async {
    try {
      safePrint('[TeacherAwsRepository] Creating teacher: $username');

      final teacher = aws.Teacher(
        username: username,
        name: name,
      );

      final request = ModelMutations.create(teacher);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.data != null) {
        safePrint('[TeacherAwsRepository] Teacher created successfully: ${response.data!.id}');
        return response.data;
      } else {
        safePrint('[TeacherAwsRepository] Failed to create teacher: ${response.errors}');
        return null;
      }
    } catch (e) {
      safePrint('[TeacherAwsRepository] Error creating teacher: $e');
      return null;
    }
  }

  /// 선생 수정
  Future<aws.Teacher?> updateTeacher(aws.Teacher teacher) async {
    try {
      safePrint('[TeacherAwsRepository] Updating teacher: ${teacher.id}');

      final request = ModelMutations.update(teacher);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.data != null) {
        safePrint('[TeacherAwsRepository] Teacher updated successfully');
        return response.data;
      } else {
        safePrint('[TeacherAwsRepository] Failed to update teacher: ${response.errors}');
        return null;
      }
    } catch (e) {
      safePrint('[TeacherAwsRepository] Error updating teacher: $e');
      return null;
    }
  }

  /// 선생 삭제
  Future<bool> deleteTeacher(String id) async {
    try {
      safePrint('[TeacherAwsRepository] Deleting teacher: $id');

      // 먼저 Teacher 객체 조회
      final teacher = await getById(id);
      if (teacher == null) {
        safePrint('[TeacherAwsRepository] Teacher not found: $id');
        return false;
      }

      final request = ModelMutations.delete(teacher);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.data != null) {
        safePrint('[TeacherAwsRepository] Teacher deleted successfully');
        return true;
      } else {
        safePrint('[TeacherAwsRepository] Failed to delete teacher: ${response.errors}');
        return false;
      }
    } catch (e) {
      safePrint('[TeacherAwsRepository] Error deleting teacher: $e');
      return false;
    }
  }

  /// username으로 선생 조회
  Future<aws.Teacher?> getByUsername(String username) async {
    try {
      safePrint('[TeacherAwsRepository] Fetching teacher by username: $username');

      final request = ModelQueries.list(
        aws.Teacher.classType,
        where: aws.Teacher.USERNAME.eq(username),
      );
      final response = await Amplify.API.query(request: request).response;

      final teachers = response.data?.items.whereType<aws.Teacher>().toList() ?? [];

      if (teachers.isNotEmpty) {
        return teachers.first;
      }

      safePrint('[TeacherAwsRepository] Teacher not found with username: $username');
      return null;
    } catch (e) {
      safePrint('[TeacherAwsRepository] Error fetching teacher by username: $e');
      return null;
    }
  }
}
