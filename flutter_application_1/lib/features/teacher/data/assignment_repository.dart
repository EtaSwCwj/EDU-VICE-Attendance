import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../../../models/ModelProvider.dart';

class PagedResult<T> {
  final List<T> items;
  final String? nextToken;
  const PagedResult({required this.items, required this.nextToken});
}

class AssignmentRepository {
  Future<List<Assignment>> listAssignmentsByTeacher({
    required String teacherUsername,
  }) async {
    final req = ModelQueries.list(
      Assignment.classType,
      where: Assignment.TEACHERUSERNAME.eq(teacherUsername),
    );
    final res = await Amplify.API.query(request: req).response;

    if (res.errors.isNotEmpty) {
      throw Exception(_errorsToText(res.errors));
    }
    if (res.data == null) return [];
    return res.data!.items.whereType<Assignment>().toList();
  }

  Future<List<Assignment>> listAssignmentsOwnerOnly() async {
    final req = ModelQueries.list(Assignment.classType);
    final res = await Amplify.API.query(request: req).response;

    if (res.errors.isNotEmpty) {
      throw Exception(_errorsToText(res.errors));
    }
    if (res.data == null) return [];
    return res.data!.items.whereType<Assignment>().toList();
  }

  /// ✅ 페이지네이션: teacherUsername 필터
  /// - 주의: 이 프로젝트 스키마에는 _version/_deleted/_lastChangedAt 없음 → 쿼리에서 제거
  Future<PagedResult<Assignment>> listAssignmentsByTeacherPaged({
    required String teacherUsername,
    required int limit,
    required String? nextToken,
  }) async {
    const query = r'''
      query ListAssignments($filter: ModelAssignmentFilterInput, $limit: Int, $nextToken: String) {
        listAssignments(filter: $filter, limit: $limit, nextToken: $nextToken) {
          items {
            id
            teacherUsername
            studentUsername
            title
            description
            status
            dueDate
            createdAt
            updatedAt
            __typename
          }
          nextToken
          __typename
        }
      }
    ''';

    final variables = <String, dynamic>{
      'filter': {
        'teacherUsername': {'eq': teacherUsername}
      },
      'limit': limit,
      'nextToken': nextToken,
    };

    final req = GraphQLRequest<String>(
      document: query,
      variables: variables,
      decodePath: null,
    );

    final res = await Amplify.API.query(request: req).response;
    if (res.errors.isNotEmpty) {
      throw Exception(_errorsToText(res.errors));
    }

    return _parseListAssignments(res.data);
  }

  /// ✅ 페이지네이션: owner-only 목록
  Future<PagedResult<Assignment>> listAssignmentsOwnerOnlyPaged({
    required int limit,
    required String? nextToken,
  }) async {
    const query = r'''
      query ListAssignments($limit: Int, $nextToken: String) {
        listAssignments(limit: $limit, nextToken: $nextToken) {
          items {
            id
            teacherUsername
            studentUsername
            title
            description
            status
            dueDate
            createdAt
            updatedAt
            __typename
          }
          nextToken
          __typename
        }
      }
    ''';

    final variables = <String, dynamic>{
      'limit': limit,
      'nextToken': nextToken,
    };

    final req = GraphQLRequest<String>(
      document: query,
      variables: variables,
      decodePath: null,
    );

    final res = await Amplify.API.query(request: req).response;
    if (res.errors.isNotEmpty) {
      throw Exception(_errorsToText(res.errors));
    }

    return _parseListAssignments(res.data);
  }

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
    final res = await Amplify.API.mutate(request: req).response;

    if (res.errors.isNotEmpty) {
      throw Exception(_errorsToText(res.errors));
    }
  }

  Future<void> deleteAssignment(String id) async {
    final req = ModelMutations.deleteById(
      Assignment.classType,
      AssignmentModelIdentifier(id: id),
    );
    final res = await Amplify.API.mutate(request: req).response;

    if (res.errors.isNotEmpty) {
      throw Exception(_errorsToText(res.errors));
    }
  }

  // ----------------- helpers -----------------

  String _errorsToText(List<GraphQLResponseError> errors) {
    return errors.map((e) => e.message).join(' | ');
  }

  /// 응답 형태 방어 파서
  PagedResult<Assignment> _parseListAssignments(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const PagedResult(items: <Assignment>[], nextToken: null);
    }

    Map<String, dynamic> root;
    try {
      root = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      safePrint('[AssignmentRepository] jsonDecode failed');
      safePrint(raw);
      throw Exception('jsonDecode failed: $e');
    }

    // { "data": { "listAssignments": {...} } }
    final data = root['data'];
    if (data is Map<String, dynamic>) {
      final la = data['listAssignments'];
      if (la is Map<String, dynamic>) {
        return _parseListAssignmentsObject(la);
      }
    }

    // { "listAssignments": {...} }
    final la2 = root['listAssignments'];
    if (la2 is Map<String, dynamic>) {
      return _parseListAssignmentsObject(la2);
    }

    // root 자체가 listAssignments 객체
    if (root.containsKey('items') && root['items'] is List) {
      return _parseListAssignmentsObject(root);
    }

    safePrint('[AssignmentRepository] Unexpected response shape');
    safePrint(raw);
    throw Exception('Unexpected response shape (listAssignments not found)');
  }

  PagedResult<Assignment> _parseListAssignmentsObject(Map<String, dynamic> la) {
    final itemsRaw = (la['items'] as List<dynamic>? ?? <dynamic>[]);
    final items = <Assignment>[];

    for (final it in itemsRaw) {
      if (it is Map<String, dynamic>) {
        items.add(Assignment.fromJson(it));
      }
    }

    final token = la['nextToken'] as String?;
    return PagedResult(items: items, nextToken: token);
  }
}
