import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';

import '../../../models/Assignment.dart';
import '../../../models/AssignmentStatus.dart';

class AssignmentPage {
  final List<Assignment> items;
  final String? nextToken;
  const AssignmentPage({required this.items, required this.nextToken});
}

class AssignmentRepository {
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

  Future<AssignmentPage> listAssignmentsByTeacherPaged({
    required String teacherUsername,
    required int limit,
    required String? nextToken,
  }) async {
    const doc = r'''
      query AssignmentsByTeacherV3($teacherUsername: String!, $limit: Int, $nextToken: String) {
        assignmentsByTeacherV3(teacherUsername: $teacherUsername, limit: $limit, nextToken: $nextToken) {
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
        'teacherUsername': teacherUsername,
        'limit': limit,
        'nextToken': nextToken,
      },
    );

    final resp = await Amplify.API.query(request: req).response;
    _throwIfHasErrors(resp);

    if (resp.data == null) return const AssignmentPage(items: [], nextToken: null);

    final map = jsonDecode(resp.data!) as Map<String, dynamic>;
    final data = (map['data'] ?? map) as Map<String, dynamic>;
    final conn = (data['assignmentsByTeacherV3'] ?? {}) as Map<String, dynamic>;

    final rawItems = (conn['items'] as List?) ?? const [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map((e) => Assignment.fromJson(e))
        .toList();

    final token = conn['nextToken'] as String?;
    return AssignmentPage(items: items, nextToken: token);
  }

  Future<AssignmentPage> listAssignmentsOwnerOnlyPaged({
    required int limit,
    required String? nextToken,
  }) async {
    // OwnerOnly은 서버 @auth로 판정. 클라는 listAssignments 호출만.
    // ✅ ModelQueries.list 쓰지 말 것(_version/_deleted/_lastChangedAt 메타필드 이슈 회피)
    const doc = r'''
      query ListAssignmentsOwnerOnly($limit: Int, $nextToken: String) {
        listAssignments(limit: $limit, nextToken: $nextToken) {
          items { ''' +
        _assignmentFields +
        r''' }
          nextToken
        }
      }
    ''';

    final req = GraphQLRequest<String>(
      document: doc,
      variables: {'limit': limit, 'nextToken': nextToken},
    );

    final resp = await Amplify.API.query(request: req).response;
    _throwIfHasErrors(resp);

    if (resp.data == null) return const AssignmentPage(items: [], nextToken: null);

    final map = jsonDecode(resp.data!) as Map<String, dynamic>;
    final data = (map['data'] ?? map) as Map<String, dynamic>;
    final conn = (data['listAssignments'] ?? {}) as Map<String, dynamic>;

    final rawItems = (conn['items'] as List?) ?? const [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map((e) => Assignment.fromJson(e))
        .toList();

    final token = conn['nextToken'] as String?;
    return AssignmentPage(items: items, nextToken: token);
  }

  Future<void> createAssignment({
    required String teacherUsername,
    required String studentUsername,
    required String title,
    String? description,
  }) async {
    const doc = r'''
      mutation CreateAssignment($input: CreateAssignmentInput!) {
        createAssignment(input: $input) { id }
      }
    ''';

    final input = <String, dynamic>{
      'teacherUsername': teacherUsername,
      'studentUsername': studentUsername,
      'title': title,
      'status': AssignmentStatus.ASSIGNED.name,
      if (description != null) 'description': description,
    };

    final req = GraphQLRequest<String>(
      document: doc,
      variables: {'input': input},
    );

    final resp = await Amplify.API.mutate(request: req).response;
    _throwIfHasErrors(resp);
  }

  Future<void> deleteAssignment(String id) async {
    const doc = r'''
      mutation DeleteAssignment($input: DeleteAssignmentInput!) {
        deleteAssignment(input: $input) { id }
      }
    ''';

    final req = GraphQLRequest<String>(
      document: doc,
      variables: {'input': {'id': id}},
    );

    final resp = await Amplify.API.mutate(request: req).response;
    _throwIfHasErrors(resp);
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
        'input': {
          'id': id,
          'status': status.name,
        }
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
