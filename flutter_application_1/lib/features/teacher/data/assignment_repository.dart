import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../../../models/ModelProvider.dart';

/// ✅ 교사 전용: 과제(Assignment) 조회/갱신
class AssignmentRepository {
  Future<List<Assignment>> listByTeacher({
    required String teacherUsername,
    int limit = 50,
  }) async {
    // ⚠️ 단순 where 예시. V3 인덱스(raw GraphQL) 붙일 땐 커스텀 쿼리로 교체 예정.
    final request = ModelQueries.list<Assignment>(
      Assignment.classType,
      where: Assignment.TEACHERUSERNAME.eq(teacherUsername),
      limit: limit,
    );

    final res = await Amplify.API.query(request: request).response;
    if (res.errors.isNotEmpty) {
      throw Exception(res.errors.map((e) => e.message).join(', '));
    }
    return res.data?.items.whereType<Assignment>().toList() ?? [];
  }

  Future<Assignment> updateStatus({
    required Assignment assignment,
    required AssignmentStatus status,
  }) async {
    final updated = assignment.copyWith(status: status);
    final req = ModelMutations.update<Assignment>(updated);
    final res = await Amplify.API.mutate(request: req).response;
    if (res.errors.isNotEmpty || res.data == null) {
      throw Exception(res.errors.isNotEmpty ? res.errors.first.message : 'null data');
    }
    return res.data!;
  }
}
