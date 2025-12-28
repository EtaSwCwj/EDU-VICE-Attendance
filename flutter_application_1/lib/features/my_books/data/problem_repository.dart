import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:sembast/sembast.dart';
import '../../../data/local/sembast_database.dart';
import '../models/problem.dart';

const String _kProblemsStore = 'problems';

/// 문제 저장소
/// - 책별로 분할된 문제들을 관리
class ProblemRepository {
  final _store = stringMapStoreFactory.store(_kProblemsStore);

  Future<Database> _db() => AppDatabase().database;

  /// 문제 저장
  Future<Problem> saveProblem(Problem problem) async {
    try {
      safePrint('[ProblemRepo] 저장: p${problem.page}-q${problem.problemNumber}');
      final db = await _db();
      await _store.record(problem.id).put(db, problem.toJson());
      safePrint('[ProblemRepo] 저장 완료: ${problem.id}');
      return problem;
    } catch (e) {
      safePrint('[ProblemRepo] 저장 실패: $e');
      throw Exception('문제 저장 실패: $e');
    }
  }

  /// 여러 문제 한번에 저장
  Future<List<Problem>> saveProblems(List<Problem> problems) async {
    try {
      safePrint('[ProblemRepo] 일괄 저장: ${problems.length}개');
      final db = await _db();
      
      for (final problem in problems) {
        await _store.record(problem.id).put(db, problem.toJson());
      }
      
      safePrint('[ProblemRepo] 일괄 저장 완료');
      return problems;
    } catch (e) {
      safePrint('[ProblemRepo] 일괄 저장 실패: $e');
      throw Exception('문제 일괄 저장 실패: $e');
    }
  }

  /// 책의 모든 문제 조회
  Future<List<Problem>> getProblemsForBook(String bookId) async {
    try {
      safePrint('[ProblemRepo] 책 문제 조회: $bookId');
      final db = await _db();
      
      // ID가 bookId로 시작하는 문제들 조회
      final snapshots = await _store.find(
        db,
        finder: Finder(
          filter: Filter.custom((record) {
            final id = record['id'] as String?;
            return id != null && id.startsWith(bookId);
          }),
          sortOrders: [
            SortOrder('page'),
            SortOrder('problemNumber'),
          ],
        ),
      );

      final problems = snapshots.map((snap) {
        final map = Map<String, dynamic>.from(snap.value);
        return Problem.fromJson(map);
      }).toList();

      safePrint('[ProblemRepo] 조회 완료: ${problems.length}개');
      return problems;
    } catch (e) {
      safePrint('[ProblemRepo] 조회 실패: $e');
      throw Exception('문제 조회 실패: $e');
    }
  }

  /// 특정 페이지의 문제들 조회
  Future<List<Problem>> getProblemsForPage(String bookId, int page) async {
    try {
      final allProblems = await getProblemsForBook(bookId);
      return allProblems.where((p) => p.page == page).toList();
    } catch (e) {
      safePrint('[ProblemRepo] 페이지 문제 조회 실패: $e');
      throw Exception('페이지 문제 조회 실패: $e');
    }
  }

  /// 문제 삭제
  Future<void> deleteProblem(String problemId) async {
    try {
      safePrint('[ProblemRepo] 삭제: $problemId');
      final db = await _db();
      await _store.record(problemId).delete(db);
      safePrint('[ProblemRepo] 삭제 완료');
    } catch (e) {
      safePrint('[ProblemRepo] 삭제 실패: $e');
      throw Exception('문제 삭제 실패: $e');
    }
  }

  /// 책의 모든 문제 삭제
  Future<void> deleteProblemsForBook(String bookId) async {
    try {
      safePrint('[ProblemRepo] 책 문제 전체 삭제: $bookId');
      final problems = await getProblemsForBook(bookId);
      final db = await _db();
      
      for (final problem in problems) {
        await _store.record(problem.id).delete(db);
      }
      
      safePrint('[ProblemRepo] 삭제 완료: ${problems.length}개');
    } catch (e) {
      safePrint('[ProblemRepo] 전체 삭제 실패: $e');
      throw Exception('문제 전체 삭제 실패: $e');
    }
  }

  /// 문제 업데이트 (정답 체크 등)
  Future<Problem> updateProblem(Problem problem) async {
    try {
      safePrint('[ProblemRepo] 업데이트: ${problem.id}');
      final db = await _db();
      await _store.record(problem.id).put(db, problem.toJson());
      safePrint('[ProblemRepo] 업데이트 완료');
      return problem;
    } catch (e) {
      safePrint('[ProblemRepo] 업데이트 실패: $e');
      throw Exception('문제 업데이트 실패: $e');
    }
  }
}
