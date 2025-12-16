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

      // Cognito username 가져오기
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
      safePrint('[StudentAwsRepository] getCurrentTeacherUsername error: $e');

      // fallback: Auth.getCurrentUser 시도
      try {
        final user = await Amplify.Auth.getCurrentUser();
        return user.username;
      } catch (_) {
        return null;
      }
    }
  }

  /// 선생님에게 연결된 학생 목록 조회
  /// TeacherStudent 테이블에서 관계 조회 후 Student 정보 가져옴
  Future<List<Student>> getStudentsByTeacher(String teacherUsername) async {
    try {
      // 1. TeacherStudent 관계 조회
      final relationRequest = ModelQueries.list(
        TeacherStudent.classType,
        where: TeacherStudent.TEACHERUSERNAME.eq(teacherUsername),
      );
      final relationResponse = await Amplify.API.query(request: relationRequest).response;

      if (relationResponse.hasErrors) {
        safePrint('[StudentAwsRepository] getStudentsByTeacher relation errors: ${relationResponse.errors}');
        return [];
      }

      final relations = relationResponse.data?.items.whereType<TeacherStudent>().toList() ?? [];
      if (relations.isEmpty) {
        safePrint('[StudentAwsRepository] No students linked to teacher: $teacherUsername');
        return [];
      }

      // 2. 각 studentUsername으로 Student 정보 조회
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

      safePrint('[StudentAwsRepository] Found ${students.length} students for teacher: $teacherUsername');
      return students;
    } catch (e) {
      safePrint('[StudentAwsRepository] getStudentsByTeacher error: $e');
      return [];
    }
  }

  /// 모든 학생 조회 (관리자용)
  Future<List<Student>> getAll() async {
    try {
      safePrint('');
      safePrint('========================================');
      safePrint('[StudentAwsRepository] getAll: START');
      safePrint('========================================');
      safePrint('[StudentAwsRepository] Fetching all students from AWS DynamoDB...');
      safePrint('[StudentAwsRepository] GraphQL Query: ModelQueries.list(Student.classType)');

      final request = ModelQueries.list(Student.classType);
      safePrint('[StudentAwsRepository] Request created, sending to AWS...');

      final response = await Amplify.API.query(request: request).response;
      safePrint('[StudentAwsRepository] Response received from AWS');

      if (response.hasErrors) {
        safePrint('[StudentAwsRepository] ❌ ERROR: Response has errors!');
        safePrint('[StudentAwsRepository] Error details: ${response.errors}');
        safePrint('[StudentAwsRepository] Error count: ${response.errors.length}');

        // 에러 상세 분석
        for (int i = 0; i < response.errors.length; i++) {
          final error = response.errors[i];
          safePrint('[StudentAwsRepository] Error [$i]: ${error.message}');
          safePrint('[StudentAwsRepository] Error [$i] path: ${error.path}');
          safePrint('[StudentAwsRepository] Error [$i] locations: ${error.locations}');
          safePrint('[StudentAwsRepository] Error [$i] extensions: ${error.extensions}');
        }

        return [];
      }

      safePrint('[StudentAwsRepository] ✅ No errors in response');
      safePrint('[StudentAwsRepository] Response data: ${response.data}');
      safePrint('[StudentAwsRepository] Response data items: ${response.data?.items}');

      final students = response.data?.items.whereType<Student>().toList() ?? [];

      safePrint('');
      safePrint('[StudentAwsRepository] 📊 RESULTS:');
      safePrint('[StudentAwsRepository] Total students found: ${students.length}');

      if (students.isEmpty) {
        safePrint('[StudentAwsRepository] ⚠️ WARNING: No students in AWS Student table!');
        safePrint('[StudentAwsRepository] This means the Student table is empty.');
        safePrint('[StudentAwsRepository] You need to create students first using AWS console or API.');
      } else {
        safePrint('[StudentAwsRepository] ✅ Students retrieved successfully:');
        for (int i = 0; i < students.length; i++) {
          final student = students[i];
          safePrint('[StudentAwsRepository]   [$i] username: ${student.username}, name: ${student.name}, grade: ${student.grade}');
        }
      }

      safePrint('========================================');
      safePrint('[StudentAwsRepository] getAll: END');
      safePrint('========================================');
      safePrint('');

      return students;
    } catch (e, stackTrace) {
      safePrint('');
      safePrint('========================================');
      safePrint('[StudentAwsRepository] ❌ EXCEPTION in getAll');
      safePrint('========================================');
      safePrint('[StudentAwsRepository] Exception type: ${e.runtimeType}');
      safePrint('[StudentAwsRepository] Exception message: $e');
      safePrint('[StudentAwsRepository] Stack trace:');
      safePrint('$stackTrace');
      safePrint('========================================');
      safePrint('');
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

      if (response.hasErrors) {
        safePrint('[StudentAwsRepository] getByUsername errors: ${response.errors}');
        return null;
      }

      final students = response.data?.items.whereType<Student>().toList() ?? [];
      return students.isNotEmpty ? students.first : null;
    } catch (e) {
      safePrint('[StudentAwsRepository] getByUsername error: $e');
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

      if (response.hasErrors) {
        safePrint('[StudentAwsRepository] getById errors: ${response.errors}');
        return null;
      }

      return response.data;
    } catch (e) {
      safePrint('[StudentAwsRepository] getById error: $e');
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

      if (response.hasErrors) {
        safePrint('[StudentAwsRepository] linkStudentToTeacher errors: ${response.errors}');
        return null;
      }

      return response.data;
    } catch (e) {
      safePrint('[StudentAwsRepository] linkStudentToTeacher error: $e');
      return null;
    }
  }

  /// 선생님-학생 연결 해제
  Future<bool> unlinkStudentFromTeacher({
    required String teacherUsername,
    required String studentUsername,
  }) async {
    try {
      // 관계 조회
      final request = ModelQueries.list(
        TeacherStudent.classType,
        where: TeacherStudent.TEACHERUSERNAME.eq(teacherUsername)
            .and(TeacherStudent.STUDENTUSERNAME.eq(studentUsername)),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors || response.data == null) {
        return false;
      }

      final relations = response.data!.items.whereType<TeacherStudent>().toList();
      if (relations.isEmpty) return false;

      // 삭제
      final deleteRequest = ModelMutations.delete(relations.first);
      final deleteResponse = await Amplify.API.mutate(request: deleteRequest).response;

      return !deleteResponse.hasErrors;
    } catch (e) {
      safePrint('[StudentAwsRepository] unlinkStudentFromTeacher error: $e');
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

      if (response.hasErrors) {
        safePrint('[StudentAwsRepository] getTeacherStudentRelations errors: ${response.errors}');
        return [];
      }

      return response.data?.items.whereType<TeacherStudent>().toList() ?? [];
    } catch (e) {
      safePrint('[StudentAwsRepository] getTeacherStudentRelations error: $e');
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
      safePrint('[StudentAwsRepository] Creating student: $username');

      final student = Student(
        username: username,
        name: name,
        grade: grade,
      );

      final request = ModelMutations.create(student);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[StudentAwsRepository] createStudent errors: ${response.errors}');
        return null;
      }

      if (response.data != null) {
        safePrint('[StudentAwsRepository] Student created successfully: ${response.data!.id}');
        return response.data;
      }

      return null;
    } catch (e) {
      safePrint('[StudentAwsRepository] createStudent error: $e');
      return null;
    }
  }

  /// 학생 수정 (Owner 전용)
  Future<Student?> updateStudent(Student student) async {
    try {
      safePrint('[StudentAwsRepository] Updating student: ${student.id}');

      final request = ModelMutations.update(student);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[StudentAwsRepository] updateStudent errors: ${response.errors}');
        return null;
      }

      if (response.data != null) {
        safePrint('[StudentAwsRepository] Student updated successfully');
        return response.data;
      }

      return null;
    } catch (e) {
      safePrint('[StudentAwsRepository] updateStudent error: $e');
      return null;
    }
  }

  /// 학생 삭제 (Owner 전용)
  Future<bool> deleteStudent(String id) async {
    try {
      safePrint('[StudentAwsRepository] Deleting student: $id');

      // 먼저 Student 객체 조회
      final student = await getById(id);
      if (student == null) {
        safePrint('[StudentAwsRepository] Student not found: $id');
        return false;
      }

      final request = ModelMutations.delete(student);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[StudentAwsRepository] deleteStudent errors: ${response.errors}');
        return false;
      }

      if (response.data != null) {
        safePrint('[StudentAwsRepository] Student deleted successfully');
        return true;
      }

      return false;
    } catch (e) {
      safePrint('[StudentAwsRepository] deleteStudent error: $e');
      return false;
    }
  }
}
