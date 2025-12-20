// lib/shared/services/user_sync_service.dart
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

/// Cognito User Pool 정보 조회 서비스
///
/// 역할:
/// 1. 로그인 시 Cognito 사용자 정보 확인
/// 2. Cognito 그룹(students, teachers, owners) 조회
/// 3. 레거시 Student/Teacher 테이블 동기화는 제거됨 (더 이상 사용 안 함)
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
        safePrint('[UserSyncService] ℹ️  역할 없음 - 초대 대기 상태');
        safePrint('[UserSyncService] ℹ️  레거시 테이블에 자동 생성하지 않음');
        safePrint('========================================');
        safePrint('');
        return SyncResult(
          success: true,
          message: '역할 없음 - 초대 대기 상태',
          isNew: false,
        );
      }

      // 5. DynamoDB에 추가 (레거시 테이블은 더 이상 사용 안 함)
      safePrint('[UserSyncService] Step 5: 레거시 테이블 동기화 스킵');
      safePrint('[UserSyncService] ℹ️  Student/Teacher 테이블은 더 이상 사용하지 않음');
      safePrint('[UserSyncService] ℹ️  AppUser, AcademyMember 테이블만 사용');
      safePrint('========================================');
      safePrint('');
      return SyncResult(
        success: true,
        message: '레거시 테이블 동기화 스킵',
        isNew: false,
      );
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
