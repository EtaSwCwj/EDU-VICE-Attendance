// lib/shared/services/user_sync_service.dart
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';

/// Cognito User Pool 정보 조회 서비스
///
/// 역할:
/// 1. 로그인 시 Cognito 사용자 정보 확인
/// 2. Cognito 그룹(students, teachers, owners) 조회
/// 3. AppUser가 없으면 자동 생성
class UserSyncService {
  /// 현재 로그인한 사용자를 DynamoDB에 동기화
  ///
  /// 로그인 성공 후 호출:
  /// - Cognito 사용자 속성 조회
  /// - AppUser 조회 (API 사용 - 실시간 데이터)
  /// - AppUser가 없으면 생성
  /// - 있으면 스킵
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
      final cognitoUsername = user.username;
      final userId = user.userId;

      safePrint('[UserSyncService] ✓ Cognito user: username=$cognitoUsername, userId=$userId');

      // 2. 사용자 속성 조회
      safePrint('[UserSyncService] Step 2: Fetching user attributes...');
      final attributes = await Amplify.Auth.fetchUserAttributes();
      safePrint('[UserSyncService] ✓ Found ${attributes.length} attributes');

      String? email;
      String? name;

      for (final attr in attributes) {
        final key = attr.userAttributeKey.key;
        if (key == 'email') {
          email = attr.value;
        } else if (key == 'name' || key == 'preferred_username') {
          name = attr.value;
        }
        safePrint('[UserSyncService]   - $key: ${attr.value}');
      }

      email ??= cognitoUsername;
      name ??= cognitoUsername.split('@').first;

      safePrint('[UserSyncService] ✓ Resolved email: $email, name: $name');

      // 3. AppUser 조회 (API 사용 - 실시간 데이터)
      safePrint('[UserSyncService] Step 3: Checking if AppUser exists...');

      const listUsersQuery = '''
        query ListAppUsers(\$filter: ModelAppUserFilterInput) {
          listAppUsers(filter: \$filter) {
            items {
              id
              cognitoUsername
              name
              email
            }
          }
        }
      ''';

      final usersResponse = await Amplify.API.query(
        request: GraphQLRequest<String>(
          document: listUsersQuery,
          variables: {
            'filter': {
              'email': {'eq': email.toLowerCase()}
            }
          },
        ),
      ).response;

      if (usersResponse.data == null) {
        throw Exception('Failed to query AppUser');
      }

      final usersJson = json.decode(usersResponse.data!);
      final usersList = usersJson['listAppUsers']['items'] as List;

      // 4. AppUser가 이미 존재하면 스킵
      if (usersList.isNotEmpty) {
        final existingUser = usersList.first;
        final existingUserId = existingUser['id'] as String;
        safePrint('[UserSyncService] ✓ AppUser already exists: id=$existingUserId');
        safePrint('========================================');
        safePrint('');
        return SyncResult(
          success: true,
          message: 'AppUser already exists',
          isNew: false,
        );
      }

      // 5. AppUser 생성
      safePrint('[UserSyncService] Step 4: Creating AppUser...');

      const createUserMutation = '''
        mutation CreateAppUser(\$input: CreateAppUserInput!) {
          createAppUser(input: \$input) {
            id
            cognitoUsername
            name
            email
          }
        }
      ''';

      final createResponse = await Amplify.API.mutate(
        request: GraphQLRequest<String>(
          document: createUserMutation,
          variables: {
            'input': {
              'id': userId,
              'cognitoUsername': cognitoUsername,
              'name': name,
              'email': email.toLowerCase(),
            }
          },
        ),
      ).response;

      if (createResponse.data == null) {
        throw Exception('Failed to create AppUser');
      }

      final createdUserJson = json.decode(createResponse.data!);
      final createdUserId = createdUserJson['createAppUser']['id'];

      safePrint('[UserSyncService] ✓ AppUser created successfully!');
      safePrint('[UserSyncService]   - id: $createdUserId');
      safePrint('[UserSyncService]   - email: $email');
      safePrint('[UserSyncService]   - name: $name');
      safePrint('========================================');
      safePrint('');

      return SyncResult(
        success: true,
        message: 'AppUser created successfully',
        isNew: true,
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


  /// 모든 Cognito 사용자를 DynamoDB에 마이그레이션 (관리자 기능)
  ///
  /// 주의: 이 기능은 Cognito Admin API를 사용하므로
  /// IAM 권한이 필요합니다. 일반적으로 서버측에서 실행해야 합니다.
  Future<MigrationResult> migrateAllUsers() async {
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
