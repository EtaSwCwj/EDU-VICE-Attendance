// lib/features/users/data/repositories/student_aws_repository.dart
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import '../../../../models/ModelProvider.dart';

/// AWS DynamoDB와 연동하는 Student Repository
/// TeacherStudent 관계 테이블을 통해 선생님-학생 연결 관리
class StudentAwsRepository {
  /// 현재 로그인한 선생님의 username 가져오기
  Future<String?> getCurrentTeacherUsername() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      final cognitoSession = session as CognitoAuthSession;
      final identityId = cognitoSession.identityIdResult.value;

      final attributes = await Amplify.Auth.fetchUserAttributes();
      final usernameAttr = attributes.firstWhere(
        (attr) => attr.userAttributeKey.key == 'preferred_username' ||
                  attr.userAttributeKey.key == 'username' ||
                  attr.userAttributeKey.key == 'sub',
        orElse: () => AuthUserAttribute(
          userAttributeKey: const CognitoUserAttributeKey.custom('sub'),
          value: identityId,
        ),
      );
      return usernameAttr.value;
    } catch (e) {
      try {
        final user = await Amplify.Auth.getCurrentUser();
        return user.username;
      } catch (_) {
        safePrint('[StudentAwsRepository] ERROR: 선생님 username 조회 실패');
        return null;
      }
    }
  }

  /// 선생님에게 연결된 학생 목록 조회
  Future<List<Student>> getStudentsByTeacher(String teacherUsername) async {
    try {
      final relationRequest = ModelQueries.list(
        TeacherStudent.classType,
        where: TeacherStudent.TEACHERUSERNAME.eq(teacherUsername),
      );
      final relationResponse = await Amplify.API.query(request: relationRequest).response;

      if (relationResponse.hasErrors) return [];

      final relations = relationResponse.data?.items.whereType<TeacherStudent>().toList() ?? [];
      if (relations.isEmpty) return [];

      final students = <Student>[];
      for (final relation in relations) {
        final studentRequest = ModelQueries.list(
          Student.classType,
          where: Student.USERNAME.eq(relation.studentUsername),
        );
        final studentResponse = await Amplify.API.query(request: studentRequest).response;

        if (!studentResponse.hasErrors && studentResponse.data != null) {
          final studentList = studentResponse.data!.items.whereType<Student>().toList();
          if (studentList.isNotEmpty) {
            students.add(studentList.first);
          }
        }
      }

      safePrint('[StudentAwsRepository] 결과: ${students.length}명 (선생님: $teacherUsername)');
      return students;
    } catch (e) {
      safePrint('[StudentAwsRepository] ERROR: $e');
      return [];
    }
  }

  /// 모든 학생 조회 (관리자용)
  Future<List<Student>> getAll() async {
    try {
      final request = ModelQueries.list(Student.classType);
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[StudentAwsRepository] ERROR: ${response.errors}');
        return [];
      }

      final students = response.data?.items.whereType<Student>().toList() ?? [];
      safePrint('[StudentAwsRepository] 결과: ${students.length}명');
      return students;
    } catch (e) {
      safePrint('[StudentAwsRepository] ERROR: $e');
      return [];
    }
  }

  /// username으로 학생 조회
  Future<Student?> getByUsername(String username) async {
    try {
      final request = ModelQueries.list(
        Student.classType,
        where: Student.USERNAME.eq(username),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) return null;

      final students = response.data?.items.whereType<Student>().toList() ?? [];
      return students.isNotEmpty ? students.first : null;
    } catch (e) {
      safePrint('[StudentAwsRepository] ERROR: username 조회 실패 - $e');
      return null;
    }
  }

  /// ID로 학생 조회
  Future<Student?> getById(String id) async {
    try {
      final request = ModelQueries.get(
        Student.classType,
        StudentModelIdentifier(id: id),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) return null;
      return response.data;
    } catch (e) {
      safePrint('[StudentAwsRepository] ERROR: ID 조회 실패 - $e');
      return null;
    }
  }

  /// 선생님-학생 연결 추가
  Future<TeacherStudent?> linkStudentToTeacher({
    required String teacherUsername,
    required String studentUsername,
    List<Subject>? subjects,
  }) async {
    try {
      final teacherStudent = TeacherStudent(
        teacherUsername: teacherUsername,
        studentUsername: studentUsername,
        subjects: subjects,
      );

      final request = ModelMutations.create(teacherStudent);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) return null;

      safePrint('[StudentAwsRepository] 학생 연결 완료: $studentUsername');
      return response.data;
    } catch (e) {
      safePrint('[StudentAwsRepository] ERROR: 학생 연결 실패 - $e');
      return null;
    }
  }

  /// 선생님-학생 연결 해제
  Future<bool> unlinkStudentFromTeacher({
    required String teacherUsername,
    required String studentUsername,
  }) async {
    try {
      final request = ModelQueries.list(
        TeacherStudent.classType,
        where: TeacherStudent.TEACHERUSERNAME.eq(teacherUsername)
            .and(TeacherStudent.STUDENTUSERNAME.eq(studentUsername)),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors || response.data == null) return false;

      final relations = response.data!.items.whereType<TeacherStudent>().toList();
      if (relations.isEmpty) return false;

      final deleteRequest = ModelMutations.delete(relations.first);
      final deleteResponse = await Amplify.API.mutate(request: deleteRequest).response;

      return !deleteResponse.hasErrors;
    } catch (e) {
      safePrint('[StudentAwsRepository] ERROR: 연결 해제 실패 - $e');
      return false;
    }
  }

  /// 선생님-학생 관계 조회 (과목 정보 포함)
  Future<List<TeacherStudent>> getTeacherStudentRelations(String teacherUsername) async {
    try {
      final request = ModelQueries.list(
        TeacherStudent.classType,
        where: TeacherStudent.TEACHERUSERNAME.eq(teacherUsername),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) return [];
      return response.data?.items.whereType<TeacherStudent>().toList() ?? [];
    } catch (e) {
      safePrint('[StudentAwsRepository] ERROR: 관계 조회 실패 - $e');
      return [];
    }
  }

  /// 학생 생성 (Owner 전용)
  Future<Student?> createStudent({
    required String username,
    required String name,
    String? grade,
  }) async {
    try {
      final student = Student(
        username: username,
        name: name,
        grade: grade,
      );

      final request = ModelMutations.create(student);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) return null;

      safePrint('[StudentAwsRepository] 학생 생성 완료: $username');
      return response.data;
    } catch (e) {
      safePrint('[StudentAwsRepository] ERROR: 학생 생성 실패 - $e');
      return null;
    }
  }

  /// 학생 수정 (Owner 전용)
  Future<Student?> updateStudent(Student student) async {
    try {
      final request = ModelMutations.update(student);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) return null;

      safePrint('[StudentAwsRepository] 학생 수정 완료: ${student.id}');
      return response.data;
    } catch (e) {
      safePrint('[StudentAwsRepository] ERROR: 학생 수정 실패 - $e');
      return null;
    }
  }

  /// 학생 삭제 (Owner 전용)
  Future<bool> deleteStudent(String id) async {
    try {
      final student = await getById(id);
      if (student == null) return false;

      final request = ModelMutations.delete(student);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) return false;

      safePrint('[StudentAwsRepository] 학생 삭제 완료: $id');
      return response.data != null;
    } catch (e) {
      safePrint('[StudentAwsRepository] ERROR: 학생 삭제 실패 - $e');
      return false;
    }
  }
}
