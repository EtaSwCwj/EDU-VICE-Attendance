import 'dart:io';
import 'dart:ui' show Offset;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// PDF 파일을 청크로 분할하는 유틸리티
class PdfChunker {
  /// PDF 파일을 지정된 페이지 수로 분할
  /// 반환: List<File> - 분할된 PDF 파일들 (임시 파일)
  static Future<List<File>> splitPdf(File pdfFile, {int pagesPerChunk = 10}) async {
    safePrint('[PdfChunker] PDF 분할 시작: ${pdfFile.path}');

    final bytes = await pdfFile.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final totalPages = document.pages.count;

    safePrint('[PdfChunker] 총 페이지 수: $totalPages, 청크당 페이지: $pagesPerChunk');

    final tempDir = await getTemporaryDirectory();
    final chunks = <File>[];

    // 청크 수 계산
    final chunkCount = (totalPages / pagesPerChunk).ceil();
    safePrint('[PdfChunker] 생성할 청크 수: $chunkCount');

    for (int i = 0; i < chunkCount; i++) {
      final startPage = i * pagesPerChunk;
      final endPage = (startPage + pagesPerChunk).clamp(0, totalPages);

      safePrint('[PdfChunker] 청크 ${i + 1}/$chunkCount: 페이지 ${startPage + 1}~$endPage');

      // 새 PDF 문서 생성
      final chunkDoc = PdfDocument();

      // 원본에서 페이지 복사
      for (int j = startPage; j < endPage; j++) {
        final template = document.pages[j].createTemplate();
        final page = chunkDoc.pages.add();
        page.graphics.drawPdfTemplate(
          template,
          const Offset(0, 0),
        );
      }

      // 임시 파일로 저장
      final chunkPath = '${tempDir.path}/pdf_chunk_${i + 1}.pdf';
      final chunkBytes = await chunkDoc.save();
      final chunkFile = File(chunkPath);
      await chunkFile.writeAsBytes(chunkBytes);

      chunks.add(chunkFile);
      chunkDoc.dispose();

      safePrint('[PdfChunker] 청크 ${i + 1} 생성 완료: $chunkPath');
    }

    document.dispose();

    safePrint('[PdfChunker] PDF 분할 완료: ${chunks.length}개 청크');
    return chunks;
  }

  /// 청크별 페이지 범위 정보 반환
  static List<Map<String, int>> getChunkRanges(int totalPages, {int pagesPerChunk = 10}) {
    final ranges = <Map<String, int>>[];
    final chunkCount = (totalPages / pagesPerChunk).ceil();

    for (int i = 0; i < chunkCount; i++) {
      final startPage = i * pagesPerChunk + 1;  // 1-indexed for display
      final endPage = ((i + 1) * pagesPerChunk).clamp(1, totalPages);
      ranges.add({
        'start': startPage,
        'end': endPage,
        'index': i,
      });
    }

    return ranges;
  }

  /// PDF 총 페이지 수 확인
  static Future<int> getPageCount(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final count = document.pages.count;
    document.dispose();
    return count;
  }

  /// 임시 청크 파일들 삭제
  static Future<void> cleanupChunks(List<File> chunks) async {
    for (final chunk in chunks) {
      try {
        if (await chunk.exists()) {
          await chunk.delete();
          safePrint('[PdfChunker] 청크 삭제: ${chunk.path}');
        }
      } catch (e) {
        safePrint('[PdfChunker] 청크 삭제 실패: $e');
      }
    }
  }
}