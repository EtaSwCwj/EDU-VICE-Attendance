import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:sembast/sembast.dart';
import '../../../data/local/sembast_database.dart';
import '../models/local_book.dart';
import '../models/toc_entry.dart';

const String _kBooksStore = 'my_books';

class LocalBookRepository {
  final _store = stringMapStoreFactory.store(_kBooksStore);

  Future<Database> _db() => AppDatabase().database;

  /// 책 저장
  Future<LocalBook> saveBook(LocalBook book) async {
    try {
      safePrint('[LocalBookRepo] 저장: ${book.title} (${book.volumes.length}개 volume)');
      final db = await _db();
      final updatedBook = book.copyWith(updatedAt: DateTime.now());
      await _store.record(book.id).put(db, updatedBook.toJson(), merge: true);
      safePrint('[LocalBookRepo] 저장 완료: ${book.title} (ID: ${book.id})');
      return updatedBook;
    } catch (e) {
      safePrint('[LocalBookRepo] 저장 실패: $e');
      throw Exception('책 저장 실패: $e');
    }
  }

  /// 모든 책 조회
  Future<List<LocalBook>> getBooks() async {
    try {
      safePrint('[LocalBookRepo] 책 목록 조회 중...');
      final db = await _db();
      final snapshots = await _store.find(
        db,
        finder: Finder(
          sortOrders: [SortOrder('createdAt', false)], // 최신순
        ),
      );

      final books = snapshots.map((snap) {
        final map = Map<String, dynamic>.from(snap.value);
        return LocalBook.fromJson(map);
      }).toList();

      safePrint('[LocalBookRepo] 조회: ${books.length}개');
      return books;
    } catch (e) {
      safePrint('[LocalBookRepo] 조회 실패: $e');
      throw Exception('책 목록 조회 실패: $e');
    }
  }

  /// 특정 책 조회
  Future<LocalBook?> getBook(String bookId) async {
    try {
      safePrint('[LocalBookRepo] 책 조회: $bookId');
      final db = await _db();
      final snap = await _store.record(bookId).getSnapshot(db);

      if (snap == null) {
        safePrint('[LocalBookRepo] 책을 찾을 수 없음: $bookId');
        return null;
      }

      final map = Map<String, dynamic>.from(snap.value);
      final book = LocalBook.fromJson(map);
      safePrint('[LocalBookRepo] 조회 완료: ${book.title} (${book.volumes.length}개 volume, 촬영기록: ${book.captureRecords.length}건)');
      return book;
    } catch (e) {
      safePrint('[LocalBookRepo] 조회 실패: $e');
      throw Exception('책 조회 실패: $e');
    }
  }

  /// 책 삭제
  Future<void> deleteBook(String bookId) async {
    try {
      safePrint('[LocalBookRepo] 삭제: $bookId');
      final db = await _db();
      await _store.record(bookId).delete(db);
      safePrint('[LocalBookRepo] 삭제 완료: $bookId');
    } catch (e) {
      safePrint('[LocalBookRepo] 삭제 실패: $e');
      throw Exception('책 삭제 실패: $e');
    }
  }

  /// 책 업데이트
  Future<LocalBook> updateBook(LocalBook book) async {
    try {
      safePrint('[LocalBookRepo] 업데이트: ${book.title}');
      final db = await _db();
      final updatedBook = book.copyWith(updatedAt: DateTime.now());
      await _store.record(book.id).put(db, updatedBook.toJson());
      safePrint('[LocalBookRepo] 업데이트 완료: ${book.title}');
      return updatedBook;
    } catch (e) {
      safePrint('[LocalBookRepo] 업데이트 실패: $e');
      throw Exception('책 업데이트 실패: $e');
    }
  }

  /// 페이지 등록 상태 업데이트
  Future<LocalBook> updateRegisteredPages(String bookId, List<int> pages) async {
    try {
      safePrint('[LocalBookRepo] 페이지 등록 업데이트: $bookId, 페이지: $pages');
      final book = await getBook(bookId);
      if (book == null) {
        throw Exception('책을 찾을 수 없습니다: $bookId');
      }

      // 중복 제거하고 정렬
      final allPages = {...book.registeredPages, ...pages}.toList()..sort();
      final updatedBook = book.copyWith(
        registeredPages: allPages,
        updatedAt: DateTime.now(),
      );

      await saveBook(updatedBook);
      safePrint('[LocalBookRepo] 페이지 등록 완료: 총 ${allPages.length}페이지');
      return updatedBook;
    } catch (e) {
      safePrint('[LocalBookRepo] 페이지 등록 실패: $e');
      throw Exception('페이지 등록 실패: $e');
    }
  }

  /// 등록된 페이지 + 정답 내용 전체 초기화
  Future<LocalBook> clearRegisteredPages(String bookId) async {
    try {
      safePrint('[LocalBookRepo] 등록된 페이지 + 정답 내용 전체 초기화: $bookId');
      final book = await getBook(bookId);
      if (book == null) {
        throw Exception('책을 찾을 수 없습니다: $bookId');
      }

      final updatedBook = book.copyWith(
        registeredPages: [],
        answerContents: {},  // ★ 정답 내용도 함께 초기화
        updatedAt: DateTime.now(),
      );

      await saveBook(updatedBook);
      safePrint('[LocalBookRepo] 등록된 페이지 + 정답 내용 초기화 완료');
      return updatedBook;
    } catch (e) {
      safePrint('[LocalBookRepo] 등록된 페이지 초기화 실패: $e');
      throw Exception('등록된 페이지 초기화 실패: $e');
    }
  }

  /// 촬영 기록 추가
  Future<LocalBook> addCaptureRecord(String bookId, CaptureRecord record) async {
    try {
      safePrint('[LocalBookRepo] 촬영 기록 추가: $bookId, 페이지: ${record.pages}, Volume: ${record.volumeName}');
      final book = await getBook(bookId);
      if (book == null) {
        throw Exception('책을 찾을 수 없습니다: $bookId');
      }

      final newRecords = [...book.captureRecords, record];
      final updatedBook = book.copyWith(
        captureRecords: newRecords,
        updatedAt: DateTime.now(),
      );

      await saveBook(updatedBook);
      safePrint('[LocalBookRepo] 촬영 기록 추가 완료: 총 ${newRecords.length}건');
      return updatedBook;
    } catch (e) {
      safePrint('[LocalBookRepo] 촬영 기록 추가 실패: $e');
      throw Exception('촬영 기록 추가 실패: $e');
    }
  }

  /// 정답 내용과 함께 페이지 등록
  Future<LocalBook> updatePagesWithAnswers(
    String bookId,
    List<int> pages,
    Map<int, String> answerContents,
  ) async {
    try {
      safePrint('[LocalBookRepo] 정답 내용 포함 페이지 등록: $bookId, 페이지: ${pages.length}개, 정답: ${answerContents.length}개');
      final book = await getBook(bookId);
      if (book == null) {
        throw Exception('책을 찾을 수 없습니다: $bookId');
      }

      // 기존 데이터와 병합
      final allPages = {...book.registeredPages, ...pages}.toList()..sort();
      final allAnswers = {...book.answerContents, ...answerContents};

      final updatedBook = book.copyWith(
        registeredPages: allPages,
        answerContents: allAnswers,
        updatedAt: DateTime.now(),
      );

      await saveBook(updatedBook);
      safePrint('[LocalBookRepo] 정답 내용 포함 저장 완료: 총 ${allPages.length}페이지, 정답 ${allAnswers.length}개');
      return updatedBook;
    } catch (e) {
      safePrint('[LocalBookRepo] 정답 내용 저장 실패: $e');
      throw Exception('정답 내용 저장 실패: $e');
    }
  }

  /// 촬영 기록 전체 삭제
  Future<LocalBook> clearCaptureRecords(String bookId) async {
    try {
      safePrint('[LocalBookRepo] 촬영 기록 전체 삭제: $bookId');
      final book = await getBook(bookId);
      if (book == null) {
        throw Exception('책을 찾을 수 없습니다: $bookId');
      }

      final updatedBook = book.copyWith(
        captureRecords: [],
        updatedAt: DateTime.now(),
      );

      await saveBook(updatedBook);
      safePrint('[LocalBookRepo] 촬영 기록 삭제 완료');
      return updatedBook;
    } catch (e) {
      safePrint('[LocalBookRepo] 촬영 기록 삭제 실패: $e');
      throw Exception('촬영 기록 삭제 실패: $e');
    }
  }

  /// 페이지 번호로 해당 단원 찾기
  TocEntry? findUnitForPage(LocalBook book, int page) {
    for (final entry in book.tableOfContents) {
      final start = entry.startPage;
      final end = entry.endPage ?? entry.startPage;
      if (page >= start && page <= end) {
        safePrint('[BookRepo] 페이지 $page → 단원: ${entry.unitName}');
        return entry;
      }
    }
    safePrint('[BookRepo] 페이지 $page → 단원 못 찾음');
    return null;
  }

  /// 정답지에서 특정 문제의 정답 추출
  /// answerContents[page]에서 "번호" 패턴으로 해당 문제 정답 찾기
  String? extractAnswerForProblem(LocalBook book, int page, int problemNumber) {
    final content = book.answerContents[page];
    if (content == null || content.isEmpty) {
      safePrint('[BookRepo] 페이지 $page 정답 없음');
      return null;
    }

    // 패턴: "3 정답내용" 또는 "3. 정답내용" 또는 "3) 정답내용"
    // 다음 문제 번호나 줄바꿈까지 추출
    final pattern = RegExp(
      r'(?:^|\s)' + problemNumber.toString() + r'[\.\)\s]+([^\n]+?)(?=\s*(?:\d+[\.\)\s]|$))',
      multiLine: true,
    );

    final match = pattern.firstMatch(content);
    if (match != null && match.group(1) != null) {
      final answer = match.group(1)!.trim();
      safePrint('[BookRepo] p$page-$problemNumber 정답: $answer');
      return answer;
    }

    safePrint('[BookRepo] p$page-$problemNumber 정답 추출 실패');
    return null;
  }
}
