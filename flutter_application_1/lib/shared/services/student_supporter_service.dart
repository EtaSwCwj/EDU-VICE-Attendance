// lib/shared/services/student_supporter_service.dart
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../models/ModelProvider.dart';

class StudentSupporterService {
  static final StudentSupporterService _instance = StudentSupporterService._internal();
  factory StudentSupporterService() => _instance;
  StudentSupporterService._internal();

  /// 서포터 연결 생성
  Future<StudentSupporter?> createSupporter({
    required String studentMemberId,
    required String supporterUserId,
    required String academyId,
    String? relationship,
  }) async {
    safePrint('[StudentSupporterService] Creating supporter link');
    safePrint('[StudentSupporterService] studentMemberId=$studentMemberId, supporterUserId=$supporterUserId');

    try {
      // 이미 연결되어 있는지 확인
      final allLinks = await Amplify.DataStore.query(
        StudentSupporter.classType,
        where: StudentSupporter.STUDENTMEMBERID.eq(studentMemberId),
      );

      final existing = allLinks.where((link) => link.supporterUserId == supporterUserId).toList();

      if (existing.isNotEmpty) {
        safePrint('[StudentSupporterService] Already linked');
        return existing.first;
      }

      // 학생당 서포터 2명 제한 체크
      final supporterCount = allLinks.length;

      if (supporterCount >= 2) {
        safePrint('[StudentSupporterService] Max supporters reached (2)');
        return null;
      }

      final supporter = StudentSupporter(
        studentMemberId: studentMemberId,
        supporterUserId: supporterUserId,
        academyId: academyId,
        relationship: relationship,
      );

      await Amplify.DataStore.save(supporter);
      safePrint('[StudentSupporterService] Supporter created: id=${supporter.id}');
      return supporter;
    } catch (e) {
      safePrint('[StudentSupporterService] Error creating supporter: $e');
      return null;
    }
  }

  /// 서포터가 볼 수 있는 학생 목록
  Future<List<StudentSupporter>> getStudentsBySupporter(String supporterUserId) async {
    safePrint('[StudentSupporterService] Fetching students for supporter: $supporterUserId');

    try {
      final links = await Amplify.DataStore.query(
        StudentSupporter.classType,
        where: StudentSupporter.SUPPORTERUSERID.eq(supporterUserId),
      );

      safePrint('[StudentSupporterService] Found ${links.length} student links');
      return links;
    } catch (e) {
      safePrint('[StudentSupporterService] Error fetching students: $e');
      return [];
    }
  }

  /// 학생의 서포터 목록
  Future<List<StudentSupporter>> getSupportersByStudent(String studentMemberId) async {
    safePrint('[StudentSupporterService] Fetching supporters for student: $studentMemberId');

    try {
      final supporters = await Amplify.DataStore.query(
        StudentSupporter.classType,
        where: StudentSupporter.STUDENTMEMBERID.eq(studentMemberId),
      );

      safePrint('[StudentSupporterService] Found ${supporters.length} supporters');
      return supporters;
    } catch (e) {
      safePrint('[StudentSupporterService] Error fetching supporters: $e');
      return [];
    }
  }
}
