import 'dart:io';
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/problem.dart';

/// 문제 분할 서비스
/// - 페이지 이미지에서 개별 문제를 감지하고 분할
class ProblemSplitService {
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-20250514';
  final _storage = const FlutterSecureStorage();

  Future<String?> _getApiKey() async {
    return await _storage.read(key: 'claude_api_key');
  }

  /// 페이지 이미지에서 문제들을 분할
  /// 
  /// [imageFile] - 촬영된 페이지 이미지
  /// [bookId] - 책 ID
  /// [page] - 페이지 번호
  /// [volumeName] - Volume 이름
  /// 
  /// Returns: 분할된 Problem 리스트
  Future<List<Problem>> splitProblems({
    required File imageFile,
    required String bookId,
    required int page,
    required String volumeName,
  }) async {
    try {
      safePrint('[ProblemSplit] 문제 분할 시작: p$page ($volumeName)');

      // 1. 원본 이미지를 pages 폴더에 저장
      final pagesDir = await _getPagesDirectory(bookId);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalPath = '${pagesDir.path}/p${page}_$timestamp.jpg';
      await imageFile.copy(originalPath);
      safePrint('[ProblemSplit] 원본 저장: $originalPath');

      // 2. Claude API로 문제 영역 감지
      final regions = await _detectProblemRegions(imageFile);
      safePrint('[ProblemSplit] 감지된 문제: ${regions.length}개');

      if (regions.isEmpty) {
        safePrint('[ProblemSplit] 감지된 문제 없음 - 기본 분할 적용');
        // 기본 분할 적용
        final defaultRegions = await _defaultSplit(imageFile);
        return await _cropAndSaveProblems(imageFile, defaultRegions, bookId, page, volumeName);
      }

      // 3. 각 문제 영역 크롭 및 저장
      return await _cropAndSaveProblems(imageFile, regions, bookId, page, volumeName);

    } catch (e) {
      safePrint('[ProblemSplit] 분할 실패: $e');
      // 실패해도 기본 분할 시도
      try {
        final defaultRegions = await _defaultSplit(imageFile);
        return await _cropAndSaveProblems(imageFile, defaultRegions, bookId, page, volumeName);
      } catch (e2) {
        safePrint('[ProblemSplit] 기본 분할도 실패: $e2');
        return [];
      }
    }
  }

  /// 문제 영역 크롭 및 저장
  Future<List<Problem>> _cropAndSaveProblems(
    File imageFile,
    List<Map<String, dynamic>> regions,
    String bookId,
    int page,
    String volumeName,
  ) async {
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) {
      throw Exception('이미지 디코딩 실패');
    }

    final problemsDir = await _getProblemsDirectory(bookId);
    final problems = <Problem>[];

    for (final region in regions) {
      final problemNum = region['problemNumber'] as int;
      final x = region['x'] as int;
      final y = region['y'] as int;
      final width = region['width'] as int;
      final height = region['height'] as int;

      // 크롭 (여유 마진 추가)
      final margin = 10;
      final cropX = (x - margin).clamp(0, originalImage.width - 1);
      final cropY = (y - margin).clamp(0, originalImage.height - 1);
      final cropW = (width + margin * 2).clamp(1, originalImage.width - cropX);
      final cropH = (height + margin * 2).clamp(1, originalImage.height - cropY);

      final cropped = img.copyCrop(
        originalImage,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );

      // 저장
      final problemPath = '${problemsDir.path}/p${page}_q$problemNum.jpg';
      final croppedBytes = img.encodeJpg(cropped, quality: 90);
      await File(problemPath).writeAsBytes(croppedBytes);

      // Problem 객체 생성
      final problem = Problem(
        id: '${bookId}_p${page}_q$problemNum',
        page: page,
        problemNumber: problemNum,
        volumeName: volumeName,
        imagePath: problemPath,
        boundingBox: {
          'x': cropX,
          'y': cropY,
          'width': cropW,
          'height': cropH,
        },
      );

      problems.add(problem);
      safePrint('[ProblemSplit] 문제 $problemNum 저장: $problemPath');
    }

    safePrint('[ProblemSplit] 분할 완료: ${problems.length}개');
    return problems;
  }

  /// Claude API로 문제 영역 감지
  Future<List<Map<String, dynamic>>> _detectProblemRegions(File imageFile) async {
    try {
      final apiKey = await _getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        safePrint('[ProblemSplit] API 키 없음 - 기본 분할 사용');
        return [];
      }

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mediaType = extension == 'png' ? 'image/png' : 'image/jpeg';

      final prompt = '''
이 교재/문제집 페이지 이미지를 분석해주세요.

각 문제의 위치를 찾아서 다음 JSON 형식으로 반환해주세요:
{
  "problems": [
    {
      "problemNumber": 1,
      "x": 픽셀_X좌표,
      "y": 픽셀_Y좌표,
      "width": 너비,
      "height": 높이
    }
  ]
}

규칙:
1. 문제 번호가 있는 영역을 찾으세요 (1, 2, 3... 또는 1번, 2번...)
2. 각 문제의 시작점(왼쪽 상단)과 크기를 픽셀 단위로 반환
3. 문제가 없으면 빈 배열 반환
4. JSON만 반환하고 다른 텍스트는 포함하지 마세요
5. 문제 영역은 다음 문제 시작 전까지 포함 (보기, 빈칸 포함)
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 2048,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Image,
                  },
                },
                {'type': 'text', 'text': prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        safePrint('[ProblemSplit] API 응답: $content');

        // JSON 파싱
        String jsonStr = content;
        if (content.contains('```json')) {
          jsonStr = content.split('```json')[1].split('```')[0].trim();
        } else if (content.contains('```')) {
          jsonStr = content.split('```')[1].split('```')[0].trim();
        } else if (content.contains('{')) {
          final start = content.indexOf('{');
          final end = content.lastIndexOf('}') + 1;
          jsonStr = content.substring(start, end);
        }

        final parsed = json.decode(jsonStr) as Map<String, dynamic>;
        final problems = (parsed['problems'] as List<dynamic>?)
            ?.map((p) => Map<String, dynamic>.from(p as Map))
            .toList() ?? [];

        return problems;
      } else {
        safePrint('[ProblemSplit] API 에러: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      safePrint('[ProblemSplit] API 호출 실패: $e');
      return [];
    }
  }

  /// API 실패 시 기본 분할 (페이지를 세로 4등분)
  Future<List<Map<String, dynamic>>> _defaultSplit(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return [];

      final w = image.width;
      final h = image.height;
      final quarterH = h ~/ 4;

      // 세로 4등분 (문제 1,2,3,4로 가정)
      return [
        {'problemNumber': 1, 'x': 0, 'y': 0, 'width': w, 'height': quarterH},
        {'problemNumber': 2, 'x': 0, 'y': quarterH, 'width': w, 'height': quarterH},
        {'problemNumber': 3, 'x': 0, 'y': quarterH * 2, 'width': w, 'height': quarterH},
        {'problemNumber': 4, 'x': 0, 'y': quarterH * 3, 'width': w, 'height': quarterH},
      ];
    } catch (e) {
      safePrint('[ProblemSplit] 기본 분할 실패: $e');
      return [];
    }
  }

  /// pages 디렉토리 생성
  Future<Directory> _getPagesDirectory(String bookId) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final pagesDir = Directory('${documentsDir.path}/captures/$bookId/pages');
    if (!await pagesDir.exists()) {
      await pagesDir.create(recursive: true);
      safePrint('[ProblemSplit] pages 디렉토리 생성: ${pagesDir.path}');
    }
    return pagesDir;
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

  /// 저장된 원본 이미지 경로 조회
  Future<String?> getPageImagePath(String bookId, int page) async {
    try {
      final pagesDir = await _getPagesDirectory(bookId);
      final files = await pagesDir.list().toList();
      
      for (final file in files) {
        if (file is File && file.path.contains('p$page')) {
          return file.path;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 책의 모든 이미지 삭제
  Future<void> deleteAllImages(String bookId) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final bookDir = Directory('${documentsDir.path}/captures/$bookId');
      if (await bookDir.exists()) {
        await bookDir.delete(recursive: true);
        safePrint('[ProblemSplit] 이미지 폴더 삭제: ${bookDir.path}');
      }
    } catch (e) {
      safePrint('[ProblemSplit] 이미지 삭제 실패: $e');
    }
  }

  /// 특정 페이지의 문제 이미지들 조회
  Future<List<File>> getProblemImages(String bookId, int page) async {
    try {
      final problemsDir = await _getProblemsDirectory(bookId);
      final files = await problemsDir.list().toList();
      
      return files
          .whereType<File>()
          .where((f) => f.path.contains('p${page}_q'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
    } catch (e) {
      safePrint('[ProblemSplit] 문제 이미지 조회 실패: $e');
      return [];
    }
  }
}
