// lib/features/academy/data/repositories/academy_member_aws_repository.dart
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../models/AcademyMember.dart';

/// AWS DynamoDB AcademyMember 테이블과 연동하는 Repository
///
/// DynamoDB 테이블: AcademyMember-{apiId}-{env}
/// 직접 GraphQL 쿼리 사용 (스키마에 타입이 없어도 테이블은 존재)
class AcademyMemberAwsRepository {
  /// 유저 ID로 소속 조회 (AcademyMember 테이블에서 직접 조회)
  ///
  /// [userId] - User 테이블의 id (예: "user-owner-001")
  Future<List<AcademyMember>> getMembershipsByUserId(String userId) async {
    try {
      safePrint('[AcademyMemberAwsRepository] ========== getMembershipsByUserId START ==========');
      safePrint('[AcademyMemberAwsRepository] Querying AcademyMember table for userId: $userId');

      // GraphQL로 AcademyMember 테이블 직접 쿼리
      // 스키마에 타입이 없어도 테이블이 존재하면 쿼리 가능
      const query = '''
        query ListAcademyMembers(\$filter: ModelAcademyMemberFilterInput) {
          listAcademyMembers(filter: \$filter) {
            items {
              id
              academyId
              userId
              role
              createdAt
              updatedAt
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: query,
        variables: {
          'filter': {
            'userId': {'eq': userId}
          }
        },
      );

      safePrint('[AcademyMemberAwsRepository] Sending GraphQL query...');
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[AcademyMemberAwsRepository] GraphQL errors: ${response.errors}');
        // GraphQL 스키마에 타입이 없으면 에러 발생 - fallback 처리
        return _fallbackGetMembershipsByUserId(userId);
      }

      if (response.data != null) {
        final data = jsonDecode(response.data!) as Map<String, dynamic>;
        final items = data['listAcademyMembers']?['items'] as List<dynamic>?;

        if (items != null && items.isNotEmpty) {
          final memberships = items.map((item) {
            final json = item as Map<String, dynamic>;
            return AcademyMember.fromJson(json);
          }).toList();

          safePrint('[AcademyMemberAwsRepository] Found ${memberships.length} memberships');
          for (final m in memberships) {
            safePrint('[AcademyMemberAwsRepository]   - academyId: ${m.academyId}, role: ${m.role}');
          }
          safePrint('[AcademyMemberAwsRepository] ========== getMembershipsByUserId END (success) ==========');
          return memberships;
        }
      }

      safePrint('[AcademyMemberAwsRepository] No memberships found for userId: $userId');
      safePrint('[AcademyMemberAwsRepository] ========== getMembershipsByUserId END (empty) ==========');
      return [];
    } catch (e, stackTrace) {
      safePrint('[AcademyMemberAwsRepository] ========== getMembershipsByUserId ERROR ==========');
      safePrint('[AcademyMemberAwsRepository] Error: $e');
      safePrint('[AcademyMemberAwsRepository] Stack trace: $stackTrace');
      // 에러 발생시 fallback
      return _fallbackGetMembershipsByUserId(userId);
    }
  }

  /// Fallback: GraphQL 쿼리 실패시 기본값 반환
  List<AcademyMember> _fallbackGetMembershipsByUserId(String userId) {
    safePrint('[AcademyMemberAwsRepository] Using fallback - returning default membership');
    return [
      AcademyMember(
        id: 'membership-$userId',
        academyId: 'default-academy',
        userId: userId,
        role: 'student', // Cognito 그룹에서 실제 역할 결정
      ),
    ];
  }

  /// 학원 ID로 멤버 조회
  Future<List<AcademyMember>> getMembersByAcademyId(String academyId) async {
    try {
      safePrint('[AcademyMemberAwsRepository] Fetching members for academyId: $academyId');

      const query = '''
        query ListAcademyMembers(\$filter: ModelAcademyMemberFilterInput) {
          listAcademyMembers(filter: \$filter) {
            items {
              id
              academyId
              userId
              role
              createdAt
              updatedAt
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: query,
        variables: {
          'filter': {
            'academyId': {'eq': academyId}
          }
        },
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[AcademyMemberAwsRepository] getMembersByAcademyId errors: ${response.errors}');
        return [];
      }

      if (response.data != null) {
        final data = jsonDecode(response.data!) as Map<String, dynamic>;
        final items = data['listAcademyMembers']?['items'] as List<dynamic>?;

        if (items != null) {
          final members = items.map((item) {
            final json = item as Map<String, dynamic>;
            return AcademyMember.fromJson(json);
          }).toList();

          safePrint('[AcademyMemberAwsRepository] Found ${members.length} members');
          return members;
        }
      }

      return [];
    } catch (e, stackTrace) {
      safePrint('[AcademyMemberAwsRepository] getMembersByAcademyId error: $e');
      safePrint('[AcademyMemberAwsRepository] Stack trace: $stackTrace');
      return [];
    }
  }

  /// ID로 멤버십 조회
  Future<AcademyMember?> getById(String id) async {
    try {
      safePrint('[AcademyMemberAwsRepository] Fetching membership by ID: $id');

      const query = '''
        query GetAcademyMember(\$id: ID!) {
          getAcademyMember(id: \$id) {
            id
            academyId
            userId
            role
            createdAt
            updatedAt
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: query,
        variables: {'id': id},
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[AcademyMemberAwsRepository] getById errors: ${response.errors}');
        return null;
      }

      if (response.data != null) {
        final data = jsonDecode(response.data!) as Map<String, dynamic>;
        final memberJson = data['getAcademyMember'] as Map<String, dynamic>?;

        if (memberJson != null) {
          return AcademyMember.fromJson(memberJson);
        }
      }

      safePrint('[AcademyMemberAwsRepository] Membership not found with ID: $id');
      return null;
    } catch (e, stackTrace) {
      safePrint('[AcademyMemberAwsRepository] getById error: $e');
      safePrint('[AcademyMemberAwsRepository] Stack trace: $stackTrace');
      return null;
    }
  }

  /// 멤버 추가
  Future<AcademyMember?> addMember({
    required String academyId,
    required String userId,
    required String role,
  }) async {
    try {
      safePrint('[AcademyMemberAwsRepository] Adding member: userId=$userId, academyId=$academyId, role=$role');

      const mutation = '''
        mutation CreateAcademyMember(\$input: CreateAcademyMemberInput!) {
          createAcademyMember(input: \$input) {
            id
            academyId
            userId
            role
            createdAt
            updatedAt
          }
        }
      ''';

      final now = TemporalDateTime.now().format();
      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {
          'input': {
            'academyId': academyId,
            'userId': userId,
            'role': role,
            'createdAt': now,
          }
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[AcademyMemberAwsRepository] addMember errors: ${response.errors}');
        return null;
      }

      if (response.data != null) {
        final data = jsonDecode(response.data!) as Map<String, dynamic>;
        final memberJson = data['createAcademyMember'] as Map<String, dynamic>?;

        if (memberJson != null) {
          safePrint('[AcademyMemberAwsRepository] Member added successfully');
          return AcademyMember.fromJson(memberJson);
        }
      }

      return null;
    } catch (e, stackTrace) {
      safePrint('[AcademyMemberAwsRepository] addMember error: $e');
      safePrint('[AcademyMemberAwsRepository] Stack trace: $stackTrace');
      return null;
    }
  }

  /// 멤버 제거
  Future<bool> removeMember(String id) async {
    try {
      safePrint('[AcademyMemberAwsRepository] Removing member: $id');

      const mutation = '''
        mutation DeleteAcademyMember(\$input: DeleteAcademyMemberInput!) {
          deleteAcademyMember(input: \$input) {
            id
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {
          'input': {'id': id}
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[AcademyMemberAwsRepository] removeMember errors: ${response.errors}');
        return false;
      }

      safePrint('[AcademyMemberAwsRepository] Member removed successfully');
      return true;
    } catch (e, stackTrace) {
      safePrint('[AcademyMemberAwsRepository] removeMember error: $e');
      safePrint('[AcademyMemberAwsRepository] Stack trace: $stackTrace');
      return false;
    }
  }

  /// 멤버 역할 변경
  Future<AcademyMember?> updateMemberRole(String id, String newRole) async {
    try {
      safePrint('[AcademyMemberAwsRepository] Updating member role: $id -> $newRole');

      const mutation = '''
        mutation UpdateAcademyMember(\$input: UpdateAcademyMemberInput!) {
          updateAcademyMember(input: \$input) {
            id
            academyId
            userId
            role
            createdAt
            updatedAt
          }
        }
      ''';

      final now = TemporalDateTime.now().format();
      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {
          'input': {
            'id': id,
            'role': newRole,
            'updatedAt': now,
          }
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[AcademyMemberAwsRepository] updateMemberRole errors: ${response.errors}');
        return null;
      }

      if (response.data != null) {
        final data = jsonDecode(response.data!) as Map<String, dynamic>;
        final memberJson = data['updateAcademyMember'] as Map<String, dynamic>?;

        if (memberJson != null) {
          safePrint('[AcademyMemberAwsRepository] Member role updated successfully');
          return AcademyMember.fromJson(memberJson);
        }
      }

      return null;
    } catch (e, stackTrace) {
      safePrint('[AcademyMemberAwsRepository] updateMemberRole error: $e');
      safePrint('[AcademyMemberAwsRepository] Stack trace: $stackTrace');
      return null;
    }
  }

  /// 모든 멤버십 조회 (관리자용)
  Future<List<AcademyMember>> getAll() async {
    try {
      safePrint('[AcademyMemberAwsRepository] Fetching all memberships...');

      const query = '''
        query ListAcademyMembers {
          listAcademyMembers {
            items {
              id
              academyId
              userId
              role
              createdAt
              updatedAt
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(document: query);
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[AcademyMemberAwsRepository] getAll errors: ${response.errors}');
        return [];
      }

      if (response.data != null) {
        final data = jsonDecode(response.data!) as Map<String, dynamic>;
        final items = data['listAcademyMembers']?['items'] as List<dynamic>?;

        if (items != null) {
          final memberships = items.map((item) {
            final json = item as Map<String, dynamic>;
            return AcademyMember.fromJson(json);
          }).toList();

          safePrint('[AcademyMemberAwsRepository] Found ${memberships.length} memberships');
          return memberships;
        }
      }

      return [];
    } catch (e, stackTrace) {
      safePrint('[AcademyMemberAwsRepository] getAll error: $e');
      safePrint('[AcademyMemberAwsRepository] Stack trace: $stackTrace');
      return [];
    }
  }
}
