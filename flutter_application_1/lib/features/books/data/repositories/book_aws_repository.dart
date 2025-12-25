// lib/features/books/data/repositories/book_aws_repository.dart
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../../../../models/ModelProvider.dart';

/// AWS DynamoDB와 연동하는 Book Repository
/// Amplify GraphQL API를 사용하여 Book 테이블에 CRUD 수행
class BookAwsRepository {
  /// 모든 책 조회
  Future<List<Book>> getAll() async {
    try {
      final request = ModelQueries.list(Book.classType);
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[BookAwsRepository] getAll errors: ${response.errors}');
        return [];
      }

      return response.data?.items.whereType<Book>().toList() ?? [];
    } catch (e) {
      safePrint('[BookAwsRepository] getAll error: $e');
      return [];
    }
  }

  /// 과목별 책 조회
  Future<List<Book>> getBySubject(Subject subject) async {
    try {
      final request = ModelQueries.list(
        Book.classType,
        where: Book.SUBJECT.eq(subject),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[BookAwsRepository] getBySubject errors: ${response.errors}');
        return [];
      }

      return response.data?.items.whereType<Book>().toList() ?? [];
    } catch (e) {
      safePrint('[BookAwsRepository] getBySubject error: $e');
      return [];
    }
  }

  /// 학년별 책 조회
  Future<List<Book>> getByGrade(Grade grade) async {
    try {
      final request = ModelQueries.list(
        Book.classType,
        where: Book.GRADE.eq(grade),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[BookAwsRepository] getByGrade errors: ${response.errors}');
        return [];
      }

      return response.data?.items.whereType<Book>().toList() ?? [];
    } catch (e) {
      safePrint('[BookAwsRepository] getByGrade error: $e');
      return [];
    }
  }

  /// 책 ID로 조회
  Future<Book?> getById(String id) async {
    try {
      final request = ModelQueries.get(
        Book.classType,
        BookModelIdentifier(id: id),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[BookAwsRepository] getById errors: ${response.errors}');
        return null;
      }

      return response.data;
    } catch (e) {
      safePrint('[BookAwsRepository] getById error: $e');
      return null;
    }
  }

  /// 책 추가
  Future<Book?> addBook(Book book) async {
    try {
      final request = ModelMutations.create(book);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[BookAwsRepository] addBook errors: ${response.errors}');
        return null;
      }

      return response.data;
    } catch (e) {
      safePrint('[BookAwsRepository] addBook error: $e');
      return null;
    }
  }

  /// 책 수정
  Future<Book?> updateBook(Book book) async {
    try {
      final request = ModelMutations.update(book);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[BookAwsRepository] updateBook errors: ${response.errors}');
        return null;
      }

      return response.data;
    } catch (e) {
      safePrint('[BookAwsRepository] updateBook error: $e');
      return null;
    }
  }

  /// 책 삭제
  Future<bool> deleteBook(String id) async {
    try {
      final book = await getById(id);
      if (book == null) return false;

      final request = ModelMutations.delete(book);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[BookAwsRepository] deleteBook errors: ${response.errors}');
        return false;
      }

      return true;
    } catch (e) {
      safePrint('[BookAwsRepository] deleteBook error: $e');
      return false;
    }
  }

  // ==================== Chapter CRUD ====================

  /// 책의 목차(Chapter) 생성
  Future<Chapter?> createChapter({
    required String bookId,
    required String title,
    required int orderIndex,
  }) async {
    try {
      safePrint('[BookAwsRepository] Creating chapter: $title for book $bookId (orderIndex: $orderIndex)');

      // Book 객체를 먼저 가져와서 relation 설정
      final book = await getById(bookId);
      if (book == null) {
        safePrint('[BookAwsRepository] createChapter: Book not found with id: $bookId');
        return null;
      }

      final chapter = Chapter(
        title: title,
        orderIndex: orderIndex,
        book: book,
      );

      final request = ModelMutations.create(chapter);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[BookAwsRepository] createChapter errors: ${response.errors}');
        return null;
      }

      safePrint('[BookAwsRepository] Chapter created successfully: ${response.data?.id}');
      return response.data;
    } catch (e, stackTrace) {
      safePrint('[BookAwsRepository] createChapter error: $e');
      safePrint('[BookAwsRepository] Stack trace: $stackTrace');
      return null;
    }
  }

  /// 특정 책의 모든 목차 조회 (순서대로 정렬)
  Future<List<Chapter>> getChaptersByBookId(String bookId) async {
    try {
      safePrint('[BookAwsRepository] Getting chapters for book: $bookId');

      final request = ModelQueries.list(
        Chapter.classType,
        where: Chapter.BOOK.eq(bookId),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[BookAwsRepository] getChaptersByBookId errors: ${response.errors}');
        return [];
      }

      final chapters = response.data?.items.whereType<Chapter>().toList() ?? [];
      // orderIndex 필드로 정렬
      chapters.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      safePrint('[BookAwsRepository] Found ${chapters.length} chapters for book $bookId');
      return chapters;
    } catch (e, stackTrace) {
      safePrint('[BookAwsRepository] getChaptersByBookId error: $e');
      safePrint('[BookAwsRepository] Stack trace: $stackTrace');
      return [];
    }
  }

  /// 목차 삭제
  Future<bool> deleteChapter(String chapterId) async {
    try {
      safePrint('[BookAwsRepository] Deleting chapter: $chapterId');

      // 먼저 Chapter를 조회
      final getRequest = ModelQueries.get(
        Chapter.classType,
        ChapterModelIdentifier(id: chapterId),
      );
      final getResponse = await Amplify.API.query(request: getRequest).response;

      if (getResponse.hasErrors || getResponse.data == null) {
        safePrint('[BookAwsRepository] deleteChapter: Chapter not found');
        return false;
      }

      final chapter = getResponse.data!;
      final deleteRequest = ModelMutations.delete(chapter);
      final deleteResponse = await Amplify.API.mutate(request: deleteRequest).response;

      if (deleteResponse.hasErrors) {
        safePrint('[BookAwsRepository] deleteChapter errors: ${deleteResponse.errors}');
        return false;
      }

      safePrint('[BookAwsRepository] Chapter deleted successfully');
      return true;
    } catch (e, stackTrace) {
      safePrint('[BookAwsRepository] deleteChapter error: $e');
      safePrint('[BookAwsRepository] Stack trace: $stackTrace');
      return false;
    }
  }

  /// 책 삭제 시 연관된 모든 목차도 함께 삭제
  Future<bool> deleteChaptersByBookId(String bookId) async {
    try {
      safePrint('[BookAwsRepository] Deleting all chapters for book: $bookId');

      final chapters = await getChaptersByBookId(bookId);

      for (final chapter in chapters) {
        await deleteChapter(chapter.id);
      }

      safePrint('[BookAwsRepository] Deleted ${chapters.length} chapters');
      return true;
    } catch (e, stackTrace) {
      safePrint('[BookAwsRepository] deleteChaptersByBookId error: $e');
      safePrint('[BookAwsRepository] Stack trace: $stackTrace');
      return false;
    }
  }

  // ==================== End Chapter CRUD ====================

  /// 기본 책 데이터 시드 (Book 테이블이 비어있을 때)
  Future<void> seedDefaultBooks() async {
    try {
      final existing = await getAll();
      if (existing.isNotEmpty) return; // 이미 데이터 있으면 스킵

      final defaultBooks = [
        // 수학 - 초등
        Book(
          title: '초등 수학의 정석',
          subject: Subject.MATH,
          grade: Grade.ELEMENTARY,
          year: 2024,
        ),
        // 수학 - 중등
        Book(
          title: '중등 수학 개념완성',
          subject: Subject.MATH,
          grade: Grade.MIDDLE,
          year: 2024,
        ),
        // 영어 - 초등
        Book(
          title: '초등 영어 첫걸음',
          subject: Subject.ENGLISH,
          grade: Grade.ELEMENTARY,
          year: 2024,
        ),
        // 영어 - 중등
        Book(
          title: '중등 영어 문법 마스터',
          subject: Subject.ENGLISH,
          grade: Grade.MIDDLE,
          year: 2024,
        ),
        // 과학 - 초등
        Book(
          title: '초등 과학 탐구',
          subject: Subject.SCIENCE,
          grade: Grade.ELEMENTARY,
          year: 2024,
        ),
        // 국어 - 초등
        Book(
          title: '초등 국어 독해력',
          subject: Subject.KOREAN,
          grade: Grade.ELEMENTARY,
          year: 2024,
        ),
      ];

      for (final book in defaultBooks) {
        await addBook(book);
      }
      safePrint('[BookAwsRepository] Seeded ${defaultBooks.length} default books');
    } catch (e) {
      safePrint('[BookAwsRepository] seedDefaultBooks error: $e');
    }
  }
}

/// Subject enum을 한글 문자열로 변환
String subjectToKorean(Subject subject) {
  switch (subject) {
    case Subject.MATH:
      return '수학';
    case Subject.ENGLISH:
      return '영어';
    case Subject.SCIENCE:
      return '과학';
    case Subject.KOREAN:
      return '국어';
  }
}

/// 한글 문자열을 Subject enum으로 변환
Subject? subjectFromKorean(String korean) {
  switch (korean) {
    case '수학':
      return Subject.MATH;
    case '영어':
      return Subject.ENGLISH;
    case '과학':
      return Subject.SCIENCE;
    case '국어':
      return Subject.KOREAN;
    default:
      return null;
  }
}

/// Grade enum을 한글 문자열로 변환
String gradeToKorean(Grade grade) {
  switch (grade) {
    case Grade.ELEMENTARY:
      return '초등';
    case Grade.MIDDLE:
      return '중등';
    case Grade.HIGH:
      return '고등';
  }
}

/// 한글 문자열을 Grade enum으로 변환
Grade? gradeFromKorean(String korean) {
  switch (korean) {
    case '초등':
      return Grade.ELEMENTARY;
    case '중등':
      return Grade.MIDDLE;
    case '고등':
      return Grade.HIGH;
    default:
      return null;
  }
}
