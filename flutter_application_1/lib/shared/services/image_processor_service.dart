import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// 이미지 크롭 및 병합 서비스
class ImageProcessorService {

  /// 이미지를 열 개수에 따라 세로로 분할
  /// columns: 1, 2, 4
  /// 반환: 왼쪽부터 순서대로 크롭된 이미지들
  static Future<List<File>> cropByColumns(File imageFile, int columns) async {
    debugPrint('[ImageProcessor] 열 분할 시작: $columns열');

    if (columns <= 1) {
      debugPrint('[ImageProcessor] 1열 - 분할 불필요');
      return [imageFile];
    }

    final bytes = await imageFile.readAsBytes();
    final original = img.decodeImage(bytes);

    if (original == null) {
      debugPrint('[ImageProcessor] 이미지 디코딩 실패');
      return [imageFile];
    }

    final width = original.width;
    final height = original.height;
    final columnWidth = width ~/ columns;

    debugPrint('[ImageProcessor] 원본: ${width}x$height, 열당 너비: $columnWidth');

    final tempDir = await getTemporaryDirectory();
    final croppedImages = <File>[];

    for (int i = 0; i < columns; i++) {
      final x = i * columnWidth;
      final cropped = img.copyCrop(
        original,
        x: x,
        y: 0,
        width: columnWidth,
        height: height,
      );

      final croppedPath = '${tempDir.path}/column_${i + 1}.png';
      final croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(img.encodePng(cropped));

      croppedImages.add(croppedFile);
      debugPrint('[ImageProcessor] 열 ${i + 1} 크롭 완료: $croppedPath');
    }

    return croppedImages;
  }

  /// 여러 이미지를 세로로 병합
  /// 반환: 병합된 단일 이미지 파일
  static Future<File> mergeVertically(List<File> images) async {
    debugPrint('[ImageProcessor] 세로 병합 시작: ${images.length}개 이미지');

    if (images.isEmpty) {
      throw Exception('병합할 이미지가 없습니다');
    }

    if (images.length == 1) {
      debugPrint('[ImageProcessor] 1개 이미지 - 병합 불필요');
      return images.first;
    }

    // 모든 이미지 로드
    final loadedImages = <img.Image>[];
    int totalHeight = 0;
    int maxWidth = 0;

    for (final file in images) {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        loadedImages.add(decoded);
        totalHeight += decoded.height;
        if (decoded.width > maxWidth) {
          maxWidth = decoded.width;
        }
      }
    }

    debugPrint('[ImageProcessor] 병합 크기: ${maxWidth}x$totalHeight');

    // 새 캔버스 생성
    final merged = img.Image(width: maxWidth, height: totalHeight);

    // 흰색 배경
    img.fill(merged, color: img.ColorRgb8(255, 255, 255));

    // 이미지들 세로로 배치
    int currentY = 0;
    for (final image in loadedImages) {
      img.compositeImage(merged, image, dstX: 0, dstY: currentY);
      currentY += image.height;
    }

    // 파일로 저장
    final tempDir = await getTemporaryDirectory();
    final mergedPath = '${tempDir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.png';
    final mergedFile = File(mergedPath);
    await mergedFile.writeAsBytes(img.encodePng(merged));

    debugPrint('[ImageProcessor] 병합 완료: $mergedPath');
    return mergedFile;
  }

  /// 임시 파일들 정리
  static Future<void> cleanup(List<File> files) async {
    for (final file in files) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('[ImageProcessor] 파일 삭제 실패: $e');
      }
    }
  }
}