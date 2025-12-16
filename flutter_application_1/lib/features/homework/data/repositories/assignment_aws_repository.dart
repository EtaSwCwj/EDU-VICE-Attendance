// lib/features/homework/data/repositories/assignment_aws_repository.dart
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../../../../models/ModelProvider.dart';

/// AWS DynamoDB와 연동하는 Assignment(숙제) Repository
/// Amplify GraphQL API를 사용하여 Assignment 테이블에 CRUD 수행
class AssignmentAwsRepository {

  /// 선생님별 숙제 목록 조회
  Future<List<Assignment>> getByTeacher(String teacherUsername) async {
    try {
      final request = ModelQueries.list(
        Assignment.classType,
        where: Assignment.TEACHERUSERNAME.eq(teacherUsername),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[AssignmentAwsRepository] getByTeacher errors: ${response.errors}');
        return [];
      }

      final assignments = response.data?.items.whereType<Assignment>().toList() ?? [];
      // 마감일 기준 내림차순 정렬 (클라이언트 측)
      assignments.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return b.dueDate!.compareTo(a.dueDate!);
      });
      return assignments;
    } catch (e) {
      safePrint('[AssignmentAwsRepository] getByTeacher error: $e');
      return [];
    }
  }

  /// 학생별 숙제 목록 조회
  Future<List<Assignment>> getByStudent(String studentUsername) async {
    try {
      final request = ModelQueries.list(
        Assignment.classType,
        where: Assignment.STUDENTUSERNAME.eq(studentUsername),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[AssignmentAwsRepository] getByStudent errors: ${response.errors}');
        return [];
      }

      final assignments = response.data?.items.whereType<Assignment>().toList() ?? [];
      // 마감일 기준 내림차순 정렬 (클라이언트 측)
      assignments.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return b.dueDate!.compareTo(a.dueDate!);
      });
      return assignments;
    } catch (e) {
      safePrint('[AssignmentAwsRepository] getByStudent error: $e');
      return [];
    }
  }

  /// 상태별 숙제 조회 (선생님 기준)
  Future<List<Assignment>> getByTeacherAndStatus(
    String teacherUsername,
    AssignmentStatus status,
  ) async {
    try {
      final request = ModelQueries.list(
        Assignment.classType,
        where: Assignment.TEACHERUSERNAME.eq(teacherUsername)
            .and(Assignment.STATUS.eq(status)),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[AssignmentAwsRepository] getByTeacherAndStatus errors: ${response.errors}');
        return [];
      }

      final assignments = response.data?.items.whereType<Assignment>().toList() ?? [];
      // 마감일 기준 오름차순 정렬 (클라이언트 측)
      assignments.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      return assignments;
    } catch (e) {
      safePrint('[AssignmentAwsRepository] getByTeacherAndStatus error: $e');
      return [];
    }
  }

  /// 상태별 숙제 조회 (학생 기준)
  Future<List<Assignment>> getByStudentAndStatus(
    String studentUsername,
    AssignmentStatus status,
  ) async {
    try {
      final request = ModelQueries.list(
        Assignment.classType,
        where: Assignment.STUDENTUSERNAME.eq(studentUsername)
            .and(Assignment.STATUS.eq(status)),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[AssignmentAwsRepository] getByStudentAndStatus errors: ${response.errors}');
        return [];
      }

      final assignments = response.data?.items.whereType<Assignment>().toList() ?? [];
      // 마감일 기준 오름차순 정렬 (클라이언트 측)
      assignments.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      return assignments;
    } catch (e) {
      safePrint('[AssignmentAwsRepository] getByStudentAndStatus error: $e');
      return [];
    }
  }

  /// ID로 숙제 조회
  Future<Assignment?> getById(String id) async {
    try {
      final request = ModelQueries.get(
        Assignment.classType,
        AssignmentModelIdentifier(id: id),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[AssignmentAwsRepository] getById errors: ${response.errors}');
        return null;
      }

      return response.data;
    } catch (e) {
      safePrint('[AssignmentAwsRepository] getById error: $e');
      return null;
    }
  }

  /// 숙제 생성
  Future<Assignment?> create(Assignment assignment) async {
    try {
      final request = ModelMutations.create(assignment);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[AssignmentAwsRepository] create errors: ${response.errors}');
        return null;
      }

      return response.data;
    } catch (e) {
      safePrint('[AssignmentAwsRepository] create error: $e');
      return null;
    }
  }

  /// 여러 학생에게 동일 숙제 발급 (배치)
  Future<List<Assignment>> createBatch({
    required String title,
    String? description,
    required String teacherUsername,
    required List<String> studentUsernames,
    String? book,
    String? range,
    DateTime? dueDate,
  }) async {
    final createdAssignments = <Assignment>[];

    try {
      for (final studentUsername in studentUsernames) {
        final assignment = Assignment(
          title: title,
          description: description,
          status: AssignmentStatus.ASSIGNED,
          teacherUsername: teacherUsername,
          studentUsername: studentUsername,
          book: book,
          range: range,
          dueDate: dueDate != null ? TemporalDateTime(dueDate) : null,
        );

        final request = ModelMutations.create(assignment);
        final response = await Amplify.API.mutate(request: request).response;

        if (response.data != null) {
          createdAssignments.add(response.data!);
        }
      }
      safePrint('[AssignmentAwsRepository] Created ${createdAssignments.length} assignments');
      return createdAssignments;
    } catch (e) {
      safePrint('[AssignmentAwsRepository] createBatch error: $e');
      return createdAssignments;
    }
  }

  /// 숙제 수정
  Future<Assignment?> update(Assignment assignment) async {
    try {
      final request = ModelMutations.update(assignment);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[AssignmentAwsRepository] update errors: ${response.errors}');
        return null;
      }

      return response.data;
    } catch (e) {
      safePrint('[AssignmentAwsRepository] update error: $e');
      return null;
    }
  }

  /// 숙제 상태 업데이트
  Future<bool> updateStatus(String id, AssignmentStatus status) async {
    try {
      safePrint('[AssignmentAwsRepository] updateStatus called with id: $id, status: $status');

      final existing = await getById(id);
      if (existing == null) {
        safePrint('[AssignmentAwsRepository] updateStatus: Assignment not found with id: $id');
        return false;
      }

      safePrint('[AssignmentAwsRepository] Existing assignment found: ${existing.title}, current status: ${existing.status}');

      final updated = existing.copyWith(status: status);
      safePrint('[AssignmentAwsRepository] Updated assignment status: ${updated.status}');

      final request = ModelMutations.update(updated);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[AssignmentAwsRepository] updateStatus errors: ${response.errors}');
        return false;
      }

      safePrint('[AssignmentAwsRepository] updateStatus success');
      return true;
    } catch (e, stackTrace) {
      safePrint('[AssignmentAwsRepository] updateStatus error: $e');
      safePrint('[AssignmentAwsRepository] Stack trace: $stackTrace');
      return false;
    }
  }

  /// 숙제 삭제
  Future<bool> delete(String id) async {
    try {
      final existing = await getById(id);
      if (existing == null) return false;

      final request = ModelMutations.delete(existing);
      final response = await Amplify.API.mutate(request: request).response;

      return !response.hasErrors;
    } catch (e) {
      safePrint('[AssignmentAwsRepository] delete error: $e');
      return false;
    }
  }

  /// 마감 임박 숙제 조회 (선생님 기준, 3일 이내)
  Future<List<Assignment>> getDueSoon(String teacherUsername) async {
    try {
      final now = DateTime.now();
      final threeDaysLater = now.add(const Duration(days: 3));

      // 선생님의 미완료 숙제 전체 조회 후 클라이언트 측에서 필터링
      final request = ModelQueries.list(
        Assignment.classType,
        where: Assignment.TEACHERUSERNAME.eq(teacherUsername)
            .and(Assignment.STATUS.ne(AssignmentStatus.DONE)),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[AssignmentAwsRepository] getDueSoon errors: ${response.errors}');
        return [];
      }

      final assignments = response.data?.items.whereType<Assignment>().toList() ?? [];

      // 마감일이 3일 이내인 것만 필터링
      final filtered = assignments.where((a) {
        if (a.dueDate == null) return false;
        final dueDateTime = a.dueDate!.getDateTimeInUtc();
        return dueDateTime.isBefore(threeDaysLater);
      }).toList();

      // 마감일 기준 오름차순 정렬
      filtered.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

      return filtered;
    } catch (e) {
      safePrint('[AssignmentAwsRepository] getDueSoon error: $e');
      return [];
    }
  }

  /// 미완료 숙제 개수 (학생별)
  Future<int> getPendingCount(String studentUsername) async {
    try {
      final request = ModelQueries.list(
        Assignment.classType,
        where: Assignment.STUDENTUSERNAME.eq(studentUsername)
            .and(Assignment.STATUS.ne(AssignmentStatus.DONE)),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[AssignmentAwsRepository] getPendingCount errors: ${response.errors}');
        return 0;
      }

      return response.data?.items.whereType<Assignment>().length ?? 0;
    } catch (e) {
      safePrint('[AssignmentAwsRepository] getPendingCount error: $e');
      return 0;
    }
  }
}

/// AssignmentStatus를 한글 문자열로 변환
String assignmentStatusToKorean(AssignmentStatus status) {
  switch (status) {
    case AssignmentStatus.ASSIGNED:
      return '발급됨';
    case AssignmentStatus.IN_PROGRESS:
      return '진행중';
    case AssignmentStatus.DONE:
      return '완료';
  }
}

/// 한글 문자열을 AssignmentStatus로 변환
AssignmentStatus? assignmentStatusFromKorean(String korean) {
  switch (korean) {
    case '발급됨':
      return AssignmentStatus.ASSIGNED;
    case '진행중':
      return AssignmentStatus.IN_PROGRESS;
    case '완료':
      return AssignmentStatus.DONE;
    default:
      return null;
  }
}
