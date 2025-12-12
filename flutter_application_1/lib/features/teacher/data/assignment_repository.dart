import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart'; // <-- ModelQueries, ModelMutations 여기에 있음
import '../../../models/ModelProvider.dart';

class AssignmentRepository {
  /// 교사가 배정한 과제 목록 (teacherUsername 필터)
  Future<List<Assignment>> listAssignmentsByTeacher({
    required String teacherUsername,
  }) async {
    final req = ModelQueries.list(
      Assignment.classType,
      where: Assignment.TEACHERUSERNAME.eq(teacherUsername),
    );
    final res = await Amplify.API.query(request: req).response;
    if (res.data == null) return [];
    return res.data!.items.whereType<Assignment>().toList();
  }

  /// owner-only 규칙으로 서버에서 필터된 "내 과제" 목록
  Future<List<Assignment>> listAssignmentsOwnerOnly() async {
    final req = ModelQueries.list(Assignment.classType);
    final res = await Amplify.API.query(request: req).response;
    if (res.data == null) return [];
    return res.data!.items.whereType<Assignment>().toList();
  }

  /// 과제 생성
  Future<void> createAssignment({
    required String teacherUsername,
    required String studentUsername,
    required String title,
    String? description,
  }) async {
    final item = Assignment(
      teacherUsername: teacherUsername,
      studentUsername: studentUsername,
      title: title,
      description: description,
      status: AssignmentStatus.ASSIGNED,
    );
    final req = ModelMutations.create(item);
    await Amplify.API.mutate(request: req).response;
  }

  /// 과제 삭제(id만으로)
  Future<void> deleteAssignment(String id) async {
    // 필수 필드 있는 모델은 인스턴스 생성 대신 deleteById 사용
    final req = ModelMutations.deleteById(
      Assignment.classType,
      AssignmentModelIdentifier(id: id),
    );
    await Amplify.API.mutate(request: req).response;
  }
}
