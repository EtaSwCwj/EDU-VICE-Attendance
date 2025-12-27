import 'package:amplify_flutter/amplify_flutter.dart';
import '../../features/my_books/models/book_volume.dart';

/// 정답지 검증 결과
class AnswerValidationResult {
  final bool isValid;
  final String? message;
  final int? suggestedAnswerPage;

  AnswerValidationResult({
    required this.isValid,
    this.message,
    this.suggestedAnswerPage,
  });
}

/// 정답지 검증 서비스
class AnswerValidationService {
  /// Volume의 정답 범위 내에서 문제 검증
  static AnswerValidationResult validateAnswer({
    required BookVolume volume,
    required int problemPage,
    required String problemNumber,
  }) {
    safePrint(
      '[AnswerValidation] 검증 시작: Volume=${volume.name}, 문제=${problemPage}p $problemNumber번',
    );

    // 1. Volume에 answerStartPage/answerEndPage가 없으면 검증 스킵
    if (volume.answerStartPage == null || volume.answerEndPage == null) {
      final result = AnswerValidationResult(
        isValid: true,
        message: '정답지 범위가 설정되지 않아 검증을 스킵합니다.',
      );
      safePrint('[AnswerValidation] 검증 결과: ${result.isValid} - ${result.message}');
      return result;
    }

    // 2. 문제 페이지 번호가 Volume의 페이지 범위를 벗어나면 경고
    if (volume.totalPages != null && problemPage > volume.totalPages!) {
      final result = AnswerValidationResult(
        isValid: false,
        message: '문제 페이지($problemPage)가 Volume의 총 페이지(${volume.totalPages}) 범위를 벗어났습니다.',
      );
      safePrint('[AnswerValidation] 검증 결과: ${result.isValid} - ${result.message}');
      return result;
    }

    // 3. 문제 페이지가 정답지 범위에 있는지 확인
    final answerStart = volume.answerStartPage!;
    final answerEnd = volume.answerEndPage!;

    if (problemPage >= answerStart && problemPage <= answerEnd) {
      final result = AnswerValidationResult(
        isValid: false,
        message: '문제 페이지($problemPage)가 정답지 범위($answerStart~$answerEnd)에 포함되어 있습니다.',
        suggestedAnswerPage: null,
      );
      safePrint('[AnswerValidation] 검증 결과: ${result.isValid} - ${result.message}');
      return result;
    }

    // 4. 정답지 범위에서 해당 문제를 찾을 수 있는지 확인 (간단한 휴리스틱)
    // 일반적으로 정답은 문제 페이지 이후에 위치
    if (problemPage < answerStart) {
      final result = AnswerValidationResult(
        isValid: true,
        message: '문제 페이지가 정답지 범위 이전에 있습니다.',
        suggestedAnswerPage: answerStart,
      );
      safePrint('[AnswerValidation] 검증 결과: ${result.isValid} - ${result.message}');
      return result;
    }

    // 문제 페이지가 정답지 이후에 있는 경우
    final result = AnswerValidationResult(
      isValid: true,
      message: '문제 페이지가 정답지 범위 이후에 있습니다.',
      suggestedAnswerPage: answerEnd,
    );
    safePrint('[AnswerValidation] 검증 결과: ${result.isValid} - ${result.message}');
    return result;
  }

  /// 정답지 페이지가 Volume 범위에 있는지 확인
  static bool isPageInAnswerRange({
    required BookVolume volume,
    required int answerPage,
  }) {
    safePrint(
      '[AnswerValidation] 정답지 범위 확인: Volume=${volume.name}, 정답 페이지=$answerPage',
    );

    if (volume.answerStartPage == null || volume.answerEndPage == null) {
      safePrint('[AnswerValidation] 정답지 범위가 설정되지 않음 - 검증 스킵');
      return true;
    }

    final answerStart = volume.answerStartPage!;
    final answerEnd = volume.answerEndPage!;
    final isInRange = answerPage >= answerStart && answerPage <= answerEnd;

    safePrint(
      '[AnswerValidation] 정답지 범위 확인 결과: $isInRange (범위: $answerStart~$answerEnd)',
    );

    return isInRange;
  }

  /// Volume의 정답지 페이지 범위 내에서 실제 정답 페이지 찾기
  static int? getAnswerPageForVolume({
    required BookVolume volume,
    required int problemPage,
  }) {
    safePrint(
      '[AnswerValidation] 정답 페이지 찾기: Volume=${volume.name}, 문제 페이지=$problemPage',
    );

    if (volume.answerStartPage == null || volume.answerEndPage == null) {
      safePrint('[AnswerValidation] 정답지 범위가 설정되지 않음');
      return null;
    }

    final answerStart = volume.answerStartPage!;
    final answerEnd = volume.answerEndPage!;

    // 간단한 휴리스틱: 문제 페이지가 정답 범위 이전에 있으면 정답 시작 페이지 추천
    if (problemPage < answerStart) {
      safePrint('[AnswerValidation] 추천 정답 페이지: $answerStart (정답 시작 페이지)');
      return answerStart;
    }

    // 문제 페이지가 정답 범위 내에 있으면 null 반환 (문제 페이지가 정답 범위에 있는 경우)
    if (problemPage >= answerStart && problemPage <= answerEnd) {
      safePrint('[AnswerValidation] 문제 페이지가 정답 범위 내에 있음');
      return null;
    }

    // 문제 페이지가 정답 범위 이후에 있으면 정답 종료 페이지 추천
    safePrint('[AnswerValidation] 추천 정답 페이지: $answerEnd (정답 종료 페이지)');
    return answerEnd;
  }
}
