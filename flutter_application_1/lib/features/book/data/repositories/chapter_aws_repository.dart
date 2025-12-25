import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../../../../models/ModelProvider.dart';

/// Chapter(단원) AWS Repository
/// 교재 단원의 CRUD 작업 담당
class ChapterAwsRepository {
  const ChapterAwsRepository();

  /// 교재별 단원 목록 조회
  /// [bookId] 교재 ID
  /// 반환: 단원 목록 (orderIndex 순 정렬)
  Future<List<Chapter>> getChaptersByBookId(String bookId) async {
    try {
      // bookId로 필터링하여 Chapter 조회
      final request = GraphQLRequest<String>(
        document: '''
          query ChaptersByBook(\$bookId: ID!) {
            chaptersByBook(bookId: \$bookId) {
              items {
                id
                title
                orderIndex
                parentId
                level
                startPage
                endPage
                answerImageUrl
                createdAt
                updatedAt
              }
            }
          }
        ''',
        variables: {'bookId': bookId},
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[ChapterAwsRepository] ERROR: ${response.errors}');
        return [];
      }

      if (response.data == null) return [];

      // JSON 파싱
      final jsonData = response.data!;
      final Map<String, dynamic> parsed = jsonDecode(jsonData);

      final items = parsed['chaptersByBook']?['items'] as List? ?? [];
      final chapters = items
          .map((item) => Chapter.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      // orderIndex 순 정렬
      chapters.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      safePrint('[ChapterAwsRepository] 단원 조회 완료: ${chapters.length}개 (bookId=$bookId)');
      return chapters;
    } catch (e) {
      safePrint('[ChapterAwsRepository] ERROR: 단원 조회 실패 - $e');
      return [];
    }
  }

  /// 단원 ID로 조회
  Future<Chapter?> getById(String id) async {
    try {
      final request = ModelQueries.get(
        Chapter.classType,
        ChapterModelIdentifier(id: id),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[ChapterAwsRepository] ERROR: ${response.errors}');
        return null;
      }

      return response.data;
    } catch (e) {
      safePrint('[ChapterAwsRepository] ERROR: ID 조회 실패 - $e');
      return null;
    }
  }

  /// 단원 생성
  Future<Chapter?> createChapter({
    required String bookId,
    required String title,
    required int orderIndex,
    String? parentId,
    int? level,
    int? startPage,
    int? endPage,
    String? answerImageUrl,
  }) async {
    try {
      // Book 조회 (belongsTo 관계)
      final bookRequest = ModelQueries.get(
        Book.classType,
        BookModelIdentifier(id: bookId),
      );
      final bookResponse = await Amplify.API.query(request: bookRequest).response;
      final book = bookResponse.data;

      final chapter = Chapter(
        title: title,
        orderIndex: orderIndex,
        parentId: parentId,
        level: level ?? 1,
        startPage: startPage,
        endPage: endPage,
        answerImageUrl: answerImageUrl,
        book: book,
      );

      final request = ModelMutations.create(chapter);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[ChapterAwsRepository] ERROR: 생성 실패 - ${response.errors}');
        return null;
      }

      safePrint('[ChapterAwsRepository] 단원 생성 완료: $title');
      return response.data;
    } catch (e) {
      safePrint('[ChapterAwsRepository] ERROR: 단원 생성 실패 - $e');
      return null;
    }
  }

  /// 단원 수정
  Future<Chapter?> updateChapter(Chapter chapter) async {
    try {
      final request = ModelMutations.update(chapter);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[ChapterAwsRepository] ERROR: 수정 실패 - ${response.errors}');
        return null;
      }

      safePrint('[ChapterAwsRepository] 단원 수정 완료: ${chapter.title}');
      return response.data;
    } catch (e) {
      safePrint('[ChapterAwsRepository] ERROR: 단원 수정 실패 - $e');
      return null;
    }
  }

  /// 단원 삭제
  Future<bool> deleteChapter(String id) async {
    try {
      final chapter = await getById(id);
      if (chapter == null) {
        safePrint('[ChapterAwsRepository] WARNING: 삭제할 단원 없음 - $id');
        return false;
      }

      final request = ModelMutations.delete(chapter);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[ChapterAwsRepository] ERROR: 삭제 실패 - ${response.errors}');
        return false;
      }

      safePrint('[ChapterAwsRepository] 단원 삭제 완료: $id');
      return true;
    } catch (e) {
      safePrint('[ChapterAwsRepository] ERROR: 단원 삭제 실패 - $e');
      return false;
    }
  }

  /// 하위 단원 조회 (계층 구조)
  /// [parentId] 상위 단원 ID
  Future<List<Chapter>> getChildChapters(String parentId) async {
    try {
      final request = ModelQueries.list(
        Chapter.classType,
        where: Chapter.PARENTID.eq(parentId),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[ChapterAwsRepository] ERROR: ${response.errors}');
        return [];
      }

      final chapters = response.data?.items.whereType<Chapter>().toList() ?? [];
      chapters.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      safePrint('[ChapterAwsRepository] 하위 단원 조회: ${chapters.length}개 (parentId=$parentId)');
      return chapters;
    } catch (e) {
      safePrint('[ChapterAwsRepository] ERROR: 하위 단원 조회 실패 - $e');
      return [];
    }
  }

  /// 답안지 이미지 URL 업데이트
  Future<Chapter?> updateAnswerImageUrl({
    required String chapterId,
    required String? answerImageUrl,
  }) async {
    try {
      final chapter = await getById(chapterId);
      if (chapter == null) return null;

      final updatedChapter = chapter.copyWith(
        answerImageUrl: answerImageUrl,
      );

      return await updateChapter(updatedChapter);
    } catch (e) {
      safePrint('[ChapterAwsRepository] ERROR: 답안지 URL 업데이트 실패 - $e');
      return null;
    }
  }

  /// 단원 순서 변경
  Future<bool> reorderChapters(List<Chapter> chapters) async {
    try {
      for (int i = 0; i < chapters.length; i++) {
        final chapter = chapters[i];
        if (chapter.orderIndex != i) {
          final updatedChapter = chapter.copyWith(orderIndex: i);
          await updateChapter(updatedChapter);
        }
      }
      safePrint('[ChapterAwsRepository] 단원 순서 변경 완료: ${chapters.length}개');
      return true;
    } catch (e) {
      safePrint('[ChapterAwsRepository] ERROR: 순서 변경 실패 - $e');
      return false;
    }
  }
}
