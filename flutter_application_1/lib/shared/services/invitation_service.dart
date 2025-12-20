// lib/shared/services/invitation_service.dart
import 'dart:math';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../models/ModelProvider.dart';

class InvitationService {
  static final InvitationService _instance = InvitationService._internal();
  factory InvitationService() => _instance;
  InvitationService._internal();

  /// 6자리 초대코드 생성 (대문자 + 숫자)
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 혼동 문자 제외 (0,O,1,I)
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// 초대 생성 (원장/선생용)
  Future<Invitation?> createInvitation({
    required String academyId,
    required String role,
    required String createdBy,
    String? targetEmail,
    String? targetStudentId,
  }) async {
    safePrint('[InvitationService] Creating invitation: academyId=$academyId, role=$role');

    try {
      final code = _generateCode();
      final expiresAt = TemporalDateTime(
        DateTime.now().add(const Duration(days: 7)),
      );

      final invitation = Invitation(
        academyId: academyId,
        role: role,
        inviteCode: code,
        targetEmail: targetEmail,
        targetStudentId: targetStudentId,
        createdBy: createdBy,
        expiresAt: expiresAt,
      );

      await Amplify.DataStore.save(invitation);
      safePrint('[InvitationService] Invitation created: code=$code, id=${invitation.id}');
      return invitation;
    } catch (e) {
      safePrint('[InvitationService] Error creating invitation: $e');
      return null;
    }
  }

  /// 초대코드로 초대 조회
  Future<Invitation?> getInvitationByCode(String code) async {
    safePrint('[InvitationService] Looking up invitation: code=$code');

    try {
      final invitations = await Amplify.DataStore.query(
        Invitation.classType,
        where: Invitation.INVITECODE.eq(code.toUpperCase()),
      );

      if (invitations.isEmpty) {
        safePrint('[InvitationService] Invitation not found');
        return null;
      }

      final invitation = invitations.first;

      // 만료 체크
      if (invitation.expiresAt.getDateTimeInUtc().isBefore(DateTime.now().toUtc())) {
        safePrint('[InvitationService] Invitation expired');
        return null;
      }

      // 이미 사용됨 체크
      if (invitation.usedAt != null) {
        safePrint('[InvitationService] Invitation already used');
        return null;
      }

      safePrint('[InvitationService] Valid invitation found: role=${invitation.role}');
      return invitation;
    } catch (e) {
      safePrint('[InvitationService] Error looking up invitation: $e');
      return null;
    }
  }

  /// 초대 사용 처리
  Future<bool> useInvitation({
    required Invitation invitation,
    required String userId,
  }) async {
    safePrint('[InvitationService] Using invitation: id=${invitation.id}, userId=$userId');

    try {
      final updated = invitation.copyWith(
        usedAt: TemporalDateTime.now(),
        usedBy: userId,
      );

      await Amplify.DataStore.save(updated);
      safePrint('[InvitationService] Invitation marked as used');
      return true;
    } catch (e) {
      safePrint('[InvitationService] Error using invitation: $e');
      return false;
    }
  }

  /// 학원의 초대 목록 조회
  Future<List<Invitation>> getInvitationsByAcademy(String academyId) async {
    safePrint('[InvitationService] Fetching invitations for academy: $academyId');

    try {
      final invitations = await Amplify.DataStore.query(
        Invitation.classType,
        where: Invitation.ACADEMYID.eq(academyId),
      );

      safePrint('[InvitationService] Found ${invitations.length} invitations');
      return invitations;
    } catch (e) {
      safePrint('[InvitationService] Error fetching invitations: $e');
      return [];
    }
  }

  /// 이메일로 받은 초대 목록 조회 (피초대자용)
  Future<List<Invitation>> getInvitationsByTargetEmail(String email) async {
    safePrint('[InvitationService] Fetching invitations for email: $email');

    try {
      final invitations = await Amplify.DataStore.query(
        Invitation.classType,
        where: Invitation.TARGETEMAIL.eq(email.toLowerCase()),
      );

      // 유효한 초대만 필터링 (만료 안 됨 + 사용 안 됨)
      final validInvitations = invitations.where((inv) {
        final notExpired = inv.expiresAt.getDateTimeInUtc().isAfter(DateTime.now().toUtc());
        final notUsed = inv.usedAt == null;
        return notExpired && notUsed;
      }).toList();

      safePrint('[InvitationService] Found ${validInvitations.length} valid invitations for $email');
      return validInvitations;
    } catch (e) {
      safePrint('[InvitationService] Error fetching invitations by email: $e');
      return [];
    }
  }
}
