import 'dart:io';
import 'package:flutter/foundation.dart';
import 'mlkit_ocr_service.dart';
import 'claude_api_service.dart';

/// 정답지 텍스트 파싱 서비스
/// 
/// ML Kit OCR로 추출한 텍스트를 정규식으로 구조화
/// - 페이지 번호: p.9, pp.10-11
/// - 섹션: A) B) C) D)
/// - 정답: 1. xxx  2. xxx
class AnswerParserService {
  final MlKitOcrService _ocrService = MlKitOcrService();
  final ClaudeApiService _claudeService = ClaudeApiService();

  /// 이미지에서 정답 추출 (ML Kit OCR + Claude AI 파싱)
  ///
  /// 기존 정규식 방식 제거 → AI가 텍스트 의미 이해하여 구조화
  Future<List<ParsedPage>> extractAnswers(File imageFile) async {
    debugPrint('[AnswerParser] 이미지 분석 시작: ${imageFile.path}');

    // 1. ML Kit OCR로 텍스트 추출
    final ocrResult = await _ocrService.analyzeImage(imageFile);

    // 2. 블록들을 위→아래 순서로 정렬 (top 기준)
    final sortedBlocks = List<OcrTextBlock>.from(ocrResult.blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    // 3. 전체 텍스트 합치기
    final fullText = sortedBlocks.map((b) => b.text).join('\n');

    // ★ BIG_143: OCR 텍스트 원본 상세 로그 (줄바꿈 치환)
    debugPrint('[AnswerParser] ========== OCR 텍스트 원본 ==========');
    debugPrint('[AnswerParser] OCR 총 길이: ${fullText.length}자');
    // 줄바꿈을 ↵로 치환해서 한 줄로 출력 (debugPrint 줄바꿈 문제 해결)
    final ocrForLog = fullText.replaceAll('\n', '↵');
    if (ocrForLog.length > 1000) {
      debugPrint('[AnswerParser] OCR 앞 500자: ${ocrForLog.substring(0, 500)}');
      debugPrint('[AnswerParser] OCR 뒤 500자: ${ocrForLog.substring(ocrForLog.length - 500)}');
    } else {
      debugPrint('[AnswerParser] OCR 전체: $ocrForLog');
    }
    debugPrint('[AnswerParser] ========================================');

    if (fullText.isEmpty) {
      debugPrint('[AnswerParser] OCR 텍스트 비어있음');
      return [];
    }

    // 4. Claude API로 텍스트 → JSON 구조화
    try {
      final apiResults = await _claudeService.parseOcrTextToAnswers(fullText);

      // 5. API 결과를 ParsedPage로 변환
      final pages = apiResults.map((result) {
        final sections = <String, List<String>>{};
        final rawSections = result['sections'] as Map<String, dynamic>? ?? {};

        for (final entry in rawSections.entries) {
          if (entry.value is List) {
            sections[entry.key] = (entry.value as List).map((e) => e.toString()).toList();
          }
        }

        return ParsedPage(
          pageNumber: result['pageNumber'] as int? ?? 0,
          sections: sections,
          rawContent: result['content'] as String? ?? '',
        );
      }).toList();

      debugPrint('[AnswerParser] AI 파싱 완료: ${pages.length}개 페이지');
      return pages;

    } catch (e) {
      debugPrint('[AnswerParser] AI 파싱 실패: $e');
      return [];
    }
  }

  // BIG_136: 정규식 파싱 제거 → Claude AI 파싱으로 대체
  // /// 텍스트를 페이지 단위로 파싱
  // List<ParsedPage> _parseText(String text) {
  //   final pages = <ParsedPage>[];
  //
  //   // 페이지 패턴: p.숫자 또는 pp.숫자-숫자
  //   // 예: "p.9", "p. 10", "pp.11-12", "p9", "P.9"
  //   final pagePattern = RegExp(
  //     r'(?:^|\n|[^\d])p+\.?\s*(\d+)(?:\s*[-~]\s*(\d+))?',
  //     caseSensitive: false,
  //     multiLine: true,
  //   );
  //
  //   final pageMatches = pagePattern.allMatches(text).toList();
  //   debugPrint('[AnswerParser] 페이지 패턴 매칭: ${pageMatches.length}개');
  //
  //   for (int i = 0; i < pageMatches.length; i++) {
  //     final match = pageMatches[i];
  //     final startPage = int.tryParse(match.group(1) ?? '') ?? 0;
  //     final endPage = int.tryParse(match.group(2) ?? '') ?? startPage;
  //
  //     debugPrint('[AnswerParser] 페이지 발견: p.$startPage${endPage != startPage ? "~$endPage" : ""}');
  //
  //     // 이 페이지와 다음 페이지 사이의 텍스트 추출
  //     final startIdx = match.end;
  //     final endIdx = (i + 1 < pageMatches.length)
  //         ? pageMatches[i + 1].start
  //         : text.length;
  //
  //     final pageContent = text.substring(startIdx, endIdx).trim();
  //
  //     // 섹션 파싱
  //     final sections = _parseSections(pageContent);
  //
  //     // 단일 페이지 또는 범위 처리
  //     for (int p = startPage; p <= endPage; p++) {
  //       pages.add(ParsedPage(
  //         pageNumber: p,
  //         sections: sections,
  //         rawContent: pageContent,
  //       ));
  //     }
  //   }
  //
  //   // 페이지 번호 중복 제거 (같은 페이지가 여러 번 나올 수 있음)
  //   final seen = <int>{};
  //   pages.removeWhere((page) {
  //     if (seen.contains(page.pageNumber)) return true;
  //     seen.add(page.pageNumber);
  //     return false;
  //   });
  //
  //   // 페이지 번호 순 정렬
  //   pages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
  //
  //   return pages;
  // }

  // BIG_136: 정규식 파싱 제거 → Claude AI 파싱으로 대체
  // /// 섹션 파싱 (A, B, C, D...)
  // Map<String, List<String>> _parseSections(String content) {
  //   final sections = <String, List<String>>{};
  //
  //   // 섹션 패턴: A) 또는 A. 또는 [A] 또는 (A)
  //   // 대문자 알파벳 하나 + 구분자
  //   final sectionPattern = RegExp(
  //     r'(?:^|\n)\s*[\[\(]?([A-Z])[\]\)]?[.)\s]+',
  //     multiLine: true,
  //   );
  //
  //   final sectionMatches = sectionPattern.allMatches(content).toList();
  //
  //   if (sectionMatches.isEmpty) {
  //     // 섹션 구분 없으면 전체를 하나의 섹션으로
  //     final answers = _parseAnswers(content);
  //     if (answers.isNotEmpty) {
  //       sections['ALL'] = answers;
  //     }
  //     return sections;
  //   }
  //
  //   for (int i = 0; i < sectionMatches.length; i++) {
  //     final match = sectionMatches[i];
  //     final sectionName = match.group(1) ?? '';
  //
  //     final startIdx = match.end;
  //     final endIdx = (i + 1 < sectionMatches.length)
  //         ? sectionMatches[i + 1].start
  //         : content.length;
  //
  //     final sectionContent = content.substring(startIdx, endIdx).trim();
  //     final answers = _parseAnswers(sectionContent);
  //
  //     if (answers.isNotEmpty) {
  //       sections[sectionName] = answers;
  //       debugPrint('[AnswerParser]   섹션 $sectionName: ${answers.length}개 정답');
  //     }
  //   }
  //
  //   return sections;
  // }

  // BIG_136: 정규식 파싱 제거 → Claude AI 파싱으로 대체
  // /// 정답 파싱 (1. xxx, 2. xxx)
  // List<String> _parseAnswers(String content) {
  //   final answers = <String>[];
  //
  //   // 정답 패턴: 숫자. 또는 숫자) 또는 (숫자)
  //   // 예: "1. answer", "2) answer", "(3) answer"
  //   final answerPattern = RegExp(
  //     r'(?:^|\s)[\(\[]?(\d+)[\)\]]?[.)\s]+(.+?)(?=(?:^|\s)[\(\[]?\d+[\)\]]?[.)\s]|$)',
  //     multiLine: true,
  //     dotAll: true,
  //   );
  //
  //   final matches = answerPattern.allMatches(content);
  //
  //   for (final match in matches) {
  //     final answerText = match.group(2)?.trim() ?? '';
  //     if (answerText.isNotEmpty && answerText.length < 200) {
  //       // 줄바꿈 정리
  //       final cleaned = answerText
  //           .replaceAll(RegExp(r'\s+'), ' ')
  //           .trim();
  //       answers.add(cleaned);
  //     }
  //   }
  //
  //   // 정규식이 안 먹히면 간단한 방식으로 폴백
  //   if (answers.isEmpty) {
  //     // 줄 단위로 분석
  //     final lines = content.split('\n');
  //     for (final line in lines) {
  //       final trimmed = line.trim();
  //       // 숫자로 시작하는 줄
  //       final simpleMatch = RegExp(r'^[\(\[]?\d+[\)\]]?[.)\s]+(.+)').firstMatch(trimmed);
  //       if (simpleMatch != null) {
  //         final answer = simpleMatch.group(1)?.trim() ?? '';
  //         if (answer.isNotEmpty && answer.length < 200) {
  //           answers.add(answer);
  //         }
  //       }
  //     }
  //   }
  //
  //   return answers;
  // }

  /// 리소스 해제
  void dispose() {
    _ocrService.dispose();
  }
}

/// 파싱된 페이지
class ParsedPage {
  final int pageNumber;
  final Map<String, List<String>> sections;
  final String rawContent;

  ParsedPage({
    required this.pageNumber,
    required this.sections,
    required this.rawContent,
  });

  /// 문자열 형식으로 변환 (UI 표시용)
  String toDisplayString() {
    final buffer = StringBuffer();
    
    for (final entry in sections.entries) {
      if (entry.key != 'ALL') {
        buffer.writeln('${entry.key})');
      }
      for (int i = 0; i < entry.value.length; i++) {
        buffer.writeln('${i + 1}. ${entry.value[i]}');
      }
      buffer.writeln();
    }
    
    return buffer.toString().trim();
  }

  /// Map 형식으로 변환 (저장용)
  Map<String, dynamic> toMap() {
    return {
      'pageNumber': pageNumber,
      'sections': sections,
      'content': toDisplayString(),
    };
  }
}
