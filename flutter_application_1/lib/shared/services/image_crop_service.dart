import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'textract_service.dart';

/// 이미지 Crop 서비스
/// - Bounding box 좌표로 이미지 영역 추출
class ImageCropService {
  
  /// Bounding box로 이미지 영역 추출
  Future<File?> cropImage({
    required File sourceImage,
    required BoundingBox boundingBox,
    String? outputFileName,
  }) async {
    try {
      safePrint('[ImageCrop] 시작: ${boundingBox.toRect()}');
      
      // 이미지 로드
      final bytes = await sourceImage.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        safePrint('[ImageCrop] 이미지 디코딩 실패');
        return null;
      }
      
      // 픽셀 좌표 계산
      final pixels = boundingBox.toPixels(image.width, image.height);
      
      // 영역 추출 (약간의 padding 추가)
      const padding = 10;
      final x = (pixels['left']! - padding).clamp(0, image.width - 1);
      final y = (pixels['top']! - padding).clamp(0, image.height - 1);
      final w = (pixels['width']! + padding * 2).clamp(1, image.width - x);
      final h = (pixels['height']! + padding * 2).clamp(1, image.height - y);
      
      // Crop
      final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);
      
      // 임시 파일로 저장
      final tempDir = await getTemporaryDirectory();
      final fileName = outputFileName ?? 'crop_${DateTime.now().millisecondsSinceEpoch}.png';
      final outputFile = File('${tempDir.path}/$fileName');
      
      await outputFile.writeAsBytes(img.encodePng(cropped));
      
      safePrint('[ImageCrop] 완료: ${outputFile.path}');
      return outputFile;
      
    } catch (e) {
      safePrint('[ImageCrop] ERROR: $e');
      return null;
    }
  }
  
  /// 여러 영역을 한 번에 추출
  Future<List<CroppedImage>> cropMultiple({
    required File sourceImage,
    required List<ProblemRegion> regions,
  }) async {
    final results = <CroppedImage>[];
    
    for (final region in regions) {
      final cropped = await cropImage(
        sourceImage: sourceImage,
        boundingBox: region.boundingBox,
        outputFileName: 'problem_${region.problemNumber}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      
      if (cropped != null) {
        results.add(CroppedImage(
          problemNumber: region.problemNumber,
          file: cropped,
        ));
      }
    }
    
    return results;
  }
  
  /// 문제 번호들 사이의 영역 계산 (문제 N의 영역 = N번 시작 ~ N+1번 시작 전)
  List<ProblemRegion> calculateProblemRegions(
    List<TextBlock> problemBlocks,
    {double pageBottom = 1.0}
  ) {
    if (problemBlocks.isEmpty) return [];
    
    // Y좌표 기준 정렬
    final sorted = List<TextBlock>.from(problemBlocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
    
    final regions = <ProblemRegion>[];
    
    for (var i = 0; i < sorted.length; i++) {
      final current = sorted[i];
      final nextTop = (i < sorted.length - 1) 
          ? sorted[i + 1].boundingBox.top 
          : pageBottom;
      
      // 문제 번호 추출 (숫자만)
      final numberMatch = RegExp(r'\d+').firstMatch(current.text);
      final problemNumber = numberMatch?.group(0) ?? '${i + 1}';
      
      regions.add(ProblemRegion(
        problemNumber: problemNumber,
        boundingBox: BoundingBox(
          left: 0, // 전체 너비
          top: current.boundingBox.top,
          width: 1.0,
          height: nextTop - current.boundingBox.top,
        ),
      ));
    }
    
    return regions;
  }
}

/// 문제 영역 정보
class ProblemRegion {
  final String problemNumber;
  final BoundingBox boundingBox;
  
  ProblemRegion({
    required this.problemNumber,
    required this.boundingBox,
  });
}

/// Crop된 이미지 결과
class CroppedImage {
  final String problemNumber;
  final File file;
  
  CroppedImage({
    required this.problemNumber,
    required this.file,
  });
}
