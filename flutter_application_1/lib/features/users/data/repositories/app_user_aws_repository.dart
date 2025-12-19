// lib/features/users/data/repositories/app_user_aws_repository.dart
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../../../../models/ModelProvider.dart';

/// AWS와 연동하는 AppUser Repository
///
/// 주의: GraphQL 스키마에 User 타입이 없으므로
/// Student/Teacher 테이블을 활용하여 사용자 정보를 관리합니다.
///
/// 회원가입 시:
/// - Cognito에 계정 생성 (Auth.signUp)
/// - Student 테이블에 기본 정보 저장 (새 사용자는 기본적으로 학생)
/// - 이후 Owner가 역할 변경 가능
class AppUserAwsRepository {
  /// Cognito username으로 유저 조회
  /// Student 또는 Teacher 테이블에서 검색
  Future<AppUser?> getByCognitoUsername(String cognitoUsername) async {
    try {
      safePrint('[AppUserAwsRepository] Fetching user by cognitoUsername: $cognitoUsername');

      // 1. Teacher 테이블에서 검색
      final teacherRequest = ModelQueries.list(
        Teacher.classType,
        where: Teacher.USERNAME.eq(cognitoUsername),
      );
      final teacherResponse = await Amplify.API.query(request: teacherRequest).response;

      if (!teacherResponse.hasErrors && teacherResponse.data != null) {
        final teachers = teacherResponse.data!.items.whereType<Teacher>().toList();
        if (teachers.isNotEmpty) {
          final t = teachers.first;
          safePrint('[AppUserAwsRepository] Found as teacher: ${t.name}');
          return AppUser(
            id: t.id,
            cognitoUsername: t.username,
            email: t.username, // username이 이메일인 경우
            name: t.name,
          );
        }
      }

      // 2. Student 테이블에서 검색
      final studentRequest = ModelQueries.list(
        Student.classType,
        where: Student.USERNAME.eq(cognitoUsername),
      );
      final studentResponse = await Amplify.API.query(request: studentRequest).response;

      if (!studentResponse.hasErrors && studentResponse.data != null) {
        final students = studentResponse.data!.items.whereType<Student>().toList();
        if (students.isNotEmpty) {
          final s = students.first;
          safePrint('[AppUserAwsRepository] Found as student: ${s.name}');
          return AppUser(
            id: s.id,
            cognitoUsername: s.username,
            email: s.username,
            name: s.name,
          );
        }
      }

      safePrint('[AppUserAwsRepository] User not found: $cognitoUsername');
      return null;
    } catch (e, stackTrace) {
      safePrint('[AppUserAwsRepository] getByCognitoUsername error: $e');
      safePrint('[AppUserAwsRepository] Stack trace: $stackTrace');
      return null;
    }
  }

  /// 이메일로 유저 조회
  Future<AppUser?> getByEmail(String email) async {
    // username이 이메일인 경우가 많으므로 동일하게 처리
    return getByCognitoUsername(email);
  }

  /// ID로 유저 조회
  Future<AppUser?> getById(String id) async {
    try {
      safePrint('[AppUserAwsRepository] Fetching user by ID: $id');

      // 1. Teacher 테이블에서 검색
      final teacherRequest = ModelQueries.get(
        Teacher.classType,
        TeacherModelIdentifier(id: id),
      );
      final teacherResponse = await Amplify.API.query(request: teacherRequest).response;

      if (!teacherResponse.hasErrors && teacherResponse.data != null) {
        final t = teacherResponse.data!;
        safePrint('[AppUserAwsRepository] Found as teacher: ${t.name}');
        return AppUser(
          id: t.id,
          cognitoUsername: t.username,
          email: t.username,
          name: t.name,
        );
      }

      // 2. Student 테이블에서 검색
      final studentRequest = ModelQueries.get(
        Student.classType,
        StudentModelIdentifier(id: id),
      );
      final studentResponse = await Amplify.API.query(request: studentRequest).response;

      if (!studentResponse.hasErrors && studentResponse.data != null) {
        final s = studentResponse.data!;
        safePrint('[AppUserAwsRepository] Found as student: ${s.name}');
        return AppUser(
          id: s.id,
          cognitoUsername: s.username,
          email: s.username,
          name: s.name,
        );
      }

      safePrint('[AppUserAwsRepository] User not found with ID: $id');
      return null;
    } catch (e, stackTrace) {
      safePrint('[AppUserAwsRepository] getById error: $e');
      safePrint('[AppUserAwsRepository] Stack trace: $stackTrace');
      return null;
    }
  }

  /// 유저 생성 (회원가입 시)
  /// 새 사용자는 기본적으로 Student 테이블에 저장
  Future<AppUser?> createUser({
    required String cognitoUsername,
    required String email,
    required String name,
    String? birthDate,
    String? gender,
    String? phone,
  }) async {
    try {
      safePrint('[AppUserAwsRepository] Creating user as student: $cognitoUsername');

      // Student 테이블에 저장
      final student = Student(
        username: cognitoUsername,
        name: name,
        grade: null, // 나중에 설정
      );

      final request = ModelMutations.create(student);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[AppUserAwsRepository] createUser errors: ${response.errors}');
        return null;
      }

      if (response.data != null) {
        final s = response.data!;
        safePrint('[AppUserAwsRepository] User created successfully: ${s.id}');
        return AppUser(
          id: s.id,
          cognitoUsername: s.username,
          email: email,
          name: s.name,
          birthDate: birthDate,
          gender: gender,
          phone: phone,
        );
      }

      return null;
    } catch (e, stackTrace) {
      safePrint('[AppUserAwsRepository] createUser error: $e');
      safePrint('[AppUserAwsRepository] Stack trace: $stackTrace');
      return null;
    }
  }

  /// 유저 수정
  Future<AppUser?> updateUser(AppUser user) async {
    try {
      safePrint('[AppUserAwsRepository] Updating user: ${user.id}');

      // Student 테이블에서 해당 사용자 찾기
      final studentRequest = ModelQueries.get(
        Student.classType,
        StudentModelIdentifier(id: user.id),
      );
      final studentResponse = await Amplify.API.query(request: studentRequest).response;

      if (!studentResponse.hasErrors && studentResponse.data != null) {
        final existingStudent = studentResponse.data!;
        final updatedStudent = existingStudent.copyWith(
          name: user.name,
        );

        final updateRequest = ModelMutations.update(updatedStudent);
        final updateResponse = await Amplify.API.mutate(request: updateRequest).response;

        if (!updateResponse.hasErrors && updateResponse.data != null) {
          safePrint('[AppUserAwsRepository] User updated successfully');
          return user;
        }
      }

      // Teacher 테이블에서 시도
      final teacherRequest = ModelQueries.get(
        Teacher.classType,
        TeacherModelIdentifier(id: user.id),
      );
      final teacherResponse = await Amplify.API.query(request: teacherRequest).response;

      if (!teacherResponse.hasErrors && teacherResponse.data != null) {
        final existingTeacher = teacherResponse.data!;
        final updatedTeacher = existingTeacher.copyWith(
          name: user.name,
        );

        final updateRequest = ModelMutations.update(updatedTeacher);
        final updateResponse = await Amplify.API.mutate(request: updateRequest).response;

        if (!updateResponse.hasErrors && updateResponse.data != null) {
          safePrint('[AppUserAwsRepository] User (teacher) updated successfully');
          return user;
        }
      }

      safePrint('[AppUserAwsRepository] User not found for update: ${user.id}');
      return null;
    } catch (e, stackTrace) {
      safePrint('[AppUserAwsRepository] updateUser error: $e');
      safePrint('[AppUserAwsRepository] Stack trace: $stackTrace');
      return null;
    }
  }

  /// 모든 유저 조회 (관리자용)
  /// Student + Teacher 목록 반환
  Future<List<AppUser>> getAll() async {
    try {
      safePrint('[AppUserAwsRepository] Fetching all users...');

      final users = <AppUser>[];

      // 1. 모든 Teacher 조회
      final teacherRequest = ModelQueries.list(Teacher.classType);
      final teacherResponse = await Amplify.API.query(request: teacherRequest).response;

      if (!teacherResponse.hasErrors && teacherResponse.data != null) {
        final teachers = teacherResponse.data!.items.whereType<Teacher>().toList();
        for (final t in teachers) {
          users.add(AppUser(
            id: t.id,
            cognitoUsername: t.username,
            email: t.username,
            name: t.name,
          ));
        }
      }

      // 2. 모든 Student 조회
      final studentRequest = ModelQueries.list(Student.classType);
      final studentResponse = await Amplify.API.query(request: studentRequest).response;

      if (!studentResponse.hasErrors && studentResponse.data != null) {
        final students = studentResponse.data!.items.whereType<Student>().toList();
        for (final s in students) {
          users.add(AppUser(
            id: s.id,
            cognitoUsername: s.username,
            email: s.username,
            name: s.name,
          ));
        }
      }

      safePrint('[AppUserAwsRepository] Found ${users.length} users');
      return users;
    } catch (e, stackTrace) {
      safePrint('[AppUserAwsRepository] getAll error: $e');
      safePrint('[AppUserAwsRepository] Stack trace: $stackTrace');
      return [];
    }
  }
}
