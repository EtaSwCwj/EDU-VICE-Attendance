// lib/shared/services/user_sync_service.dart
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import '../../models/ModelProvider.dart';

/// Cognito User Pool과 DynamoDB Student/Teacher 테이블 동기화 서비스
///
/// 역할:
/// 1. 로그인 시 Cognito 사용자를 DynamoDB에 자동 추가
/// 2. Cognito 그룹(students, teachers, owners)에 따라 테이블 구분
/// 3. 기존 Cognito 사용자를 일괄 마이그레이션
class UserSyncService {
  /// 현재 로그인한 사용자를 DynamoDB에 동기화
  ///
  /// 로그인 성공 후 호출:
  /// - Cognito 사용자 속성 조회
  /// - Cognito 그룹 조회
  /// - 그룹에 따라 Student 또는 Teacher 테이블에 추가
  /// - 이미 존재하면 업데이트하거나 skip
  Future<SyncResult> syncCurrentUser() async {
    try {
      safePrint('');
      safePrint('========================================');
      safePrint('[UserSyncService] syncCurrentUser: START');
      safePrint('========================================');
      safePrint('[UserSyncService] Time: ${DateTime.now()}');

      // 1. 현재 사용자 정보
      safePrint('[UserSyncService] Step 1: Getting current user...');
      final user = await Amplify.Auth.getCurrentUser();
      final username = user.username;
      final userId = user.userId;

      safePrint('[UserSyncService] ✓ Current user: username=$username, userId=$userId');

      // 2. 사용자 속성 조회
      safePrint('[UserSyncService] Step 2: Fetching user attributes...');
      final attributes = await Amplify.Auth.fetchUserAttributes();
      safePrint('[UserSyncService] ✓ Found ${attributes.length} attributes');

      String? name;

      for (final attr in attributes) {
        final key = attr.userAttributeKey.key;
        safePrint('[UserSyncService]   - $key: ${attr.value}');
        if (key == 'name' || key == 'preferred_username') {
          name = attr.value;
        }
      }

      name ??= username; // name이 없으면 username 사용

      safePrint('[UserSyncService] ✓ Resolved name: $name');

      // 3. Cognito 그룹 조회
      safePrint('[UserSyncService] Step 3: Getting Cognito groups...');
      final groups = await _getGroups();
      safePrint('[UserSyncService] ✓ Groups: $groups (count: ${groups.length})');

      // 4. 역할 판단
      safePrint('[UserSyncService] Step 4: Determining role...');
      final isStudent = groups.contains('students');
      final isTeacher = groups.contains('teachers') || groups.contains('owners');

      safePrint('[UserSyncService]   - isStudent: $isStudent');
      safePrint('[UserSyncService]   - isTeacher: $isTeacher');

      if (!isStudent && !isTeacher) {
        safePrint('[UserSyncService] ⚠️  WARNING: User has no role (not in students/teachers/owners group)');
        safePrint('[UserSyncService] ⚠️  Will create as Student by default...');
      }

      // 5. DynamoDB에 추가
      safePrint('[UserSyncService] Step 5: Syncing to DynamoDB...');
      if (isStudent || (!isTeacher && !isStudent)) {
        // Student 테이블에 추가
        safePrint('[UserSyncService] → Syncing to Student table...');
        final result = await _syncToStudentTable(
          username: username,
          userId: userId,
          name: name,
        );
        safePrint('[UserSyncService] ✅ Student sync result: ${result.message}');
        safePrint('========================================');
        safePrint('');
        return result;
      } else {
        // Teacher 테이블에 추가
        safePrint('[UserSyncService] → Syncing to Teacher table...');
        final result = await _syncToTeacherTable(
          username: username,
          userId: userId,
          name: name,
          isOwner: groups.contains('owners'),
        );
        safePrint('[UserSyncService] ✅ Teacher sync result: ${result.message}');
        safePrint('========================================');
        safePrint('');
        return result;
      }
    } catch (e, stackTrace) {
      safePrint('');
      safePrint('========================================');
      safePrint('[UserSyncService] ❌ EXCEPTION in syncCurrentUser');
      safePrint('========================================');
      safePrint('[UserSyncService] Exception: $e');
      safePrint('[UserSyncService] Stack trace: $stackTrace');
      safePrint('========================================');
      safePrint('');
      return SyncResult(success: false, message: 'Error: $e');
    }
  }

  /// Cognito 그룹 조회
  Future<List<String>> _getGroups() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      final idToken = session.userPoolTokensResult.value.idToken;

      // ID 토큰에서 cognito:groups 클레임 추출
      return idToken.groups;
    } catch (e) {
      safePrint('[UserSyncService] getGroups error: $e');
      return [];
    }
  }

  /// Student 테이블에 동기화
  Future<SyncResult> _syncToStudentTable({
    required String username,
    required String userId,
    required String name,
  }) async {
    try {
      safePrint('[_syncToStudentTable] START');
      safePrint('[_syncToStudentTable] username: $username, name: $name');

      // 1. 기존 Student 확인
      safePrint('[_syncToStudentTable] Step 1: Checking if student already exists...');
      final existingRequest = ModelQueries.list(
        Student.classType,
        where: Student.USERNAME.eq(username),
      );
      safePrint('[_syncToStudentTable] Sending query request...');
      final existingResponse = await Amplify.API.query(request: existingRequest).response;

      if (existingResponse.hasErrors) {
        safePrint('[_syncToStudentTable] ❌ Query errors:');
        for (int i = 0; i < existingResponse.errors.length; i++) {
          final error = existingResponse.errors[i];
          safePrint('[_syncToStudentTable]   Error [$i]: ${error.message}');
          safePrint('[_syncToStudentTable]   Error [$i] path: ${error.path}');
          safePrint('[_syncToStudentTable]   Error [$i] locations: ${error.locations}');
          safePrint('[_syncToStudentTable]   Error [$i] extensions: ${error.extensions}');
        }
      }

      final existingStudents = existingResponse.data?.items.whereType<Student>().toList() ?? [];
      safePrint('[_syncToStudentTable] ✓ Found ${existingStudents.length} existing students');

      if (existingStudents.isNotEmpty) {
        safePrint('[_syncToStudentTable] ℹ️  Student already exists: username=$username');
        safePrint('[_syncToStudentTable] END (already exists)');
        return SyncResult(
          success: true,
          message: 'Student already exists',
          isNew: false,
        );
      }

      // 2. 새로운 Student 생성
      safePrint('[_syncToStudentTable] Step 2: Creating new Student...');

      final student = Student(
        username: username,
        name: name,
        // grade는 null (나중에 설정 가능)
      );

      safePrint('[_syncToStudentTable] Student object created, sending mutation...');
      final createRequest = ModelMutations.create(student);
      final createResponse = await Amplify.API.mutate(request: createRequest).response;

      safePrint('[_syncToStudentTable] Mutation response received');

      if (createResponse.hasErrors) {
        safePrint('[_syncToStudentTable] ❌ Create student mutation errors:');
        for (int i = 0; i < createResponse.errors.length; i++) {
          final error = createResponse.errors[i];
          safePrint('[_syncToStudentTable]   Error [$i]: ${error.message}');
          safePrint('[_syncToStudentTable]   Error [$i] path: ${error.path}');
          safePrint('[_syncToStudentTable]   Error [$i] locations: ${error.locations}');
          safePrint('[_syncToStudentTable]   Error [$i] extensions: ${error.extensions}');
        }
        safePrint('[_syncToStudentTable] END (failed)');
        return SyncResult(
          success: false,
          message: 'Failed to create student: ${createResponse.errors.first.message}',
        );
      }

      safePrint('[_syncToStudentTable] ✅ Student created successfully!');
      safePrint('[_syncToStudentTable] Created student ID: ${createResponse.data?.id}');
      safePrint('[_syncToStudentTable] END (success)');
      return SyncResult(
        success: true,
        message: 'Student created successfully',
        isNew: true,
      );
    } catch (e, stackTrace) {
      safePrint('[UserSyncService] _syncToStudentTable error: $e');
      safePrint('[UserSyncService] Stack trace: $stackTrace');
      return SyncResult(success: false, message: 'Exception: $e');
    }
  }

  /// Teacher 테이블에 동기화
  Future<SyncResult> _syncToTeacherTable({
    required String username,
    required String userId,
    required String name,
    bool isOwner = false,
  }) async {
    try {
      safePrint('[_syncToTeacherTable] START');
      safePrint('[_syncToTeacherTable] username: $username, name: $name, isOwner: $isOwner');

      // 1. 기존 Teacher 확인
      safePrint('[_syncToTeacherTable] Step 1: Checking if teacher already exists...');
      final existingRequest = ModelQueries.list(
        Teacher.classType,
        where: Teacher.USERNAME.eq(username),
      );
      safePrint('[_syncToTeacherTable] Sending query request...');
      final existingResponse = await Amplify.API.query(request: existingRequest).response;

      if (existingResponse.hasErrors) {
        safePrint('[_syncToTeacherTable] ❌ Query errors:');
        for (int i = 0; i < existingResponse.errors.length; i++) {
          final error = existingResponse.errors[i];
          safePrint('[_syncToTeacherTable]   Error [$i]: ${error.message}');
          safePrint('[_syncToTeacherTable]   Error [$i] path: ${error.path}');
          safePrint('[_syncToTeacherTable]   Error [$i] locations: ${error.locations}');
          safePrint('[_syncToTeacherTable]   Error [$i] extensions: ${error.extensions}');
        }
      }

      final existingTeachers = existingResponse.data?.items.whereType<Teacher>().toList() ?? [];
      safePrint('[_syncToTeacherTable] ✓ Found ${existingTeachers.length} existing teachers');

      if (existingTeachers.isNotEmpty) {
        safePrint('[_syncToTeacherTable] ℹ️  Teacher already exists: username=$username');
        safePrint('[_syncToTeacherTable] END (already exists)');
        return SyncResult(
          success: true,
          message: 'Teacher already exists',
          isNew: false,
        );
      }

      // 2. 새로운 Teacher 생성
      safePrint('[_syncToTeacherTable] Step 2: Creating new Teacher...');

      final teacher = Teacher(
        username: username,
        name: name,
        // subjects는 null (나중에 설정 가능)
      );

      safePrint('[_syncToTeacherTable] Teacher object created, sending mutation...');
      final createRequest = ModelMutations.create(teacher);
      final createResponse = await Amplify.API.mutate(request: createRequest).response;

      safePrint('[_syncToTeacherTable] Mutation response received');

      if (createResponse.hasErrors) {
        safePrint('[_syncToTeacherTable] ❌ Create teacher mutation errors:');
        for (int i = 0; i < createResponse.errors.length; i++) {
          final error = createResponse.errors[i];
          safePrint('[_syncToTeacherTable]   Error [$i]: ${error.message}');
          safePrint('[_syncToTeacherTable]   Error [$i] path: ${error.path}');
          safePrint('[_syncToTeacherTable]   Error [$i] locations: ${error.locations}');
          safePrint('[_syncToTeacherTable]   Error [$i] extensions: ${error.extensions}');
        }
        safePrint('[_syncToTeacherTable] END (failed)');
        return SyncResult(
          success: false,
          message: 'Failed to create teacher: ${createResponse.errors.first.message}',
        );
      }

      safePrint('[_syncToTeacherTable] ✅ Teacher created successfully!');
      safePrint('[_syncToTeacherTable] Created teacher ID: ${createResponse.data?.id}');
      safePrint('[_syncToTeacherTable] END (success)');
      return SyncResult(
        success: true,
        message: 'Teacher created successfully',
        isNew: true,
      );
    } catch (e, stackTrace) {
      safePrint('[UserSyncService] _syncToTeacherTable error: $e');
      safePrint('[UserSyncService] Stack trace: $stackTrace');
      return SyncResult(success: false, message: 'Exception: $e');
    }
  }

  /// 모든 Cognito 사용자를 DynamoDB에 마이그레이션 (관리자 기능)
  ///
  /// 주의: 이 기능은 Cognito Admin API를 사용하므로
  /// IAM 권한이 필요합니다. 일반적으로 서버측에서 실행해야 합니다.
  Future<MigrationResult> migrateAllUsers() async {
    // TODO: Cognito Admin API를 사용한 전체 사용자 마이그레이션
    // 현재는 클라이언트에서 불가능 (Admin API 필요)
    return MigrationResult(
      totalUsers: 0,
      syncedUsers: 0,
      errors: ['Migration requires server-side implementation with Cognito Admin API'],
    );
  }
}

/// 동기화 결과
class SyncResult {
  final bool success;
  final String message;
  final bool isNew; // 새로 생성되었는지 여부

  SyncResult({
    required this.success,
    required this.message,
    this.isNew = false,
  });
}

/// 마이그레이션 결과
class MigrationResult {
  final int totalUsers;
  final int syncedUsers;
  final List<String> errors;

  MigrationResult({
    required this.totalUsers,
    required this.syncedUsers,
    required this.errors,
  });
}
