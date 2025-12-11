import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart'; // ModelQueries / ModelMutations
import '../../../models/ModelProvider.dart';

/// 교사용 과제 CRUD + 목록
class AssignmentRepository {
  /// 교사가 배정한 과제 목록 (페이징 미포함: 필요 시 이후 단계에서 확장)
  Future<List<Assignment>> listByTeacher({
    required String teacherUsername,
    int limit = 20,
  }) async {
    final req = ModelQueries.list<Assignment>(
      Assignment.classType,
      where: Assignment.TEACHERUSERNAME.eq(teacherUsername),
      limit: limit,
    );
    final res = await Amplify.API.query(request: req).response;
    _throwIfError(res);
    return res.data?.items.whereType<Assignment>().toList() ?? <Assignment>[];
  }

  /// 학생 기준 목록 (다음 단계에서 사용, 페이징 미포함)
  Future<List<Assignment>> listByStudent({
    required String studentUsername,
    int limit = 20,
  }) async {
    final req = ModelQueries.list<Assignment>(
      Assignment.classType,
      where: Assignment.STUDENTUSERNAME.eq(studentUsername),
      limit: limit,
    );
    final res = await Amplify.API.query(request: req).response;
    _throwIfError(res);
    return res.data?.items.whereType<Assignment>().toList() ?? <Assignment>[];
  }

  /// 생성
  Future<Assignment> create({
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
    final res = await Amplify.API.mutate(request: req).response;
    _throwIfError(res);
    return res.data!;
  }

  /// 상태 변경
  Future<Assignment> updateStatus({
    required Assignment assignment,
    required AssignmentStatus status,
  }) async {
    final updated = assignment.copyWith(status: status);
    final req = ModelMutations.update(updated);
    final res = await Amplify.API.mutate(request: req).response;
    _throwIfError(res);
    return res.data!;
  }

  /// 삭제
  Future<void> delete({required Assignment assignment}) async {
    final req = ModelMutations.delete(assignment);
    final res = await Amplify.API.mutate(request: req).response;
    _throwIfError(res);
  }

  void _throwIfError(GraphQLResponse<dynamic> res) {
    if (res.errors.isNotEmpty) {
      final msg = res.errors.map((e) => e.message).join('; ');
      throw Exception(msg);
    }
  }
}
