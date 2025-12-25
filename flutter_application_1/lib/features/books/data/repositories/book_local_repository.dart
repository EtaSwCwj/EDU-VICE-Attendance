import 'package:sembast/sembast.dart';
import '../../../books/domain/entities/book.dart';

class BookLocalRepository {
  final Database _db;
  final _store = StoreRef<String, Map<String, dynamic>>('books');
  final _progressStore = StoreRef<String, Map<String, dynamic>>('book_progress');

  BookLocalRepository(this._db);

  /// 기본 책 데이터 시드 (최초 실행 시)
  Future<void> seedDefaultBooks() async {
    final existing = await _store.count(_db);
    if (existing > 0) return; // 이미 데이터 있으면 스킵

    final defaultBooks = [
      // 수학
      Book(
        id: 'book-math-elementary-01',
        academyId: 'default',
        title: '초등 수학의 정석',
        subject: '수학',
        grade: '초등',
        chapters: [
          '1단원 자연수',
          '2단원 분수',
          '3단원 소수',
          '4단원 도형',
          '5단원 측정',
          '6단원 규칙성',
        ],
        publishYear: 2024,
        createdAt: DateTime.now(),
      ),
      Book(
        id: 'book-math-middle-01',
        academyId: 'default',
        title: '중등 수학 개념완성',
        subject: '수학',
        grade: '중등',
        chapters: [
          '1장 정수와 유리수',
          '2장 문자와 식',
          '3장 일차방정식',
          '4장 좌표평면과 그래프',
          '5장 도형의 성질',
        ],
        publishYear: 2024,
        createdAt: DateTime.now(),
      ),
      // 영어
      Book(
        id: 'book-eng-elementary-01',
        academyId: 'default',
        title: '초등 영어 첫걸음',
        subject: '영어',
        grade: '초등',
        chapters: [
          'Unit 1 Greetings',
          'Unit 2 Family',
          'Unit 3 School',
          'Unit 4 Food',
          'Unit 5 Animals',
          'Unit 6 Weather',
        ],
        publishYear: 2024,
        createdAt: DateTime.now(),
      ),
      Book(
        id: 'book-eng-middle-01',
        academyId: 'default',
        title: '중등 영어 문법 마스터',
        subject: '영어',
        grade: '중등',
        chapters: [
          'Chapter 1 Be동사',
          'Chapter 2 일반동사',
          'Chapter 3 시제',
          'Chapter 4 조동사',
          'Chapter 5 문장의 종류',
        ],
        publishYear: 2024,
        createdAt: DateTime.now(),
      ),
      // 과학
      Book(
        id: 'book-sci-elementary-01',
        academyId: 'default',
        title: '초등 과학 탐구',
        subject: '과학',
        grade: '초등',
        chapters: [
          '1단원 생물의 세계',
          '2단원 물질의 성질',
          '3단원 힘과 운동',
          '4단원 지구와 우주',
        ],
        publishYear: 2024,
        createdAt: DateTime.now(),
      ),
      // 국어
      Book(
        id: 'book-kor-elementary-01',
        academyId: 'default',
        title: '초등 국어 독해력',
        subject: '국어',
        grade: '초등',
        chapters: [
          '1장 문장 이해하기',
          '2장 단락 파악하기',
          '3장 글의 구조',
          '4장 추론하기',
          '5장 비판적 읽기',
        ],
        publishYear: 2024,
        createdAt: DateTime.now(),
      ),
    ];

    for (final book in defaultBooks) {
      await _store.record(book.id).put(_db, _bookToJson(book));
    }
  }

  /// 모든 책 조회
  Future<List<Book>> getAll() async {
    final records = await _store.find(_db);
    return records.map((r) => _bookFromJson(r.value)).toList();
  }

  /// 과목별 책 조회
  Future<List<Book>> getBySubject(String subject) async {
    final finder = Finder(filter: Filter.equals('subject', subject));
    final records = await _store.find(_db, finder: finder);
    return records.map((r) => _bookFromJson(r.value)).toList();
  }

  /// 책 ID로 조회
  Future<Book?> getById(String id) async {
    final record = await _store.record(id).get(_db);
    if (record == null) return null;
    return _bookFromJson(record);
  }

  /// 책 추가
  Future<void> addBook(Book book) async {
    await _store.record(book.id).put(_db, _bookToJson(book));
  }

  /// 책 삭제
  Future<void> deleteBook(String id) async {
    await _store.record(id).delete(_db);
  }

  /// 학생별 책 진도 저장
  Future<void> saveProgress(BookProgress progress) async {
    final key = '${progress.bookId}_${progress.studentId}';
    await _progressStore.record(key).put(_db, _progressToJson(progress));
  }

  /// 학생별 책 진도 조회
  Future<BookProgress?> getProgress(String bookId, String studentId) async {
    final key = '${bookId}_$studentId';
    final record = await _progressStore.record(key).get(_db);
    if (record == null) return null;
    return _progressFromJson(record);
  }

  /// 학생의 모든 책 진도 조회
  Future<List<BookProgress>> getStudentProgress(String studentId) async {
    final finder = Finder(filter: Filter.equals('studentId', studentId));
    final records = await _progressStore.find(_db, finder: finder);
    return records.map((r) => _progressFromJson(r.value)).toList();
  }

  // JSON 변환
  Map<String, dynamic> _bookToJson(Book book) {
    return {
      'id': book.id,
      'academyId': book.academyId,
      'title': book.title,
      'subject': book.subject,
      'grade': book.grade,
      'imageUrl': book.imageUrl,
      'chapters': book.chapters,
      'publishYear': book.publishYear,
      'createdAt': book.createdAt.toIso8601String(),
    };
  }

  Book _bookFromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      academyId: json['academyId'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      grade: json['grade'] as String?,
      imageUrl: json['imageUrl'] as String?,
      chapters: (json['chapters'] as List).cast<String>(),
      publishYear: json['publishYear'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> _progressToJson(BookProgress progress) {
    return {
      'bookId': progress.bookId,
      'studentId': progress.studentId,
      'chapters': progress.chapters.map((k, v) => MapEntry(k.toString(), {
        'chapterIndex': v.chapterIndex,
        'isCompleted': v.isCompleted,
        'completedAt': v.completedAt?.toIso8601String(),
        'note': v.note,
      })),
    };
  }

  BookProgress _progressFromJson(Map<String, dynamic> json) {
    final chaptersMap = (json['chapters'] as Map<String, dynamic>).map((k, v) {
      final data = v as Map<String, dynamic>;
      return MapEntry(
        int.parse(k),
        ChapterProgress(
          chapterIndex: data['chapterIndex'] as int,
          isCompleted: data['isCompleted'] as bool,
          completedAt: data['completedAt'] != null
              ? DateTime.parse(data['completedAt'] as String)
              : null,
          note: data['note'] as String?,
        ),
      );
    });
    
    return BookProgress(
      bookId: json['bookId'] as String,
      studentId: json['studentId'] as String,
      chapters: chaptersMap,
    );
  }
}
