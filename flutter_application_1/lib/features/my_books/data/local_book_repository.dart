import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:sembast/sembast.dart';
import '../../../data/local/sembast_database.dart';
import '../models/local_book.dart';

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

  /// 등록된 페이지 전체 초기화
  Future<LocalBook> clearRegisteredPages(String bookId) async {
    try {
      safePrint('[LocalBookRepo] 등록된 페이지 전체 초기화: $bookId');
      final book = await getBook(bookId);
      if (book == null) {
        throw Exception('책을 찾을 수 없습니다: $bookId');
      }

      final updatedBook = book.copyWith(
        registeredPages: [],
        updatedAt: DateTime.now(),
      );

      await saveBook(updatedBook);
      safePrint('[LocalBookRepo] 등록된 페이지 초기화 완료');
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
}
