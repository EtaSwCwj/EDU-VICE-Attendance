import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'textract_service.dart';
import 'image_crop_service.dart';
import 'claude_api_service.dart';

/// 문제 이미지 추출 서비스
/// - Claude Vision AI (문제 구조 파악) + Textract (OCR 좌표) 결합
/// - 문제별 이미지 crop 및 S3 저장
class ProblemExtractorService {
  final _textractService = TextractService();
  final _cropService = ImageCropService();
  final _claudeService = ClaudeApiService();
  
  /// 페이지 이미지에서 문제별 이미지 추출
  Future<ExtractionResult> extractProblems(File pageImage) async {
    try {
      safePrint('[ProblemExtractor] 시작');
      
      // 1. Claude Vision AI로 문제 구조 분석
      safePrint('[ProblemExtractor] Step 1: Claude Vision 분석');
      final claudeResult = await _claudeService.analyzeTextbookFile(pageImage);
      
      if (claudeResult == null) {
        throw Exception('Claude 분석 실패');
      }
      
      final problems = claudeResult['problems'] as List<dynamic>? ?? [];
      safePrint('[ProblemExtractor] Claude 결과: ${problems.length}개 문제');
      
      // 2. Textract OCR로 텍스트 + 좌표 추출
      safePrint('[ProblemExtractor] Step 2: Textract OCR');
      final textractResult = await _textractService.analyzeDocument(pageImage);
      safePrint('[ProblemExtractor] Textract 결과: ${textractResult.blocks.length}개 블록');
      
      // 3. 문제 번호 블록 찾기
      final problemBlocks = textractResult.findProblemNumbers();
      safePrint('[ProblemExtractor] 문제 번호 블록: ${problemBlocks.length}개');
      
      for (final block in problemBlocks) {
        safePrint('  - "${block.text}" at ${block.boundingBox.toRect()}');
      }
      
      // 4. 문제 영역 계산
      final regions = _cropService.calculateProblemRegions(problemBlocks);
      safePrint('[ProblemExtractor] 계산된 영역: ${regions.length}개');
      
      // 5. 각 영역 crop
      safePrint('[ProblemExtractor] Step 3: 이미지 Crop');
      final croppedImages = await _cropService.cropMultiple(
        sourceImage: pageImage,
        regions: regions,
      );
      safePrint('[ProblemExtractor] Crop 완료: ${croppedImages.length}개');
      
      // 6. S3에 업로드
      safePrint('[ProblemExtractor] Step 4: S3 업로드');
      final uploadedUrls = <String, String>{};
      
      for (final cropped in croppedImages) {
        final s3Key = 'problem-images/${DateTime.now().millisecondsSinceEpoch}_${cropped.problemNumber}.png';
        
        try {
          final result = await Amplify.Storage.uploadFile(
            localFile: AWSFile.fromPath(cropped.file.path),
            path: StoragePath.fromString(s3Key),
          ).result;
          
          // URL 생성
          final urlResult = await Amplify.Storage.getUrl(
            path: StoragePath.fromString(s3Key),
          ).result;
          
          uploadedUrls[cropped.problemNumber] = urlResult.url.toString();
          safePrint('[ProblemExtractor] 업로드 완료: ${cropped.problemNumber}번');
          
        } catch (e) {
          safePrint('[ProblemExtractor] 업로드 실패 (${cropped.problemNumber}번): $e');
        }
        
        // 임시 파일 삭제
        await cropped.file.delete();
      }
      
      safePrint('[ProblemExtractor] 완료!');
      
      return ExtractionResult(
        claudeAnalysis: claudeResult,
        problemImages: uploadedUrls,
        textractBlocks: textractResult.blocks,
      );
      
    } catch (e) {
      safePrint('[ProblemExtractor] ERROR: $e');
      rethrow;
    }
  }
  
  /// 특정 문제 번호의 영역만 추출
  Future<String?> extractSingleProblem({
    required File pageImage,
    required String problemNumber,
  }) async {
    try {
      // Textract OCR
      final textractResult = await _textractService.analyzeDocument(pageImage);
      
      // 해당 문제 번호 찾기
      final problemBlocks = textractResult.findProblemNumbers();
      final targetBlock = problemBlocks.firstWhere(
        (b) => b.text.contains(problemNumber),
        orElse: () => throw Exception('문제 $problemNumber 을(를) 찾을 수 없습니다'),
      );
      
      // 영역 계산 (다음 문제까지)
      final sortedBlocks = List<TextBlock>.from(problemBlocks)
        ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
      
      final targetIndex = sortedBlocks.indexOf(targetBlock);
      final nextTop = (targetIndex < sortedBlocks.length - 1)
          ? sortedBlocks[targetIndex + 1].boundingBox.top
          : 1.0;
      
      final region = BoundingBox(
        left: 0,
        top: targetBlock.boundingBox.top,
        width: 1.0,
        height: nextTop - targetBlock.boundingBox.top,
      );
      
      // Crop
      final cropped = await _cropService.cropImage(
        sourceImage: pageImage,
        boundingBox: region,
        outputFileName: 'problem_$problemNumber.png',
      );
      
      if (cropped == null) return null;
      
      // S3 업로드
      final s3Key = 'problem-images/${DateTime.now().millisecondsSinceEpoch}_$problemNumber.png';
      
      await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(cropped.path),
        path: StoragePath.fromString(s3Key),
      ).result;
      
      final urlResult = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(s3Key),
      ).result;
      
      // 임시 파일 삭제
      await cropped.delete();
      
      return urlResult.url.toString();
      
    } catch (e) {
      safePrint('[ProblemExtractor] 단일 추출 실패: $e');
      return null;
    }
  }
}

/// 추출 결과
class ExtractionResult {
  final Map<String, dynamic> claudeAnalysis;
  final Map<String, String> problemImages; // {문제번호: S3 URL}
  final List<TextBlock> textractBlocks;
  
  ExtractionResult({
    required this.claudeAnalysis,
    required this.problemImages,
    required this.textractBlocks,
  });
  
  /// 문제 정보와 이미지 URL 매칭
  List<ProblemWithImage> getProblemsWithImages() {
    final problems = claudeAnalysis['problems'] as List<dynamic>? ?? [];
    
    return problems.map((p) {
      final prob = p as Map<String, dynamic>;
      final number = prob['number']?.toString() ?? '';
      
      return ProblemWithImage(
        number: number,
        question: prob['question']?.toString() ?? '',
        answer: prob['answer']?.toString() ?? '',
        difficulty: prob['difficulty']?.toString() ?? 'MEDIUM',
        imageUrl: problemImages[number],
      );
    }).toList();
  }
}

/// 이미지가 포함된 문제 정보
class ProblemWithImage {
  final String number;
  final String question;
  final String answer;
  final String difficulty;
  final String? imageUrl;
  
  ProblemWithImage({
    required this.number,
    required this.question,
    required this.answer,
    required this.difficulty,
    this.imageUrl,
  });
}
