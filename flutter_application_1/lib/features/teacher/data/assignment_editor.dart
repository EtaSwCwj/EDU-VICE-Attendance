// lib/features/teacher/data/assignment_editor.dart
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../models/ModelProvider.dart';

/// 과제 편집 전용 경량 서비스.
/// - UI는 나중에 붙이고, 지금은 호출만 되면 동작하도록 구현.
/// - AppSync codegen 스키마의 표준 update/delete 시그니처를 사용.
class AssignmentEditor {
  AssignmentEditor._();

  /// 제목/설명 일부만 수정 (null 은 그대로 유지)
  static Future<Assignment?> updateTitleDesc({
    required String id,
    String? title,
    String? description,
  }) async {
    final input = <String, dynamic>{'id': id};
    if (title != null) input['title'] = title;
    if (description != null) input['description'] = description;

    const doc = r'''
      mutation UpdateAssignment($input: UpdateAssignmentInput!) {
        updateAssignment(input: $input) {
          id
          title
          description
          status
          teacherUsername
          studentUsername
          createdAt
          updatedAt
        }
      }
    ''';

    final req = GraphQLRequest<String>(
      document: doc,
      variables: {'input': input},
    );

    final resp = await Amplify.API.mutate(request: req).response;
    _throwIfHasErrors(resp);
    if (resp.data == null) return null;

    final map = jsonDecode(resp.data!) as Map<String, dynamic>;
    final body = (map['data'] ?? map)['updateAssignment'] as Map<String, dynamic>;
    return Assignment.fromJson(body);
  }

  /// 상태만 변경
  static Future<Assignment?> updateStatus({
    required String id,
    required AssignmentStatus status,
  }) async {
    const doc = r'''
      mutation UpdateAssignment($input: UpdateAssignmentInput!) {
        updateAssignment(input: $input) {
          id
          title
          description
          status
          teacherUsername
          studentUsername
          createdAt
          updatedAt
        }
      }
    ''';

    final req = GraphQLRequest<String>(
      document: doc,
      variables: {
        'input': {
          'id': id,
          // GraphQL Enum 은 문자열 리터럴로 전달 (ex. "ASSIGNED")
          'status': status.name,
        }
      },
    );

    final resp = await Amplify.API.mutate(request: req).response;
    _throwIfHasErrors(resp);
    if (resp.data == null) return null;

    final map = jsonDecode(resp.data!) as Map<String, dynamic>;
    final body = (map['data'] ?? map)['updateAssignment'] as Map<String, dynamic>;
    return Assignment.fromJson(body);
  }

  /// (옵션) ID 로 삭제 – 리포에 이미 있으면 무시해도 됨.
  static Future<bool> deleteById(String id) async {
    const doc = r'''
      mutation DeleteAssignment($input: DeleteAssignmentInput!) {
        deleteAssignment(input: $input) {
          id
        }
      }
    ''';

    final req = GraphQLRequest<String>(
      document: doc,
      variables: {'input': {'id': id}},
    );

    final resp = await Amplify.API.mutate(request: req).response;
    _throwIfHasErrors(resp);
    if (resp.data == null) return false;

    final map = jsonDecode(resp.data!) as Map<String, dynamic>;
    final body = (map['data'] ?? map)['deleteAssignment'];
    return body != null;
  }

  static void _throwIfHasErrors(GraphQLResponse<String> resp) {
    if (resp.errors.isNotEmpty) {
      final msgs = resp.errors.map((e) => e.message).join('; ');
      // NOTE: ApiException 은 직접 new 하지 말고, 단순 Exception 으로 래핑
      throw Exception('GraphQL error: $msgs');
    }
  }
}
