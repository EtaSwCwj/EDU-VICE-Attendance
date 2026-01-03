import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/problem.dart';
import '../../../shared/services/claude_api_service.dart';

/// 문제 분할 서비스 (ocr_test_page.dart의 성공 로직 그대로 복사)
/// 
/// 핵심 파이프라인:
/// 1. Claude Vision → 섹션 bounds(%) 감지
/// 2. 섹션별 crop → OCR로 문제 번호 실측 좌표(px) 찾기
/// 3. 미감지 문제 재검사 (평균 간격 기반)
/// 4. 각 문제별 crop + 저장
class ProblemSplitService {
  final _claudeService = ClaudeApiService();

  /// 페이지 이미지에서 문제들을 분할
  Future<List<Problem>> splitProblems({
    required File imageFile,
    required String bookId,
    required int page,
    required String volumeName,
  }) async {
    try {
      safePrint('[ProblemSplit] ========== 문제 분할 시작 ==========');
      safePrint('[ProblemSplit] p$page ($volumeName)');
      safePrint('[ProblemSplit] 이미지: ${imageFile.path}');
      
      if (!await imageFile.exists()) {
        safePrint('[ProblemSplit] ❌ 이미지 파일 없음!');
        return [];
      }

      // 0. 이미지 로드
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        safePrint('[ProblemSplit] ❌ 이미지 디코딩 실패');
        return [];
      }
      safePrint('[ProblemSplit] 이미지 크기: ${image.width}x${image.height}');

      // 1. Claude Vision으로 섹션 영역 감지
      safePrint('[ProblemSplit] Step 1: Claude Vision 분석...');
      final analysisResult = await _claudeService.analyzePageComplete(imageFile);
      
      if (analysisResult == null) {
        safePrint('[ProblemSplit] ❌ Claude 분석 실패 → 기본 분할');
        return await _defaultSplit(imageFile, bookId, page, volumeName);
      }
      
      safePrint('[ProblemSplit] Claude 응답: $analysisResult');
      
      final sectionBounds = analysisResult['sectionBounds'] as Map<String, dynamic>?;
      if (sectionBounds == null || sectionBounds.isEmpty) {
        safePrint('[ProblemSplit] ❌ 섹션 감지 실패 → 기본 분할');
        return await _defaultSplit(imageFile, bookId, page, volumeName);
      }
      
      safePrint('[ProblemSplit] 감지된 섹션: ${sectionBounds.keys.toList()}');

      // 2. 저장 디렉토리 준비
      final problemsDir = await _getProblemsDirectory(bookId);
      final tempDir = await getTemporaryDirectory();
      final problems = <Problem>[];

      // 3. 각 섹션별로 처리 (ocr_test_page.dart의 _runExtraction 로직 그대로)
      for (final sectionName in sectionBounds.keys) {
        final bounds = sectionBounds[sectionName] as Map<String, dynamic>?;
        if (bounds == null) continue;
        
        safePrint('[ProblemSplit] --- Section $sectionName 처리 ---');
        
        // 3-1. 섹션 영역 crop
        final xStart = ((bounds['xStart'] as num?)?.toDouble() ?? 0) / 100 * image.width;
        final xEnd = ((bounds['xEnd'] as num?)?.toDouble() ?? 100) / 100 * image.width;
        final yStart = ((bounds['yStart'] as num?)?.toDouble() ?? 0) / 100 * image.height;
        final yEnd = ((bounds['yEnd'] as num?)?.toDouble() ?? 100) / 100 * image.height;
        
        final sectionWidth = (xEnd - xStart).round().clamp(1, image.width);
        final sectionHeight = (yEnd - yStart).round().clamp(1, image.height);
        
        if (sectionWidth < 50 || sectionHeight < 50) {
          safePrint('[ProblemSplit] Section $sectionName 너무 작음: ${sectionWidth}x$sectionHeight');
          continue;
        }
        
        final sectionImg = img.copyCrop(
          image,
          x: xStart.round().clamp(0, image.width - 1),
          y: yStart.round().clamp(0, image.height - 1),
          width: sectionWidth,
          height: sectionHeight,
        );
        
        final sectionFile = File('${tempDir.path}/p${page}_section_$sectionName.png');
        await sectionFile.writeAsBytes(img.encodePng(sectionImg));
        safePrint('[ProblemSplit] Section $sectionName crop: ${sectionWidth}x$sectionHeight');
        
        // 3-2. OCR로 문제 번호 위치 찾기 (ocr_test_page.dart 그대로)
        final ocrResult = await _findProblemNumbersWithOCR(sectionFile, sectionName);
        var ocrPositions = ocrResult['problems'] as List<Map<String, int>>;
        safePrint('[ProblemSplit] Section $sectionName: OCR ${ocrPositions.length}개 발견');
        
        if (ocrPositions.isEmpty) {
          safePrint('[ProblemSplit] Section $sectionName OCR 실패 → 스킵');
          continue;
        }

        // 3-3. 미감지 문제 재검사 (ocr_test_page.dart 그대로)
        final foundNumbers = ocrPositions.map((p) => p['number']!).toSet();
        final maxNumber = foundNumbers.reduce((a, b) => a > b ? a : b);
        final missingNumbers = <int>[];
        for (int num = 1; num <= maxNumber; num++) {
          if (!foundNumbers.contains(num)) {
            missingNumbers.add(num);
          }
        }

        if (missingNumbers.isNotEmpty) {
          safePrint('[ProblemSplit] $sectionName 미감지: $missingNumbers → 재검사');
          final retryResults = await _retryMissingProblems(
            sectionImage: sectionFile,
            foundPositions: ocrPositions,
            missingNumbers: missingNumbers,
            sectionName: sectionName,
          );
          ocrPositions.addAll(retryResults);
          ocrPositions.sort((a, b) => a['y']!.compareTo(b['y']!));
          safePrint('[ProblemSplit] $sectionName 재검사 후: ${ocrPositions.length}개');
        }

        // 3-4. 각 문제별 crop + 저장 (ocr_test_page.dart 그대로)
        for (int i = 0; i < ocrPositions.length; i++) {
          final pos = ocrPositions[i];
          final number = pos['number'] as int;
          final yPx = pos['y'] as int;
          
          // 다음 문제까지 영역
          int yEndPx;
          if (i < ocrPositions.length - 1) {
            yEndPx = ocrPositions[i + 1]['y'] as int;
          } else {
            yEndPx = sectionImg.height;
          }
          
          // 마진 (ocr_test_page.dart 그대로)
          final marginTop = (sectionImg.height * 0.01).round();
          final marginBottom = (sectionImg.height * 0.02).round();
          
          final cropY = (yPx - marginTop).clamp(0, sectionImg.height - 1);
          final cropYEnd = (yEndPx + marginBottom).clamp(cropY + 1, sectionImg.height);
          final cropHeight = cropYEnd - cropY;
          
          if (cropHeight < 20) {
            safePrint('[ProblemSplit] $sectionName.$number 높이 너무 작음: $cropHeight');
            continue;
          }
          
          final problemImg = img.copyCrop(
            sectionImg,
            x: 0,
            y: cropY,
            width: sectionImg.width,
            height: cropHeight,
          );
          
          // 저장 경로: p{page}_{section}_{number}.jpg
          final problemPath = '${problemsDir.path}/p${page}_${sectionName}_$number.jpg';
          await File(problemPath).writeAsBytes(img.encodeJpg(problemImg, quality: 90));
          
          // Problem 객체 생성
          final problem = Problem(
            id: '${bookId}_p${page}_${sectionName}_$number',
            page: page,
            problemNumber: number,
            volumeName: volumeName,
            imagePath: problemPath,
            boundingBox: {
              'x': 0,
              'y': cropY,
              'width': sectionImg.width,
              'height': cropHeight,
            },
          );
          
          problems.add(problem);
          safePrint('[ProblemSplit] ✓ $sectionName.$number 저장: $problemPath');
        }
      }

      safePrint('[ProblemSplit] ========== 분할 완료: ${problems.length}개 ==========');
      return problems;

    } catch (e, stackTrace) {
      safePrint('[ProblemSplit] ❌ 오류: $e');
      safePrint('[ProblemSplit] $stackTrace');
      return [];
    }
  }

  // ============================================================
  // ocr_test_page.dart의 _findProblemNumbersWithOCR 그대로 복사
  // ============================================================
  
  /// OCR로 문제 번호 위치 찾기 (찾은 것만 반환!)
  Future<Map<String, dynamic>> _findProblemNumbersWithOCR(
    File sectionImage,
    String sectionName,
  ) async {
    try {
      final inputImage = InputImage.fromFile(sectionImage);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      
      final foundPositions = <Map<String, int>>[];
      final foundNumbers = <int>{};  // 중복 방지
      
      // 1~20 범위의 문제 번호 찾기
      final targetNumbers = List.generate(20, (i) => i + 1);
      
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          
          for (final targetNum in targetNumbers) {
            if (foundNumbers.contains(targetNum)) continue;
            
            // 패턴 매칭 (ocr_test_page.dart 그대로)
            final isMatch = text == '$targetNum' ||
                text == '$targetNum.' ||
                text.startsWith('$targetNum ') ||
                text.startsWith('$targetNum. ') ||
                RegExp('^$targetNum\\s').hasMatch(text) ||
                RegExp('^$targetNum\\.\\s').hasMatch(text);
            
            if (isMatch) {
              final boundingBox = line.boundingBox;
              foundPositions.add({
                'number': targetNum,
                'y': boundingBox.top.round(),
              });
              foundNumbers.add(targetNum);
              safePrint('[OCR] $sectionName: $targetNum 발견 "$text" y=${boundingBox.top.round()}');
              break;
            }
          }
        }
      }
      
      foundPositions.sort((a, b) => a['y']!.compareTo(b['y']!));
      
      return {'problems': foundPositions};
      
    } catch (e) {
      safePrint('[OCR] 오류: $e');
      return {'problems': <Map<String, int>>[]};
    }
  }

  // ============================================================
  // ocr_test_page.dart의 _retryMissingProblems 그대로 복사
  // ============================================================

  /// 미감지 문제 재검사 (기존 좌표 기반 예측)
  Future<List<Map<String, int>>> _retryMissingProblems({
    required File sectionImage,
    required List<Map<String, int>> foundPositions,
    required List<int> missingNumbers,
    required String sectionName,
  }) async {
    if (foundPositions.isEmpty || missingNumbers.isEmpty) {
      safePrint('[Retry] 재검사 스킵: found=${foundPositions.length}, missing=${missingNumbers.length}');
      return [];
    }

    final bytes = await sectionImage.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return [];

    // 1. 평균 간격 계산 (ocr_test_page.dart 그대로)
    final yPositions = foundPositions.map((p) => p['y']!).toList()..sort();
    double avgGap;
    if (yPositions.length >= 2) {
      double totalGap = 0;
      for (int i = 1; i < yPositions.length; i++) {
        totalGap += yPositions[i] - yPositions[i - 1];
      }
      avgGap = totalGap / (yPositions.length - 1);
    } else {
      // 1개만 찾은 경우: 이미지 높이 / 문제 수로 추정
      final expectedCount = missingNumbers.isNotEmpty 
          ? missingNumbers.reduce((a, b) => a > b ? a : b) 
          : 4;
      avgGap = image.height / expectedCount;
      safePrint('[Retry] 1개만 찾음 → 추정 간격: ${avgGap.round()}px');
    }
    safePrint('[Retry] $sectionName 평균 간격: ${avgGap.round()}px');

    final retryFound = <Map<String, int>>[];
    final tempDir = await getTemporaryDirectory();

    // 2. 각 미감지 문제에 대해 예상 위치 계산 후 재검사 (ocr_test_page.dart 그대로)
    for (final missingNum in missingNumbers) {
      // 예상 위치 계산
      int? predictedY;

      // 방법 1: 앞뒤 문제 사이 보간
      final prevFound = foundPositions.where((p) => p['number']! < missingNum).toList();
      final nextFound = foundPositions.where((p) => p['number']! > missingNum).toList();

      if (prevFound.isNotEmpty && nextFound.isNotEmpty) {
        // 앞뒤 문제가 모두 있으면 선형 보간
        final prev = prevFound.reduce((a, b) => a['number']! > b['number']! ? a : b);
        final next = nextFound.reduce((a, b) => a['number']! < b['number']! ? a : b);
        final gap = next['y']! - prev['y']!;
        final numGap = next['number']! - prev['number']!;
        predictedY = prev['y']! + (gap * (missingNum - prev['number']!) ~/ numGap);
        safePrint('[Retry] $sectionName.$missingNum: 보간 예측 y=$predictedY');
      } else if (prevFound.isNotEmpty) {
        // 앞 문제만 있으면 평균 간격으로 예측
        final prev = prevFound.reduce((a, b) => a['number']! > b['number']! ? a : b);
        predictedY = prev['y']! + (avgGap * (missingNum - prev['number']!)).round();
        safePrint('[Retry] $sectionName.$missingNum: 앞 기준 예측 y=$predictedY');
      } else if (nextFound.isNotEmpty) {
        // 뒤 문제만 있으면 역산
        final next = nextFound.reduce((a, b) => a['number']! < b['number']! ? a : b);
        predictedY = next['y']! - (avgGap * (next['number']! - missingNum)).round();
        safePrint('[Retry] $sectionName.$missingNum: 뒤 기준 예측 y=$predictedY');
      }

      if (predictedY == null) continue;

      // 3. 예상 위치 주변 영역 crop (±평균간격의 50%)
      final margin = (avgGap * 0.5).round();
      final cropY = (predictedY - margin).clamp(0, image.height - 1);
      final cropHeight = (avgGap * 1.2).round().clamp(1, image.height - cropY);

      final cropImg = img.copyCrop(
        image,
        x: 0,
        y: cropY,
        width: image.width,
        height: cropHeight,
      );

      final cropFile = File('${tempDir.path}/retry_${sectionName}_$missingNum.png');
      await cropFile.writeAsBytes(img.encodePng(cropImg));

      safePrint('[Retry] $sectionName.$missingNum: crop y=$cropY~${cropY + cropHeight}');

      // 4. OCR 재시도 (ocr_test_page.dart 그대로)
      try {
        final inputImage = InputImage.fromFile(cropFile);
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        for (final block in recognizedText.blocks) {
          for (final line in block.lines) {
            final text = line.text.trim();

            final isMatch = text == '$missingNum' ||
                text == '$missingNum.' ||
                text.startsWith('$missingNum ') ||
                text.startsWith('$missingNum. ') ||
                RegExp('^$missingNum\\s').hasMatch(text) ||
                RegExp('^$missingNum\\.\\s').hasMatch(text);

            if (isMatch) {
              final boundingBox = line.boundingBox;
              // crop 영역 내 좌표 → 원본 좌표로 변환
              final originalY = cropY + boundingBox.top.round();
              retryFound.add({
                'number': missingNum,
                'y': originalY,
              });
              safePrint('[Retry] ✅ $sectionName.$missingNum 발견! y=$originalY');
              break;
            }
          }
          if (retryFound.any((p) => p['number'] == missingNum)) break;
        }
      } catch (e) {
        safePrint('[Retry] OCR 오류: $e');
      }
    }

    return retryFound;
  }

  /// API 실패 시 기본 분할 (세로 4등분)
  Future<List<Problem>> _defaultSplit(
    File imageFile,
    String bookId,
    int page,
    String volumeName,
  ) async {
    try {
      safePrint('[ProblemSplit] 기본 분할 (4등분)');
      
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return [];

      final problemsDir = await _getProblemsDirectory(bookId);
      final problems = <Problem>[];
      final quarterH = image.height ~/ 4;

      for (int i = 0; i < 4; i++) {
        final cropY = quarterH * i;
        final cropHeight = quarterH;
        
        final problemImg = img.copyCrop(
          image,
          x: 0,
          y: cropY,
          width: image.width,
          height: cropHeight,
        );
        
        final problemPath = '${problemsDir.path}/p${page}_q${i + 1}.jpg';
        await File(problemPath).writeAsBytes(img.encodeJpg(problemImg, quality: 90));
        
        problems.add(Problem(
          id: '${bookId}_p${page}_q${i + 1}',
          page: page,
          problemNumber: i + 1,
          volumeName: volumeName,
          imagePath: problemPath,
          boundingBox: {'x': 0, 'y': cropY, 'width': image.width, 'height': cropHeight},
        ));
      }

      return problems;
    } catch (e) {
      safePrint('[ProblemSplit] 기본 분할 실패: $e');
      return [];
    }
  }

  /// problems 디렉토리 생성
  Future<Directory> _getProblemsDirectory(String bookId) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final problemsDir = Directory('${documentsDir.path}/captures/$bookId/problems');
    if (!await problemsDir.exists()) {
      await problemsDir.create(recursive: true);
      safePrint('[ProblemSplit] problems 디렉토리 생성: ${problemsDir.path}');
    }
    return problemsDir;
  }
}
