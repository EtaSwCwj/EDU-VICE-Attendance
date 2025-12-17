import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../../../../models/ModelProvider.dart' as aws;

/// Teacher 테이블 AWS Repository (Owner 전용)
class TeacherAwsRepository {
  const TeacherAwsRepository();

  /// 전체 선생 조회
  Future<List<aws.Teacher>> getAllTeachers() async {
    try {
      final request = ModelQueries.list(aws.Teacher.classType);
      final response = await Amplify.API.query(request: request).response;

      final teachers = response.data?.items.whereType<aws.Teacher>().toList() ?? [];
      safePrint('[TeacherAwsRepository] 결과: ${teachers.length}명');
      return teachers;
    } catch (e) {
      safePrint('[TeacherAwsRepository] ERROR: $e');
      return [];
    }
  }

  /// 선생 조회 (ID로)
  Future<aws.Teacher?> getById(String id) async {
    try {
      final request = ModelQueries.get(aws.Teacher.classType, aws.TeacherModelIdentifier(id: id));
      final response = await Amplify.API.query(request: request).response;
      return response.data;
    } catch (e) {
      safePrint('[TeacherAwsRepository] ERROR: ID 조회 실패 - $e');
      return null;
    }
  }

  /// 선생 생성
  Future<aws.Teacher?> createTeacher({
    required String username,
    required String name,
  }) async {
    try {
      final teacher = aws.Teacher(
        username: username,
        name: name,
      );

      final request = ModelMutations.create(teacher);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.data != null) {
        safePrint('[TeacherAwsRepository] 선생 생성 완료: $username');
        return response.data;
      }
      return null;
    } catch (e) {
      safePrint('[TeacherAwsRepository] ERROR: 생성 실패 - $e');
      return null;
    }
  }

  /// 선생 수정
  Future<aws.Teacher?> updateTeacher(aws.Teacher teacher) async {
    try {
      final request = ModelMutations.update(teacher);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.data != null) {
        safePrint('[TeacherAwsRepository] 선생 수정 완료: ${teacher.id}');
        return response.data;
      }
      return null;
    } catch (e) {
      safePrint('[TeacherAwsRepository] ERROR: 수정 실패 - $e');
      return null;
    }
  }

  /// 선생 삭제
  Future<bool> deleteTeacher(String id) async {
    try {
      final teacher = await getById(id);
      if (teacher == null) return false;

      final request = ModelMutations.delete(teacher);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.data != null) {
        safePrint('[TeacherAwsRepository] 선생 삭제 완료: $id');
        return true;
      }
      return false;
    } catch (e) {
      safePrint('[TeacherAwsRepository] ERROR: 삭제 실패 - $e');
      return false;
    }
  }

  /// username으로 선생 조회
  Future<aws.Teacher?> getByUsername(String username) async {
    try {
      final request = ModelQueries.list(
        aws.Teacher.classType,
        where: aws.Teacher.USERNAME.eq(username),
      );
      final response = await Amplify.API.query(request: request).response;

      final teachers = response.data?.items.whereType<aws.Teacher>().toList() ?? [];
      return teachers.isNotEmpty ? teachers.first : null;
    } catch (e) {
      safePrint('[TeacherAwsRepository] ERROR: username 조회 실패 - $e');
      return null;
    }
  }
}
