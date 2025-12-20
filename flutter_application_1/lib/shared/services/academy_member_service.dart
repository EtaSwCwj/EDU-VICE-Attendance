// lib/shared/services/academy_member_service.dart
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../models/ModelProvider.dart';

class AcademyMemberService {
  static final AcademyMemberService _instance = AcademyMemberService._internal();
  factory AcademyMemberService() => _instance;
  AcademyMemberService._internal();

  /// 초대를 통한 멤버 생성
  Future<AcademyMember?> createMemberFromInvitation({
    required Invitation invitation,
    required String userId,
  }) async {
    safePrint('[AcademyMemberService] Creating member from invitation');
    safePrint('[AcademyMemberService] academyId=${invitation.academyId}, role=${invitation.role}, userId=$userId');

    try {
      // 이미 해당 학원의 멤버인지 확인
      final existing = await Amplify.DataStore.query(
        AcademyMember.classType,
        where: AcademyMember.ACADEMYID.eq(invitation.academyId)
            .and(AcademyMember.USERID.eq(userId)),
      );

      if (existing.isNotEmpty) {
        safePrint('[AcademyMemberService] User already member of this academy');
        return existing.first;
      }

      final member = AcademyMember(
        academyId: invitation.academyId,
        userId: userId,
        role: invitation.role,
      );

      await Amplify.DataStore.save(member);
      safePrint('[AcademyMemberService] Member created: id=${member.id}');
      return member;
    } catch (e) {
      safePrint('[AcademyMemberService] Error creating member: $e');
      return null;
    }
  }

  /// 유저의 모든 멤버십 조회
  Future<List<AcademyMember>> getMembershipsByUser(String userId) async {
    safePrint('[AcademyMemberService] Fetching memberships for user: $userId');

    try {
      final memberships = await Amplify.DataStore.query(
        AcademyMember.classType,
        where: AcademyMember.USERID.eq(userId),
      );

      safePrint('[AcademyMemberService] Found ${memberships.length} memberships');
      return memberships;
    } catch (e) {
      safePrint('[AcademyMemberService] Error fetching memberships: $e');
      return [];
    }
  }

  /// 학원의 멤버 목록 조회
  Future<List<AcademyMember>> getMembersByAcademy(String academyId, {String? role}) async {
    safePrint('[AcademyMemberService] Fetching members for academy: $academyId, role=$role');

    try {
      final allMembers = await Amplify.DataStore.query(
        AcademyMember.classType,
        where: AcademyMember.ACADEMYID.eq(academyId),
      );

      List<AcademyMember> members;
      if (role != null) {
        members = allMembers.where((m) => m.role == role).toList();
      } else {
        members = allMembers;
      }

      safePrint('[AcademyMemberService] Found ${members.length} members');
      return members;
    } catch (e) {
      safePrint('[AcademyMemberService] Error fetching members: $e');
      return [];
    }
  }
}
