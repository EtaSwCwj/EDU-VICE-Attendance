import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';

import '../../models/Assignment.dart';
import '../../models/AssignmentStatus.dart';

class StudentAssignmentPage {
  final List<Assignment> items;
  final String? nextToken;
  const StudentAssignmentPage({required this.items, required this.nextToken});
}

/// 학생용: 내(studentUsername) 과제 조회 + 상태변경(DONE)
class StudentAssignmentRepository {
  static const _assignmentFields = r'''
    id
    teacherUsername
    studentUsername
    title
    description
    status
    dueDate
    createdAt
    updatedAt
  ''';

  Future<StudentAssignmentPage> listAssignmentsByStudentPaged({
    required String studentUsername,
    required int limit,
    required String? nextToken,
  }) async {
    const doc = r'''
      query AssignmentsByStudentV3($studentUsername: String!, $limit: Int, $nextToken: String) {
        assignmentsByStudentV3(studentUsername: $studentUsername, limit: $limit, nextToken: $nextToken) {
          items { ''' +
        _assignmentFields +
        r''' }
          nextToken
        }
      }
    ''';

    final req = GraphQLRequest<String>(
      document: doc,
      variables: {
        'studentUsername': studentUsername,
        'limit': limit,
        'nextToken': nextToken,
      },
    );

    final resp = await Amplify.API.query(request: req).response;
    _throwIfHasErrors(resp);

    if (resp.data == null) {
      return const StudentAssignmentPage(items: [], nextToken: null);
    }

    final map = jsonDecode(resp.data!) as Map<String, dynamic>;
    final data = (map['data'] ?? map) as Map<String, dynamic>;
    final conn = (data['assignmentsByStudentV3'] ?? {}) as Map<String, dynamic>;

    final rawItems = (conn['items'] as List?) ?? const [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map((e) => Assignment.fromJson(e))
        .toList();

    final token = conn['nextToken'] as String?;
    return StudentAssignmentPage(items: items, nextToken: token);
  }

  Future<void> updateAssignmentStatus({
    required String id,
    required AssignmentStatus status,
  }) async {
    const doc = r'''
      mutation UpdateAssignment($input: UpdateAssignmentInput!) {
        updateAssignment(input: $input) { id status }
      }
    ''';

    final req = GraphQLRequest<String>(
      document: doc,
      variables: {
        'input': {'id': id, 'status': status.name}
      },
    );

    final resp = await Amplify.API.mutate(request: req).response;
    _throwIfHasErrors(resp);
  }

  static void _throwIfHasErrors(GraphQLResponse<String> resp) {
    if (resp.errors.isNotEmpty) {
      final msgs = resp.errors.map((e) => e.message).join(' | ');
      throw Exception('GraphQL error: $msgs');
    }
  }
}
