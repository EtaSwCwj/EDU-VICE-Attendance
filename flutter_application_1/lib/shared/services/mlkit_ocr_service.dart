import 'dart:io';
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// Google ML Kit 기반 OCR 서비스
/// - 무료 + 오프라인 동작
/// - 텍스트 + bounding box 좌표 추출
class MlKitOcrService {
  final _textRecognizer = TextRecognizer();  // 기본 라틴 (한국어는 나중에)

  /// 이미지 파일에서 텍스트와 bounding box 추출
  Future<MlKitOcrResult> analyzeImage(File imageFile) async {
    try {
      safePrint('[MlKitOcr] 분석 시작: ${imageFile.path}');

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      safePrint('[MlKitOcr] 분석 완료: ${recognizedText.blocks.length}개 블록');

      final blocks = <OcrTextBlock>[];

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          blocks.add(OcrTextBlock(
            text: line.text,
            boundingBox: _convertBoundingBox(line.boundingBox, inputImage),
            confidence: line.confidence ?? 0,
          ));
        }
      }

      return MlKitOcrResult(
        blocks: blocks,
        imageWidth: inputImage.metadata?.size.width.toInt() ?? 0,
        imageHeight: inputImage.metadata?.size.height.toInt() ?? 0,
      );
    } catch (e) {
      safePrint('[MlKitOcr] ERROR: $e');
      rethrow;
    }
  }

  /// Rect를 0~1 비율 좌표로 변환
  OcrBoundingBox _convertBoundingBox(Rect? rect, InputImage inputImage) {
    if (rect == null) {
      return OcrBoundingBox(left: 0, top: 0, width: 0, height: 0);
    }

    // 이미지 크기 가져오기 (metadata가 없으면 rect 기준으로 추정)
    final imageWidth = inputImage.metadata?.size.width ?? rect.right + 100;
    final imageHeight = inputImage.metadata?.size.height ?? rect.bottom + 100;

    return OcrBoundingBox(
      left: rect.left / imageWidth,
      top: rect.top / imageHeight,
      width: rect.width / imageWidth,
      height: rect.height / imageHeight,
    );
  }

  /// 리소스 해제
  void dispose() {
    _textRecognizer.close();
  }
}

/// ML Kit OCR 분석 결과
class MlKitOcrResult {
  final List<OcrTextBlock> blocks;
  final int imageWidth;
  final int imageHeight;

  MlKitOcrResult({
    required this.blocks,
    required this.imageWidth,
    required this.imageHeight,
  });

  /// 문제 번호 패턴으로 블록 찾기 (예: "1", "1.", "1번", "(1)")
  List<OcrTextBlock> findProblemNumbers() {
    final pattern = RegExp(r'^[\(\[]?\d+[\)\].]?$|^\d+번$|^\d+\s');
    return blocks.where((b) {
      final trimmed = b.text.trim();
      // 문제 번호로 시작하는 라인 찾기
      return pattern.hasMatch(trimmed) || 
             RegExp(r'^\d+[.\s]').hasMatch(trimmed);
    }).toList();
  }

  /// 특정 텍스트를 포함하는 블록 찾기
  List<OcrTextBlock> findBlocksContaining(String text) {
    return blocks.where((b) => b.text.contains(text)).toList();
  }
}

/// 텍스트 블록
class OcrTextBlock {
  final String text;
  final OcrBoundingBox boundingBox;
  final double confidence;

  OcrTextBlock({
    required this.text,
    required this.boundingBox,
    required this.confidence,
  });

  @override
  String toString() => 'OcrTextBlock("$text", ${boundingBox.toRect()})';
}

/// Bounding Box (0~1 비율 좌표)
class OcrBoundingBox {
  final double left;   // 0~1
  final double top;    // 0~1
  final double width;  // 0~1
  final double height; // 0~1

  OcrBoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  double get right => left + width;
  double get bottom => top + height;

  /// 실제 픽셀 좌표로 변환
  Map<String, int> toPixels(int imageWidth, int imageHeight) {
    return {
      'left': (left * imageWidth).round(),
      'top': (top * imageHeight).round(),
      'width': (width * imageWidth).round(),
      'height': (height * imageHeight).round(),
    };
  }

  String toRect() =>
      'Rect(${left.toStringAsFixed(3)}, ${top.toStringAsFixed(3)}, ${width.toStringAsFixed(3)}, ${height.toStringAsFixed(3)})';
}
