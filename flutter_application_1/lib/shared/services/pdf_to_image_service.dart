import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdfx/pdfx.dart';
import 'package:image/image.dart' as img;

/// PDF를 이미지로 변환하는 서비스
class PdfToImageService {
  /// 단일 열로 간주할 가로/세로 비율 기준
  /// 비율 > 이 값이면 아직 여러 열 → 추가 분리 필요
  static const double _columnRatioThreshold = 0.7;

  /// PDF 파일의 각 페이지를 이미지로 변환 + 비율 기반 열 분리
  /// 
  /// BIG_144: 비율 기반 재귀 분리
  /// - 가로/세로 비율 > 0.7 → 2등분 후 재검사
  /// - 비율 <= 0.7 → 단일 열로 간주
  /// 
  /// 반환: List<File> - 분리된 열 이미지들
  static Future<List<File>> convertPdfToImages(
    File pdfFile, {
    int? maxPages,  // 테스트용: 처리할 최대 페이지 수
    String? bookName,  // 파일명에 포함할 책 이름
  }) async {
    final name = bookName ?? 'book';
    debugPrint('[PdfToImage] ========================================');
    debugPrint('[PdfToImage] PDF → 이미지 변환 시작');
    debugPrint('[PdfToImage] 파일: ${pdfFile.path}');
    debugPrint('[PdfToImage] 책 이름: $name');
    debugPrint('[PdfToImage] 열 분리 기준 비율: $_columnRatioThreshold');
    debugPrint('[PdfToImage] ========================================');

    final images = <File>[];
    
    // 외부 저장소 DCIM/flutter_1에 저장
    final outputDir = Directory('/storage/emulated/0/DCIM/flutter_1');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
      debugPrint('[PdfToImage] 디렉토리 생성: ${outputDir.path}');
    }

    try {
      final document = await PdfDocument.openFile(pdfFile.path);
      final pageCount = document.pagesCount;
      final pagesToProcess = maxPages != null ? maxPages.clamp(1, pageCount) : pageCount;

      debugPrint('[PdfToImage] 총 $pageCount 페이지, 처리할 페이지: $pagesToProcess');

      for (int i = 1; i <= pagesToProcess; i++) {
        debugPrint('[PdfToImage] ====== 페이지 $i/$pagesToProcess ======');

        final page = await document.getPage(i);
        final pageImage = await page.render(
          width: page.width * 2,  // 2배 해상도
          height: page.height * 2,
        );

        // 원본 이미지 저장 (흰색 배경 추가 - OCR 인식률 향상)
        // BIG_146: PNG 투명 배경 → JPG 흰색 배경 (ML Kit OCR 호환)
        final originalPath = '${outputDir.path}/${name}_page${i}_original.jpg';
        final originalFile = File(originalPath);
        
        final pngImage = img.decodeImage(pageImage!.bytes);
        if (pngImage != null) {
          // 흰색 배경 이미지 생성 후 원본 합성
          final withBackground = img.Image(width: pngImage.width, height: pngImage.height);
          img.fill(withBackground, color: img.ColorRgb8(255, 255, 255));
          img.compositeImage(withBackground, pngImage);
          await originalFile.writeAsBytes(img.encodeJpg(withBackground, quality: 95));
          debugPrint('[PdfToImage] JPG 변환 완료 (흰색 배경 추가)');
        } else {
          await originalFile.writeAsBytes(pageImage.bytes);
          debugPrint('[PdfToImage] 디코딩 실패, 원본 PNG 저장');
        }
        debugPrint('[PdfToImage] 원본 저장: $originalPath');

        // 비율 기반 재귀 분리
        final splitImages = await _splitByRatioRecursive(
          originalFile,
          '${outputDir.path}/${name}_page${i}',
          0,  // depth
        );
        images.addAll(splitImages);
        debugPrint('[PdfToImage] 페이지 $i → ${splitImages.length}개 열 이미지');

        await page.close();
      }

      await document.close();
      debugPrint('[PdfToImage] ========================================');
      debugPrint('[PdfToImage] 변환 완료: 총 ${images.length}개 열 이미지');
      debugPrint('[PdfToImage] 저장 위치: ${outputDir.path}');
      debugPrint('[PdfToImage] ========================================');

    } catch (e, stack) {
      debugPrint('[PdfToImage] 변환 실패: $e');
      debugPrint('[PdfToImage] 스택: $stack');
      rethrow;
    }

    return images;
  }

  /// 비율 기반 재귀 분리
  /// 가로/세로 비율이 기준보다 크면 2등분 후 재귀 호출
  static Future<List<File>> _splitByRatioRecursive(
    File imageFile,
    String outputPrefix,
    int depth,
  ) async {
    final results = <File>[];
    final indent = '  ' * depth;  // 로그 들여쓰기
    
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      debugPrint('$indent[Split] 이미지 디코딩 실패: ${imageFile.path}');
      return results;
    }

    final width = image.width;
    final height = image.height;
    final ratio = width / height;

    debugPrint('$indent[Split] depth=$depth, 크기=${width}x$height, 비율=${ratio.toStringAsFixed(3)}');

    // 비율 체크: 기준 이하면 단일 열로 간주
    if (ratio <= _columnRatioThreshold) {
      debugPrint('$indent[Split] → 단일 열로 간주 (비율 <= $_columnRatioThreshold)');
      
      // BIG_146: JPG로 저장 (흰색 배경 유지)
      final colPath = '${outputPrefix}_col${depth > 0 ? "_d$depth" : ""}_final.jpg';
      await imageFile.copy(colPath);
      results.add(File(colPath));
      debugPrint('$indent[Split] → 저장: $colPath');
      return results;
    }

    // 비율이 기준보다 크면 2등분
    debugPrint('$indent[Split] → 2등분 필요 (비율 > $_columnRatioThreshold)');
    
    final halfWidth = width ~/ 2;

    // BIG_146: 열 분리도 JPG로 저장 (흰색 배경 유지)
    // 왼쪽 절반
    final leftCropped = img.copyCrop(image, x: 0, y: 0, width: halfWidth, height: height);
    final leftPath = '${outputPrefix}_d${depth}_left.jpg';
    final leftFile = File(leftPath);
    await leftFile.writeAsBytes(img.encodeJpg(leftCropped, quality: 95));
    debugPrint('$indent[Split] 왼쪽 저장: $leftPath');

    // 오른쪽 절반
    final rightCropped = img.copyCrop(image, x: halfWidth, y: 0, width: width - halfWidth, height: height);
    final rightPath = '${outputPrefix}_d${depth}_right.jpg';
    final rightFile = File(rightPath);
    await rightFile.writeAsBytes(img.encodeJpg(rightCropped, quality: 95));
    debugPrint('$indent[Split] 오른쪽 저장: $rightPath');

    // 재귀 호출
    final leftResults = await _splitByRatioRecursive(leftFile, '${outputPrefix}_L', depth + 1);
    final rightResults = await _splitByRatioRecursive(rightFile, '${outputPrefix}_R', depth + 1);

    results.addAll(leftResults);
    results.addAll(rightResults);

    return results;
  }

  /// 단일 이미지 파일 열 분리 (갤러리용)
  /// PDF가 아닌 일반 이미지에도 동일한 열 분리 로직 적용
  static Future<List<File>> splitImageByRatio(File imageFile, {String? bookName}) async {
    final name = bookName ?? 'gallery';
    debugPrint('[ImageSplit] ========================================');
    debugPrint('[ImageSplit] 이미지 열 분리 시작');
    debugPrint('[ImageSplit] 파일: ${imageFile.path}');
    debugPrint('[ImageSplit] ========================================');

    // 외부 저장소 DCIM/flutter_1에 저장
    final outputDir = Directory('/storage/emulated/0/DCIM/flutter_1');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    // 원본 이미지를 JPG로 변환 (흰색 배경 보장)
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    
    if (originalImage == null) {
      debugPrint('[ImageSplit] 이미지 디코딩 실패');
      return [imageFile];  // 실패시 원본 반환
    }

    // 흰색 배경 추가 후 JPG 저장
    final withBackground = img.Image(width: originalImage.width, height: originalImage.height);
    img.fill(withBackground, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(withBackground, originalImage);
    
    final jpgPath = '${outputDir.path}/${name}_original.jpg';
    final jpgFile = File(jpgPath);
    await jpgFile.writeAsBytes(img.encodeJpg(withBackground, quality: 95));
    debugPrint('[ImageSplit] JPG 변환 완료: $jpgPath');

    // 비율 기반 재귀 분리
    final splitImages = await _splitByRatioRecursive(
      jpgFile,
      '${outputDir.path}/${name}',
      0,
    );

    debugPrint('[ImageSplit] ========================================');
    debugPrint('[ImageSplit] 분리 완료: ${splitImages.length}개 열 이미지');
    debugPrint('[ImageSplit] ========================================');

    return splitImages;
  }

  /// 임시 이미지 파일들 정리
  static Future<void> cleanupImages(List<File> images) async {
    for (final image in images) {
      try {
        if (await image.exists()) {
          await image.delete();
          debugPrint('[PdfToImage] 이미지 삭제: ${image.path}');
        }
      } catch (e) {
        debugPrint('[PdfToImage] 이미지 삭제 실패: $e');
      }
    }
  }
}
