import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ClaudeApiService {
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-20250514';
  static const _modelHaiku = 'claude-3-5-haiku-20241022';  // PDF 처리용 (저렴)
  final _storage = const FlutterSecureStorage();

  Future<String?> _getApiKey() async {
    return await _storage.read(key: 'claude_api_key');
  }

  /// 이미지 또는 PDF 파일 분석
  Future<Map<String, dynamic>?> analyzeTextbookFile(File file) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    // 파일을 base64로 변환
    final bytes = await file.readAsBytes();
    final base64Data = base64Encode(bytes);

    // 확장자로 파일 타입 결정
    final extension = file.path.split('.').last.toLowerCase();
    final isPdf = extension == 'pdf';
    
    final mediaType = switch (extension) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    const prompt = '''
이 교재 페이지를 분석해서 다음 JSON 형식으로 반환해주세요.
반드시 JSON만 반환하고, 다른 텍스트는 포함하지 마세요.

{
  "pageInfo": {
    "pageNumber": 페이지 번호 (숫자),
    "chapterTitle": "단원명",
    "section": "대단원명 (있으면)"
  },
  "problems": [
    {
      "number": "문제 번호 (1, 2, 1-1 등)",
      "question": "문제 내용 요약",
      "difficulty": "BASIC 또는 MEDIUM 또는 HARD",
      "category": "CONCEPT 또는 APPLICATION",
      "answer": "정답 (보이면)",
      "concepts": ["관련 개념1", "관련 개념2"]
    }
  ]
}

난이도 판단 기준:
- BASIC: 단순 계산, 개념 확인
- MEDIUM: 2-3단계 풀이 필요
- HARD: 복합 개념, 서술형, 고난도

카테고리 판단 기준:
- CONCEPT: 개념/공식 확인, 단순 적용
- APPLICATION: 응용, 실생활, 융합 문제
''';

    // PDF vs 이미지 content 구성
    final fileContent = isPdf
        ? {
            'type': 'document',
            'source': {
              'type': 'base64',
              'media_type': mediaType,
              'data': base64Data,
            },
          }
        : {
            'type': 'image',
            'source': {
              'type': 'base64',
              'media_type': mediaType,
              'data': base64Data,
            },
          };

    try {
      debugPrint('[ClaudeAPI] 파일 분석 시작: $extension, isPdf: $isPdf');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 4096,
          'messages': [
            {
              'role': 'user',
              'content': [
                fileContent,
                {
                  'type': 'text',
                  'text': prompt,
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;

        // JSON 파싱 시도
        try {
          // JSON 블록 추출 (```json ... ``` 형태일 수 있음)
          String jsonStr = content;
          if (content.contains('```json')) {
            jsonStr = content.split('```json')[1].split('```')[0].trim();
          } else if (content.contains('```')) {
            jsonStr = content.split('```')[1].split('```')[0].trim();
          }

          return jsonDecode(jsonStr) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('[ClaudeAPI] JSON 파싱 실패: $e');
          debugPrint('[ClaudeAPI] 원본 응답: $content');
          return {'raw': content, 'error': 'JSON 파싱 실패'};
        }
      } else {
        debugPrint('[ClaudeAPI] 에러: ${response.statusCode}');
        debugPrint('[ClaudeAPI] 응답: ${response.body}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ClaudeAPI] 예외: $e');
      rethrow;
    }
  }

  /// 기존 메서드 호환성 유지
  Future<Map<String, dynamic>?> analyzeTextbookImage(File imageFile) async {
    return analyzeTextbookFile(imageFile);
  }

  /// 이미지를 보고 문제 번호 + 위치 파악 (목차 힌트 포함)
  Future<Map<String, dynamic>?> detectProblemsWithLayout(
    File imageFile, {
    List<String>? expectedNumbers,  // 목차에서 파악한 문제 번호들
  }) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    // 이미지를 base64로 변환
    final bytes = await imageFile.readAsBytes();
    final base64Data = base64Encode(bytes);
    
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mediaType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };

    // 목차 힌트가 있으면 프롬프트에 추가
    final hintText = expectedNumbers != null && expectedNumbers.isNotEmpty
        ? '\n\n참고: 이 페이지에는 ${expectedNumbers.join(", ")}번 문제가 있습니다.'
        : '';

    final prompt = '''
이 교재 페이지를 분석해주세요.
$hintText

중요:
- 각 문제의 영역은 문제 번호부터 다음 문제 시작 전까지 전체를 포함해야 합니다
- 보기(①②③), 풀이 공간도 해당 문제 영역에 포함하세요
- 영역이 잘리지 않도록 넉넉하게 잡아주세요

반드시 JSON만 반환하세요:
{
  "layout": {
    "columns": 1 또는 2,
    "description": "레이아웃 설명"
  },
  "problems": [
    {
      "number": "문제번호",
      "position": {
        "column": "left" 또는 "right" 또는 "full",
        "verticalOrder": 1부터 순서 (해당 열에서 몇번째)
      },
      "region": {
        "xPercent": 0~100 (왼쪽 시작점 %),
        "yPercent": 0~100 (위쪽 시작점 %),
        "widthPercent": 0~100 (너비 %),
        "heightPercent": 0~100 (높이 %)
      }
    }
  ]
}

예시 (2열 레이아웃):
- 1번이 왼쪽 상단에 있고 높이가 페이지의 30% 정도면:
  xPercent=0, yPercent=10, widthPercent=50, heightPercent=30
''';

    try {
      debugPrint('[ClaudeAPI] 이미지에서 문제 + 레이아웃 감지 시작');
      if (expectedNumbers != null) {
        debugPrint('[ClaudeAPI] 힌트: $expectedNumbers');
      }
      
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
                    'data': base64Data,
                  },
                },
                {
                  'type': 'text',
                  'text': prompt,
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;

        debugPrint('[ClaudeAPI] 감지 응답: $content');

        // JSON 파싱
        try {
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

          return jsonDecode(jsonStr) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('[ClaudeAPI] JSON 파싱 실패: $e');
          return null;
        }
      } else {
        debugPrint('[ClaudeAPI] 에러: ${response.statusCode}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ClaudeAPI] 예외: $e');
      rethrow;
    }
  }

  /// 책 이미지 종합 분석 (책 영역 + 회전 + 페이지 분리 + 페이지 번호)
  Future<Map<String, dynamic>?> analyzeBookImage(File imageFile) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Data = base64Encode(bytes);
    
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mediaType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };

    const prompt = '''
이 책 페이지 사진을 분석해주세요.

반드시 JSON만 반환하세요:
{
  "rotation": 0/90/180/270 (시계방향 회전 필요 각도, 텍스트가 정상으로 읽히도록),
  "pageCount": 1 또는 2 (보이는 페이지 수),
  "bookArea": {
    "xStart": 0~100 (책 시작 x%),
    "yStart": 0~100 (책 시작 y%),
    "width": 0~100 (책 너비%),
    "height": 0~100 (책 높이%)
  },
  "pages": [
    {
      "position": "left" 또는 "right" 또는 "single",
      "pageNumber": 페이지 번호 (숫자, 없으면 null),
      "unitInfo": "Unit XX" 또는 null,
      "sections": ["A", "B", "C", "D"] 보이는 섹션들
    }
  ]
}

중요:
- bookArea: 손, 책상, 그림자 등 책 외부 영역을 제외한 순수 책 영역
- rotation: 텍스트가 오른쪽으로 누워있으면 270, 왼쪽으로 누워있으면 90
- 2페이지 펼침이면 pages 배열에 2개, 1페이지면 1개
- 페이지 번호는 책에 인쇄된 숫자를 읽어주세요
''';

    try {
      debugPrint('[ClaudeAPI] 책 이미지 종합 분석 시작');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Data,
                  },
                },
                {
                  'type': 'text',
                  'text': prompt,
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;

        debugPrint('[ClaudeAPI] 분석 응답: $content');

        try {
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

          return jsonDecode(jsonStr) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('[ClaudeAPI] JSON 파싱 실패: $e');
          return null;
        }
      } else {
        debugPrint('[ClaudeAPI] 에러: ${response.statusCode}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ClaudeAPI] 예외: $e');
      rethrow;
    }
  }

  /// 이미지 전처리 분석 (회전 필요 여부 + 페이지 인식) - 단순 버전
  Future<Map<String, dynamic>?> analyzeImagePreprocess(File imageFile) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Data = base64Encode(bytes);
    
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mediaType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };

    const prompt = '''
이 교재 페이지 이미지를 분석해주세요.

반드시 JSON만 반환하세요:
{
  "rotation": 0 또는 90 또는 180 또는 270 (시계방향 회전 필요 각도),
  "pageNumber": 페이지 번호 (숫자만, 없으면 null),
  "unitInfo": "Unit XX" 또는 null,
  "sectionInfo": "Practice" 또는 "Actual Test" 등,
  "visibleSections": ["A", "B", "C", "D"] 보이는 섹션들,
  "confidence": 0~100 (확신도)
}

회전 판단 기준:
- 텍스트가 정상적으로 읽히면 rotation=0
- 텍스트가 오른쪽으로 90도 누워있으면 rotation=270 (반시계 90도 = 시계 270도)
- 텍스트가 왼쪽으로 90도 누워있으면 rotation=90
- 거꾸로면 rotation=180
''';

    try {
      debugPrint('[ClaudeAPI] 이미지 전처리 분석 시작');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 512,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Data,
                  },
                },
                {
                  'type': 'text',
                  'text': prompt,
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;

        debugPrint('[ClaudeAPI] 전처리 분석 응답: $content');

        try {
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

          return jsonDecode(jsonStr) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('[ClaudeAPI] JSON 파싱 실패: $e');
          return null;
        }
      } else {
        debugPrint('[ClaudeAPI] 에러: ${response.statusCode}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ClaudeAPI] 예외: $e');
      rethrow;
    }
  }

  /// 페이지에서 문제 위치(Y좌표) 자동 감지
  /// 반환: {"A": {"1": {"yStart": 10, "yEnd": 18}, "2": {...}}, "B": {...}}
  Future<Map<String, dynamic>?> detectProblemPositions(File imageFile) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Data = base64Encode(bytes);
    
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mediaType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };

    try {
      debugPrint('[ClaudeAPI] 문제 위치 감지 시작');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 2000,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Data,
                  },
                },
                {
                  'type': 'text',
                  'text': '''이 교재 페이지에서 각 문제의 위치를 찾아주세요.

★★★ 매우 중요 ★★★
1. 각 문제를 독립적으로 찾으세요 (이전 문제 위치와 무관하게!)
2. 문제 번호(1, 2, 3...)가 보이는 줄을 기준으로 시작점 찾기
3. 문제 영역이 서로 겹쳐도 괜찮습니다! (예: 1번이 12~20%, 2번이 18~26%)
4. 각 문제는 여유있게 잡으세요 (위아래 margin 포함)

Y좌표 = 페이지 전체 높이 대비 % (상단=0%, 하단=100%)

반드시 JSON만 반환:
{
  "sections": {
    "A": {
      "problems": {
        "1": {"yStart": 12, "yEnd": 20, "text": "문제의 핵심 텍스트 일부"},
        "2": {"yStart": 18, "yEnd": 26, "text": "문제의 핵심 텍스트 일부"}
      }
    }
  }
}

text 필드: 해당 영역에서 실제로 보이는 문제 텍스트 일부 (검증용, 5~10단어)''',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        debugPrint('[ClaudeAPI] 문제 위치 응답: $content');

        // JSON 파싱
        try {
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
          return jsonDecode(jsonStr) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('[ClaudeAPI] JSON 파싱 실패: $e');
          return null;
        }
      } else {
        debugPrint('[ClaudeAPI] 에러: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[ClaudeAPI] 문제 위치 감지 예외: $e');
      return null;
    }
  }

  /// 텍스트 가독성 점수 확인 (0~100)
  /// 이미지에서 텍스트가 정상적으로 읽히는지 확인
  Future<int> checkTextReadability(File imageFile) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) return 0;

    final bytes = await imageFile.readAsBytes();
    final base64Data = base64Encode(bytes);
    
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mediaType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 100,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Data,
                  },
                },
                {
                  'type': 'text',
                  'text': '''이 이미지의 텍스트가 정상적으로 읽히나요?

- 텍스트가 정상 방향으로 잘 읽히면: 90~100점
- 텍스트가 약간 기울어져 있지만 읽혀지면: 60~80점
- 텍스트가 옆으로 누워있거나 거꾸로면: 0~30점

답변은 숫자만 (0~100)''',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] as String;
        debugPrint('[ClaudeAPI] 가독성 응답: $text');
        
        final match = RegExp(r'\d+').firstMatch(text);
        if (match != null) {
          return int.parse(match.group(0)!).clamp(0, 100);
        }
      }
      return 0;
    } catch (e) {
      debugPrint('[ClaudeAPI] 가독성 확인 예외: $e');
      return 0;
    }
  }

  /// Step 1: 회전 각도 + 페이지 수 감지 (한 번에)
  Future<Map<String, int>> detectRotationAndPageCount(File imageFile) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Data = base64Encode(bytes);
    
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mediaType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };

    try {
      debugPrint('[ClaudeAPI] 회전 + 페이지 수 감지 시작');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 50,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Data,
                  },
                },
                {
                  'type': 'text',
                  'text': '''이 책 사진을 분석해주세요.

**회전 판단 방법:**
사진에서 영어 단어나 한글을 찾아보세요.
- 글자가 정상적으로 읽히면 (ABC가 왼쪽→오른쪽): 회전=0
- 글자가 세로로 서있고 위에서 아래로 읽혀야 하면 (A\nB\nC 형태): 회전=270
- 글자가 세로로 서있고 아래에서 위로 읽혀야 하면: 회전=90
- 글자가 거꾸로 뒤집혀 있으면: 회전=180

**페이지 수:**
- 책 페이지 1장만 보이면: 페이지=1
- 책을 펼쳐서 2장이 보이면: 페이지=2

이 사진에서 "Practice" 또는 "Unit" 같은 영어 단어가 어떻게 보이나요?

답변 형식만: "회전:270 페이지:1"''',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] as String;
        debugPrint('[ClaudeAPI] 회전+페이지 응답: $text');
        
        // 파싱
        int rotation = 0;
        int pageCount = 1;
        
        final rotMatch = RegExp(r'회전[:\s]*(0|90|180|270)').firstMatch(text);
        if (rotMatch != null) {
          rotation = int.parse(rotMatch.group(1)!);
        } else {
          // 숫자만 있는 경우 첫 번째를 회전으로
          final nums = RegExp(r'(0|90|180|270)').firstMatch(text);
          if (nums != null) rotation = int.parse(nums.group(0)!);
        }
        
        final pageMatch = RegExp(r'페이지[:\s]*(1|2)').firstMatch(text);
        if (pageMatch != null) {
          pageCount = int.parse(pageMatch.group(1)!);
        } else if (text.contains('2')) {
          pageCount = 2;
        }
        
        return {'rotation': rotation, 'pageCount': pageCount};
      } else {
        debugPrint('[ClaudeAPI] 에러: ${response.statusCode}');
      }
      return {'rotation': 0, 'pageCount': 1};
    } catch (e) {
      debugPrint('[ClaudeAPI] 회전+페이지 감지 예외: $e');
      return {'rotation': 0, 'pageCount': 1};
    }
  }

  /// Step 1: 회전 각도만 감지 (단순화) - 기존 호환용
  Future<int> detectRotation(File imageFile) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Data = base64Encode(bytes);
    
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mediaType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };

    try {
      debugPrint('[ClaudeAPI] 회전 감지 시작');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 50,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Data,
                  },
                },
                {
                  'type': 'text',
                  'text': '''이 이미지의 텍스트를 정상적으로 읽으려면 시계 방향으로 몇 도 회전해야 하나요?
답변은 숫자만: 0, 90, 180, 270 중 하나만 답하세요.''',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] as String;
        debugPrint('[ClaudeAPI] 회전 응답: $text');
        
        final match = RegExp(r'(0|90|180|270)').firstMatch(text);
        if (match != null) {
          return int.parse(match.group(0)!);
        }
      } else {
        debugPrint('[ClaudeAPI] 에러: ${response.statusCode}');
      }
      return 0;
    } catch (e) {
      debugPrint('[ClaudeAPI] 회전 감지 예외: $e');
      return 0;
    }
  }

  /// 페이지 번호만 인식 (단순화)
  Future<int> detectPageNumber(File imageFile) async {
    final result = await analyzePageComplete(imageFile);
    return result?['pageNumber'] as int? ?? 0;
  }

  /// ML Kit OCR로 추출한 텍스트를 정답 데이터로 파싱
  /// BIG_136: 텍스트 전용 Claude AI 파싱 (이미지 없이)
  /// 
  /// 반환 형식 (answer_parser_service.dart가 기대하는 구조):
  /// [
  ///   {
  ///     'pageNumber': 9,
  ///     'sections': {'A': ['답1', '답2'], 'B': ['답1']},
  ///     'content': 'Unit 01...\nA)\n1. 답1\n...'
  ///   }
  /// ]
  Future<List<Map<String, dynamic>>> parseOcrTextToAnswers(String ocrText) async {
    debugPrint('[Claude] ========== parseOcrTextToAnswers 시작 ==========');
    debugPrint('[Claude] OCR 텍스트 길이: ${ocrText.length}자');

    // ★ BIG_143: AI 입력 텍스트 상세 로그 (줄바꿈 치환)
    final inputForLog = ocrText.replaceAll('\n', '↵');
    final inputPreview = inputForLog.length > 500 ? inputForLog.substring(0, 500) : inputForLog;
    debugPrint('[Claude] AI 입력 OCR 앞 500자: $inputPreview');

    try {
      final apiKey = await _getApiKey();
      if (apiKey == null) {
        throw Exception('API 키가 설정되지 않았습니다');
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _modelHaiku,  // 비용 절감
          'max_tokens': 4096,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': '''
다음은 교육용 학습 관리 시스템(LMS)에서 ML Kit OCR로 추출한 텍스트입니다.
학생 학습 진도 추적을 위해 정답 데이터를 구조화해주세요.

<ocr_text>
$ocrText
</ocr_text>

요구사항:
1. 페이지 번호 인식: "p. 09", "p.11", "p. 13" 형식 찾기
2. 섹션 구분: A, B, C, D 등 대문자 알파벳
3. 각 섹션의 정답만 추출 (문제번호 제외, 정답 텍스트만)

JSON 형식:
{
  "pages": [
    {
      "pageNumber": 9,
      "unitName": "Unit 01 문장을 이루는 요소",
      "sections": {
        "A": ["목적어", "동사", "수식어", "보어"],
        "B": ["wrote", "My teacher", "great", "dinner"],
        "C": ["주어, 동사, 보어", "주어, 동사, 목적어, 수식어"],
        "D": ["Tom and I go to the same school.", "She was writing in a diary."]
      }
    }
  ]
}

중요:
- sections 값은 **정답 문자열 배열** (객체 아님!)
- 같은 페이지 정보는 하나로 합치기
- JSON만 반환, 설명 금지
'''
                }
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        debugPrint('[Claude] ========== AI 응답 ==========');
        debugPrint('[Claude] 응답 길이: ${content.length}자');
        // ★ BIG_143: AI 응답 전체 로그 (줄바꿈 치환)
        final responseForLog = content.replaceAll('\n', '↵');
        debugPrint('[Claude] 응답 전체: $responseForLog');
        debugPrint('[Claude] ================================');

        // JSON 추출 및 파싱
        String jsonStr = content;
        if (content.contains('```json')) {
          jsonStr = content.split('```json')[1].split('```')[0].trim();
        } else if (content.contains('```')) {
          jsonStr = content.split('```')[1].split('```')[0].trim();
        } else if (content.contains('{')) {
          final start = content.indexOf('{');
          final end = content.lastIndexOf('}') + 1;
          if (end > start) {
            jsonStr = content.substring(start, end);
          }
        }

        final Map<String, dynamic> parsed = jsonDecode(jsonStr);

        // 결과 변환 - answer_parser_service.dart가 기대하는 형식으로!
        final List<Map<String, dynamic>> results = [];

        if (parsed['pages'] != null) {
          for (var page in parsed['pages']) {
            final pageNumber = page['pageNumber'] as int? ?? 0;
            final unitName = page['unitName'] as String? ?? '';
            final rawSections = page['sections'] as Map<String, dynamic>? ?? {};
            
            // sections를 Map<String, List<String>>으로 변환
            final sections = <String, List<String>>{};
            for (final entry in rawSections.entries) {
              final sectionName = entry.key;
              final sectionValue = entry.value;
              
              if (sectionValue is List) {
                // 정상: ["답1", "답2"] 형태
                sections[sectionName] = sectionValue.map((e) => e.toString()).toList();
              } else if (sectionValue is Map) {
                // 구형: {"answers": [...]} 형태 → 변환
                final answers = sectionValue['answers'] as List? ?? [];
                sections[sectionName] = answers.map((e) {
                  if (e is Map) {
                    return e['answer']?.toString() ?? '';
                  }
                  return e.toString();
                }).where((s) => s.isNotEmpty).toList();
              }
              
              debugPrint('[Claude] p.$pageNumber 섹션 $sectionName: ${sections[sectionName]?.length ?? 0}개 정답');
            }
            
            // content 생성 (UI 표시용)
            final contentBuffer = StringBuffer();
            if (unitName.isNotEmpty) {
              contentBuffer.writeln(unitName);
              contentBuffer.writeln();
            }
            for (final entry in sections.entries) {
              contentBuffer.writeln('${entry.key})');
              for (int i = 0; i < entry.value.length; i++) {
                contentBuffer.writeln('${i + 1}. ${entry.value[i]}');
              }
              contentBuffer.writeln();
            }
            
            results.add({
              'pageNumber': pageNumber,
              'sections': sections,
              'content': contentBuffer.toString().trim(),
            });
            
            debugPrint('[Claude] p.$pageNumber 추가: ${sections.keys.toList()} 섹션');
          }
        }

        debugPrint('[Claude] 총 ${results.length}개 페이지 파싱 완료');
        return results;
      } else {
        debugPrint('[Claude] 에러: ${response.statusCode}');
        debugPrint('[Claude] 응답: ${response.body}');
        return [];
      }

    } catch (e) {
      debugPrint('[Claude] parseOcrTextToAnswers 오류: $e');
      return [];
    }
  }

  /// 통합 분석: 페이지 번호 + 문제 위치 한 번에
  Future<Map<String, dynamic>?> analyzePageComplete(File imageFile) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Data = base64Encode(bytes);
    
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mediaType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };

    try {
      debugPrint('[ClaudeAPI] 통합 분석 시작 (페이지+문제)');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 2500,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Data,
                  },
                },
                {
                  'type': 'text',
                  'text': '''이 교재 페이지를 분석해주세요.

JSON만 반환:
{
  "pageNumber": 9,
  "unit": "Unit 01",
  "layout": {
    "type": "vertical" 또는 "horizontal" 또는 "single",
    "sections": ["A", "B", "C", "D"]
  },
  "sectionBounds": {
    "A": {"xStart": 0, "xEnd": 100, "yStart": 10, "yEnd": 35},
    "B": {"xStart": 0, "xEnd": 100, "yStart": 35, "yEnd": 55},
    "C": {"xStart": 0, "xEnd": 100, "yStart": 55, "yEnd": 75},
    "D": {"xStart": 0, "xEnd": 100, "yStart": 75, "yEnd": 95}
  }
}

layout.type 설명:
- "vertical": 섹션이 위아래로 배치 (A 아래 B 아래 C...)
- "horizontal": 섹션이 좌우로 배치 (A|B 또는 A|B / C|D)
- "single": 섹션 하나만 있음

sectionBounds: 각 섹션이 차지하는 대략적인 영역 (%)
- xStart, xEnd: 가로 범위 (0=왼쪽, 100=오른쪽)
- yStart, yEnd: 세로 범위 (0=상단, 100=하단)

주의: 개별 문제 위치는 필요 없습니다. 섹션 영역만!''',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        debugPrint('[ClaudeAPI] 통합 분석 응답: $content');

        try {
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
          return jsonDecode(jsonStr) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('[ClaudeAPI] JSON 파싱 실패: $e');
          return null;
        }
      } else {
        debugPrint('[ClaudeAPI] 에러: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[ClaudeAPI] 통합 분석 예외: $e');
      return null;
    }
  }

  /// Crop된 이미지가 해당 문제가 맞는지 검증
  Future<bool> verifyCroppedProblem(File croppedImage, String expectedNumber) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) return false;

    final bytes = await croppedImage.readAsBytes();
    final base64Data = base64Encode(bytes);

    final extension = croppedImage.path.split('.').last.toLowerCase();
    final mediaType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 100,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Data,
                  },
                },
                {
                  'type': 'text',
                  'text': '이 이미지에 $expectedNumber번 문제가 보이나요? "yes" 또는 "no"만 답하세요.',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = (data['content'][0]['text'] as String).toLowerCase();
        return content.contains('yes');
      }
      return false;
    } catch (e) {
      debugPrint('[ClaudeAPI] 검증 실패: $e');
      return false;
    }
  }

  /// PDF 여러 페이지 분석 (정답지용)
  /// 반환: List<int> 인식된 페이지 번호들
  Future<List<int>> analyzePdfPages(File pdfFile) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    final bytes = await pdfFile.readAsBytes();
    final base64Data = base64Encode(bytes);

    debugPrint('[ClaudeAPI] PDF 여러 페이지 분석 시작');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _modelHaiku,  // PDF 처리는 저렴한 Haiku 사용
          'max_tokens': 2048,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'document',
                  'source': {
                    'type': 'base64',
                    'media_type': 'application/pdf',
                    'data': base64Data,
                  },
                },
                {
                  'type': 'text',
                  'text': '''이 PDF의 각 페이지에서 페이지 번호를 찾아주세요.
교재 정답지입니다. 각 페이지 상단이나 하단에 있는 페이지 번호를 읽어주세요.

JSON만 반환:
{
  "pages": [1, 2, 3, 4, 5]
}

pages 배열에 인식된 페이지 번호들을 순서대로 넣어주세요.
페이지 번호를 못 찾으면 해당 페이지는 건너뛰세요.''',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        debugPrint('[ClaudeAPI] PDF 분석 응답: $content');

        try {
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

          final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
          final pages = (parsed['pages'] as List<dynamic>)
              .map((e) => e as int)
              .toList();
          debugPrint('[ClaudeAPI] 인식된 페이지: $pages');
          return pages;
        } catch (e) {
          debugPrint('[ClaudeAPI] JSON 파싱 실패: $e');
          return [];
        }
      } else {
        debugPrint('[ClaudeAPI] 에러: ${response.statusCode}');
        debugPrint('[ClaudeAPI] 응답: ${response.body}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ClaudeAPI] PDF 분석 예외: $e');
      rethrow;
    }
  }

  /// PDF 정답지 텍스트 추출 (인식 확인용)
  /// 반환: List<Map> - [{pageNumber: 9, content: "A 1 목적어 2 동사..."}, ...]
  Future<List<Map<String, dynamic>>> extractPdfText(File pdfFile) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    final bytes = await pdfFile.readAsBytes();
    final base64Data = base64Encode(bytes);

    debugPrint('[ClaudeAPI] PDF 텍스트 추출 시작');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _modelHaiku,  // PDF 처리는 저렴한 Haiku 사용
          'max_tokens': 16000,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'document',
                  'source': {
                    'type': 'base64',
                    'media_type': 'application/pdf',
                    'data': base64Data,
                  },
                },
                {
                  'type': 'text',
                  'text': '''이 PDF는 영어 교재 정답지입니다.

각 페이지에서 보이는 내용을 **그대로** 추출해주세요.
- 페이지 번호 (p. XX 형식으로 인쇄된 것)
- 섹션 (A, B, C, D, Practice, Unit 등)
- 문제 번호와 정답

JSON 형식:
{
  "pages": [
    {
      "pageNumber": 9,
      "content": "Unit 01 문장을 이루는 요소\\nPractice\\nA 1 목적어 2 동사 3 수식어 4 보어\\nB 1 wrote 2 My teacher 3 great 4 dinner\\nC 1 주어, 동사, 보어 2 주어, 동사, 목적어, 수식어..."
    },
    {
      "pageNumber": 11,
      "content": "Unit 02 1형식, 2형식\\nA 1 angry 2 an artist..."
    }
  ]
}

content에는 해당 페이지에서 보이는 텍스트를 줄바꿈(\\n)으로 구분해서 넣어주세요.
모든 페이지를 빠짐없이 추출해주세요.''',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        debugPrint('[ClaudeAPI] PDF 텍스트 추출 응답 길이: ${content.length}');

        try {
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

          final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
          final pages = (parsed['pages'] as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList();

          debugPrint('[ClaudeAPI] 텍스트 추출 완료: ${pages.length}페이지');
          return pages;
        } catch (e) {
          debugPrint('[ClaudeAPI] JSON 파싱 실패: $e');
          debugPrint('[ClaudeAPI] 원본 앞부분: ${content.substring(0, content.length > 500 ? 500 : content.length)}');
          return [];
        }
      } else {
        debugPrint('[ClaudeAPI] 에러: ${response.statusCode}');
        debugPrint('[ClaudeAPI] 응답: ${response.body}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ClaudeAPI] PDF 텍스트 추출 예외: $e');
      rethrow;
    }
  }

  /// 단일 PDF 청크 텍스트 추출 (분할 처리용)
  /// 작은 PDF(10페이지 이하)에 최적화
  Future<List<Map<String, dynamic>>> extractPdfChunkText(File pdfChunk) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    final bytes = await pdfChunk.readAsBytes();
    final base64Data = base64Encode(bytes);

    debugPrint('[ClaudeAPI] PDF 청크 텍스트 추출 시작');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _modelHaiku,  // PDF 처리는 저렴한 Haiku 사용
          'max_tokens': 4000,  // 청크당 4000 토큰으로 제한
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'document',
                  'source': {
                    'type': 'base64',
                    'media_type': 'application/pdf',
                    'data': base64Data,
                  },
                },
                {
                  'type': 'text',
                  'text': '''이 PDF는 영어 교재 정답지입니다.

★★★ 페이지 번호 찾는 방법 ★★★
1. "p. XX", "pp. XX", "p.XX" 형식 (예: p. 09, pp. 16-17)
2. "Practice p. XX", "Actual Test p. XX" 형식
3. 페이지 상단/하단에 인쇄된 숫자 (예: 하단 중앙에 "19")
4. Unit 제목 옆의 페이지 번호

위 순서대로 찾고, 없으면 다음 방법 시도.
페이지 번호는 반드시 교재에 인쇄된 번호를 사용하세요.

★★★ 정답 구조화 형식 ★★★
섹션(A, B, C, D...)별로 구분하고, 각 문제 번호마다 줄바꿈하세요.

예시 입력:
"Unit 01 A 1 목적어 2 주어 3 보어 B 1 동사 2 목적어"

예시 출력:
A)
1. 목적어
2. 주어
3. 보어

B)
1. 동사
2. 목적어

JSON 형식:
{
  "answers": [
    {
      "textbookPage": 9,
      "content": "Unit 01 문장을 이루는 요소\\n\\nA)\\n1. 목적어\\n2. 주어\\n3. 보어\\n4. 수식어\\n\\nB)\\n1. 동사\\n2. 목적어"
    }
  ]
}

규칙:
- textbookPage: 교재에 인쇄된 페이지 번호 (PDF 순서 아님!)
- content: 섹션별로 구분, 문제번호마다 줄바꿈
- 한 PDF 페이지에 여러 교재 페이지가 있으면 분리
- 영어 문장 정답은 그대로 유지''',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        debugPrint('[ClaudeAPI] 청크 응답 길이: ${content.length}');

        try {
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

          final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
          final answers = (parsed['answers'] as List<dynamic>)
              .map((e) => <String, dynamic>{
                'pageNumber': e['textbookPage'],
                'content': e['content'],
              })
              .toList();

          debugPrint('[ClaudeAPI] 청크에서 ${answers.length}개 교재 페이지 추출');
          return answers.cast<Map<String, dynamic>>();
        } catch (e) {
          debugPrint('[ClaudeAPI] 청크 JSON 파싱 실패: $e');
          return [];
        }
      } else if (response.statusCode == 429) {
        debugPrint('[ClaudeAPI] Rate limit 초과 (429)');
        throw Exception('RATE_LIMIT');
      } else {
        debugPrint('[ClaudeAPI] 에러: ${response.statusCode}');
        debugPrint('[ClaudeAPI] 400 응답 body: ${response.body}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ClaudeAPI] 청크 처리 예외: $e');
      rethrow;
    }
  }

  /// 목차 이미지에서 단원명 + 페이지 번호 추출
  Future<List<Map<String, dynamic>>> extractTableOfContents(File imageFile) async {
    try {
      final apiKey = await _getApiKey();
      if (apiKey == null) throw Exception('API key not found');

      // 이미지를 base64로 변환
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-haiku-20241022', // Haiku 모델 사용
          'max_tokens': 1000,
          'temperature': 0.2,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': 'image/jpeg',
                    'data': base64Image,
                  },
                },
                {
                  'type': 'text',
                  'text': '''이 교재 목차 이미지를 분석해주세요.

★★★ 중요 규칙 ★★★
1. 반드시 페이지 번호가 있는 항목만 추출하세요
2. Chapter/Unit 구분 없이 "페이지 번호가 있는 모든 항목"을 플랫하게 나열하세요
3. 중첩 구조(entries 안에 entries)는 절대 사용하지 마세요

JSON 형식으로만 반환:
{
  "entries": [
    {"unitName": "Unit 01 문장을 이루는 요소", "startPage": 8},
    {"unitName": "Unit 02 1형식, 2형식", "startPage": 10},
    {"unitName": "Unit 03 3형식, 4형식", "startPage": 12},
    {"unitName": "Grammar & Writing", "startPage": 16}
  ]
}

규칙:
- unitName: 목차에 보이는 이름 그대로 (Chapter, Unit, Lesson 등 포함)
- startPage: 반드시 숫자만! (페이지 번호가 없으면 해당 항목 제외)
- 페이지 범위(8-10)가 있으면 시작 페이지(8)만 추출
- 페이지 번호가 없는 항목은 절대 포함하지 마세요
- 중첩 구조 금지! entries 안에 또 entries 넣지 마세요''',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        debugPrint('[ClaudeAPI] 목차 응답: $content');

        try {
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

          final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
          final entries = (parsed['entries'] as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .where((e) => e['startPage'] != null && e['unitName'] != null)  // null 필터링
              .toList();

          debugPrint('[ClaudeAPI] 유효한 목차 항목: ${entries.length}개');
          return entries;
        } catch (e) {
          debugPrint('[ClaudeAPI] 목차 JSON 파싱 실패: $e');
          debugPrint('[ClaudeAPI] 원본 응답: $content');
          return [];
        }
      } else {
        debugPrint('[ClaudeAPI] 목차 API 에러: ${response.statusCode}');
        debugPrint('[ClaudeAPI] 응답: ${response.body}');
        throw Exception('목차 인식 API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ClaudeAPI] 목차 인식 예외: $e');
      rethrow;
    }
  }

  /// PDF 정답지 단계별 분석 (목차 교차 검증)
  ///
  /// Step 1: 열 구조 파악
  /// Step 2: 왼쪽 위부터 순서대로 읽기
  /// Step 3: 목차와 교차 검증
  /// Step 4: 페이지 번호 검증
  /// Step 5: 정답 구조화
  Future<List<Map<String, dynamic>>> extractPdfWithTocValidation(
    File pdfChunk,
    List<Map<String, dynamic>> tocEntries,  // 목차 데이터
  ) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    final bytes = await pdfChunk.readAsBytes();
    final base64Data = base64Encode(bytes);

    // 목차 정보를 프롬프트용 문자열로 변환
    final tocInfo = tocEntries.map((e) {
      final name = e['unitName'] ?? '';
      final start = e['startPage'] ?? 0;
      final end = e['endPage'] ?? start;
      return '$name: p.$start~$end';
    }).join('\n');

    debugPrint('[PDF분석] ========== 단계별 분석 시작 ==========');
    debugPrint('[PDF분석] 목차 정보:\n$tocInfo');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _modelHaiku,
          'max_tokens': 4000,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'document',
                  'source': {
                    'type': 'base64',
                    'media_type': 'application/pdf',
                    'data': base64Data,
                  },
                },
                {
                  'type': 'text',
                  'text': '''이 PDF는 영어 교재 정답지입니다.

★★★ 가장 중요 ★★★
이 PDF 청크에는 교재 페이지가 여러 개 있습니다!
반드시 보이는 모든 교재 페이지를 찾아서 pages 배열에 넣으세요.
1개만 찾지 말고, 2개, 3개, 4개... 보이는 만큼 모두 추출하세요!

★★★ 목차 정보 (교차 검증용) ★★★
$tocInfo

★★★ 분석 방법 ★★★

1. PDF 전체를 훑으면서 "p.숫자" 또는 "Unit XX" 패턴을 모두 찾기
2. 각 교재 페이지마다 정답 추출
3. 목차와 매칭 확인

페이지 번호 찾는 방법:
- "p. 09", "p.9", "pp. 16-17" 형식
- 페이지 하단 중앙의 숫자
- "Practice p.XX", "Actual Test p.XX" 형식

JSON 형식으로만 반환:
{
  "analysis": {
    "columnLayout": 1 또는 2,
    "totalPagesFound": 3
  },
  "pages": [
    {
      "unitName": "Unit 01 문장을 이루는 요소",
      "tocMatched": true,
      "pageNumber": 9,
      "pageValidation": "목차 범위 내",
      "sections": {
        "A": ["목적어", "동사", "수식어", "보어"],
        "B": ["wrote", "My teacher", "great", "dinner"]
      }
    },
    {
      "unitName": "Unit 02 1형식, 2형식",
      "tocMatched": true,
      "pageNumber": 11,
      "pageValidation": "목차 범위 내",
      "sections": {
        "A": ["angry", "an artist"],
        "B": ["looked", "became"]
      }
    }
  ]
}

★★★ 필수 규칙 ★★★
- pages 배열에 찾은 모든 페이지를 넣으세요! (1개만 넣지 마세요!)
- JSON만 반환! 다른 텍스트 금지!
- pageNumber는 교재에 인쇄된 번호 (PDF 순서 아님!)
- 섹션(A,B,C,D)별로 정답 분리''',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        debugPrint('[PDF분석] API 응답 길이: ${content.length}');

        try {
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

          final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

          // 분석 결과 로그
          final analysis = parsed['analysis'] as Map<String, dynamic>?;
          if (analysis != null) {
            debugPrint('[PDF분석] Step 1: ${analysis['columnLayout']}열 구조 감지');
            debugPrint('[PDF분석] Step 2: 읽기 순서 - ${analysis['readingOrder']}');
          }

          final pages = parsed['pages'] as List<dynamic>? ?? [];
          final results = <Map<String, dynamic>>[];
          
          // ★★★ 중복 페이지 방지용 Set ★★★
          final Set<int> processedPages = {};

          for (final page in pages) {
            final unitName = page['unitName'] ?? '';
            final tocMatched = page['tocMatched'] ?? false;
            final pageNum = page['pageNumber'] as int?;
            final validation = page['pageValidation'] ?? '';
            
            // ★★★ 중복 페이지 체크 ★★★
            if (pageNum != null && processedPages.contains(pageNum)) {
              debugPrint('[PDF분석] ⚠️ 중복 페이지 건너뜀: p.$pageNum (이미 처리됨)');
              continue;
            }
            
            // ★★★ sections 타입 안전 처리 ★★★
            Map<String, dynamic> sections = {};
            final rawSections = page['sections'];
            if (rawSections is Map<String, dynamic>) {
              sections = rawSections;
            } else if (rawSections is Map) {
              sections = Map<String, dynamic>.from(rawSections);
            } else {
              debugPrint('[PDF분석] ⚠️ sections 타입 오류: ${rawSections.runtimeType}');
            }

            debugPrint('[PDF분석] Step 3: $unitName ${tocMatched ? "목차 매칭 ✓" : "목차 매칭 ✗"}');
            debugPrint('[PDF분석] Step 4: p.$pageNum - $validation');

            // ★★★ 교차 검증: API + 클라이언트 둘 다 통과해야 진짜 통과 ★★★
            
            // 1. API 판단
            final bool apiSaysValid = tocMatched;
            
            // 2. 클라이언트 판단 (실제 페이지 범위 확인)
            bool clientSaysValid = false;
            String matchedTocName = '';
            if (pageNum != null) {
              for (final toc in tocEntries) {
                final start = toc['startPage'] as int? ?? 0;
                final end = toc['endPage'] as int? ?? start;
                if (pageNum >= start && pageNum <= end) {
                  clientSaysValid = true;
                  matchedTocName = toc['unitName'] as String? ?? '';
                  break;
                }
              }
            }
            
            debugPrint('[PDF분석] 검증: API=$apiSaysValid, 클라이언트=$clientSaysValid (p.$pageNum)');

            // 3. 클라이언트 우선 검증 (PDF는 텍스트가 깨끗해서 클라이언트 판단이 더 정확)
            // TODO: 사진 기반일 때는 API 판단도 고려 필요
            if (!clientSaysValid) {
              // ★★★ 실패 원인 상세 로그 ★★★
              debugPrint('[PDF분석] ========== 교차 검증 실패 상세 ==========');
              debugPrint('[PDF분석] ❌ 제외된 페이지: p.$pageNum ($unitName)');
              
              // API 실패 원인
              if (!apiSaysValid) {
                debugPrint('[PDF분석] ❌ API 실패 원인: tocMatched=false (API가 목차 매칭 실패 판정)');
              }
              
              // 클라이언트 실패 원인
              if (!clientSaysValid) {
                if (pageNum == null) {
                  debugPrint('[PDF분석] ❌ 클라이언트 실패 원인: pageNumber가 null');
                } else {
                  debugPrint('[PDF분석] ❌ 클라이언트 실패 원인: p.$pageNum이 어떤 목차 범위에도 포함 안 됨');
                  debugPrint('[PDF분석]    검사한 목차 범위들:');
                  for (final toc in tocEntries) {
                    final tocName = toc['unitName'] ?? '';
                    final start = toc['startPage'] as int? ?? 0;
                    final end = toc['endPage'] as int? ?? start;
                    final inRange = pageNum >= start && pageNum <= end;
                    debugPrint('[PDF분석]    - $tocName: p.$start~$end ${inRange ? "✓" : "✗"}');
                  }
                }
              }
              debugPrint('[PDF분석] ================================================');
              continue;  // 다음 페이지로 건너뜀
            }
            debugPrint('[PDF분석] ✓ 교차 검증 통과: p.$pageNum (목차: $matchedTocName)');
            
            // ★★★ 처리된 페이지로 등록 ★★★
            if (pageNum != null) {
              processedPages.add(pageNum);
            }

            // 섹션별 문제 수 로그 (안전 처리)
            final sectionInfo = sections.entries.map((e) {
              final val = e.value;
              if (val is List) {
                return '${e.key}섹션 ${val.length}문제';
              } else {
                return '${e.key}섹션 (타입오류)';
              }
            }).join(', ');
            debugPrint('[PDF분석] Step 5: $sectionInfo');

            // 정답 내용을 구조화된 문자열로 변환
            final contentBuffer = StringBuffer();
            contentBuffer.writeln(unitName);
            contentBuffer.writeln();

            for (final entry in sections.entries) {
              final sectionName = entry.key;
              final rawAnswers = entry.value;
              if (rawAnswers is! List) {
                debugPrint('[PDF분석] ⚠️ $sectionName 섹션 정답이 List가 아님: ${rawAnswers.runtimeType}');
                continue;
              }
              final answers = rawAnswers;
              contentBuffer.writeln('$sectionName)');
              for (int i = 0; i < answers.length; i++) {
                contentBuffer.writeln('${i + 1}. ${answers[i]}');
              }
              contentBuffer.writeln();
            }

            results.add({
              'pageNumber': pageNum,
              'content': contentBuffer.toString().trim(),
              'unitName': unitName,
              'tocMatched': tocMatched,
            });
          }

          debugPrint('[PDF분석] ========== 분석 완료: ${results.length}페이지 ==========');
          return results;

        } catch (e) {
          debugPrint('[PDF분석] JSON 파싱 실패: $e');
          debugPrint('[PDF분석] 원본 응답 앞 500자: ${content.substring(0, content.length > 500 ? 500 : content.length)}');
          return [];
        }
      } else if (response.statusCode == 429) {
        debugPrint('[PDF분석] Rate limit 초과 (429)');
        throw Exception('RATE_LIMIT');
      } else {
        debugPrint('[PDF분석] API 에러: ${response.statusCode}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[PDF분석] 예외: $e');
      rethrow;
    }
  }

  /// 이미지에서 열 개수 감지 (1, 2, 4)
  Future<int> detectColumnCount(File imageFile) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Data = base64Encode(bytes);

    final extension = imageFile.path.split('.').last.toLowerCase();
    final mediaType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/png',
    };

    try {
      debugPrint('[ClaudeAPI] 열 개수 감지 시작');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _modelHaiku,  // 빠른 처리를 위해 Haiku 사용
          'max_tokens': 50,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Data,
                  },
                },
                {
                  'type': 'text',
                  'text': '''이 이미지는 교재 정답지입니다.
정답이 몇 열로 배치되어 있나요?

- 1열: 정답이 세로로 한 줄
- 2열: 정답이 좌/우 2개 열 (2페이지 펼침)
- 4열: 정답이 4개 열 (2페이지 펼침 + 각 페이지 2열)

숫자만 답하세요: 1, 2, 또는 4''',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] as String;
        debugPrint('[ClaudeAPI] 열 감지 응답: $text');

        final match = RegExp(r'[124]').firstMatch(text);
        if (match != null) {
          final columns = int.parse(match.group(0)!);
          debugPrint('[ClaudeAPI] 감지된 열 개수: $columns');
          return columns;
        }
      }

      debugPrint('[ClaudeAPI] 열 감지 실패, 기본값 2 반환');
      return 2;  // 기본값
    } catch (e) {
      debugPrint('[ClaudeAPI] 열 감지 예외: $e');
      return 2;
    }
  }

  /// 병합된 1열 이미지에서 텍스트 추출 (학습 관리용 OCR)
  /// 
  /// 프롬프트 설계 원칙:
  /// - "정답지" 대신 "학습 자료", "교육 콘텐츠" 사용
  /// - 목적을 "학습 진도 추적"으로 명시
  /// - JSON 파싱 실패 시 다양한 폴백 전략
  Future<List<Map<String, dynamic>>> extractAnswersFromMergedImage(
    File mergedImage,
    List<Map<String, dynamic>> tocEntries,
  ) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    final bytes = await mergedImage.readAsBytes();
    final base64Data = base64Encode(bytes);

    // 목차 정보 문자열
    final tocInfo = tocEntries.map((e) {
      final name = e['unitName'] ?? '';
      final start = e['startPage'] ?? 0;
      final end = e['endPage'] ?? start;
      return '$name: p.$start~$end';
    }).join('\n');

    debugPrint('[OCR추출] 이미지 텍스트 추출 시작');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _modelHaiku,
          'max_tokens': 8000,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': 'image/png',
                    'data': base64Data,
                  },
                },
                {
                  'type': 'text',
                  'text': '''당신은 교육용 학습 관리 시스템(LMS)의 OCR 엔진입니다.
이 이미지는 학생 진도 추적을 위한 교육 자료입니다.

[시스템 목적]
- 학원에서 학생별 학습 진도를 추적하는 앱
- 선생님이 학생의 오답을 분석하여 복습 자료 생성
- 이미지의 텍스트를 DB에 저장하여 검색/분석에 활용

[추출 요청]
이미지에서 모든 텍스트를 OCR로 추출해주세요.
위에서 아래로 순서대로 읽어주세요.

[참고 - 단원 구성]
$tocInfo

[출력 형식 - 반드시 JSON만]
{"pages":[{"pageNumber":9,"unitName":"Unit 01","sections":{"A":["1번내용","2번내용"],"B":["1번내용"]}}]}

[중요 규칙]
1. 반드시 위 JSON 형식으로만 출력
2. 설명이나 코멘트 없이 JSON만
3. p.XX, pp.XX-YY 형식의 페이지 번호 찾기
4. A, B, C, D 등 섹션별로 구분
5. 각 항목의 번호와 내용 추출''',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        debugPrint('[OCR추출] 응답 길이: ${content.length}');
        debugPrint('[OCR추출] 응답 앞 200자: ${content.substring(0, content.length > 200 ? 200 : content.length)}');

        // ★★★ 강화된 JSON 파싱 로직 ★★★
        return _parseOcrResponse(content);

      } else {
        debugPrint('[OCR추출] API 에러: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('[OCR추출] 예외: $e');
      return [];
    }
  }

  /// OCR 응답 파싱 (다양한 형식 처리)
  List<Map<String, dynamic>> _parseOcrResponse(String content) {
    debugPrint('[OCR파싱] 파싱 시작');
    
    // 1. JSON 추출 시도
    String jsonStr = content;
    
    // 마크다운 코드블록 제거
    if (content.contains('```json')) {
      jsonStr = content.split('```json')[1].split('```')[0].trim();
    } else if (content.contains('```')) {
      jsonStr = content.split('```')[1].split('```')[0].trim();
    } else if (content.contains('{')) {
      final start = content.indexOf('{');
      final end = content.lastIndexOf('}') + 1;
      if (end > start) {
        jsonStr = content.substring(start, end);
      }
    }

    // 2. JSON 파싱 시도
    try {
      final parsed = jsonDecode(jsonStr);
      
      // Case A: {"pages": [...]} 형식
      if (parsed is Map<String, dynamic> && parsed.containsKey('pages')) {
        final pagesRaw = parsed['pages'];
        List<dynamic> pages;
        
        if (pagesRaw is List) {
          pages = pagesRaw;
        } else if (pagesRaw is Map) {
          // 단일 객체가 온 경우 배열로 변환
          pages = [pagesRaw];
        } else {
          debugPrint('[OCR파싱] pages가 예상치 못한 타입: ${pagesRaw.runtimeType}');
          return [];
        }
        
        return _convertPagesToResults(pages);
      }
      
      // Case B: [{...}, {...}] 배열 직접
      if (parsed is List) {
        return _convertPagesToResults(parsed);
      }
      
      // Case C: 단일 페이지 객체 {"pageNumber": ...}
      if (parsed is Map<String, dynamic> && parsed.containsKey('pageNumber')) {
        return _convertPagesToResults([parsed]);
      }
      
      debugPrint('[OCR파싱] 알 수 없는 JSON 구조');
      return [];
      
    } catch (e) {
      debugPrint('[OCR파싱] JSON 파싱 실패: $e');
      
      // 3. 텍스트 응답에서 정보 추출 시도 (최후의 수단)
      return _extractFromPlainText(content);
    }
  }

  /// 페이지 배열을 결과 형식으로 변환
  List<Map<String, dynamic>> _convertPagesToResults(List<dynamic> pages) {
    final results = <Map<String, dynamic>>[];
    
    for (final page in pages) {
      if (page is! Map) continue;
      
      // pageNumber 추출 (int 또는 String)
      int? pageNum;
      final rawPageNum = page['pageNumber'];
      if (rawPageNum is int) {
        pageNum = rawPageNum;
      } else if (rawPageNum is String) {
        pageNum = int.tryParse(rawPageNum.replaceAll(RegExp(r'[^0-9]'), ''));
      }
      
      final unitName = page['unitName']?.toString() ?? '';
      
      // sections 추출 (Map 또는 다른 형식)
      Map<String, dynamic> sections = {};
      final rawSections = page['sections'];
      if (rawSections is Map<String, dynamic>) {
        sections = rawSections;
      } else if (rawSections is Map) {
        sections = Map<String, dynamic>.from(rawSections);
      }

      // 정답 내용을 문자열로 변환
      final contentBuffer = StringBuffer();
      if (unitName.isNotEmpty) {
        contentBuffer.writeln(unitName);
        contentBuffer.writeln();
      }

      for (final entry in sections.entries) {
        contentBuffer.writeln('${entry.key})');
        
        // answers가 List인지 확인
        final rawAnswers = entry.value;
        if (rawAnswers is List) {
          for (int i = 0; i < rawAnswers.length; i++) {
            contentBuffer.writeln('${i + 1}. ${rawAnswers[i]}');
          }
        } else if (rawAnswers is String) {
          contentBuffer.writeln(rawAnswers);
        }
        contentBuffer.writeln();
      }

      if (pageNum != null) {
        results.add({
          'pageNumber': pageNum,
          'content': contentBuffer.toString().trim(),
          'unitName': unitName,
        });
        debugPrint('[OCR파싱] 페이지 추출: p.$pageNum - $unitName');
      }
    }
    
    debugPrint('[OCR파싱] 총 ${results.length}페이지 추출 완료');
    return results;
  }

  /// 일반 텍스트에서 페이지 정보 추출 (최후의 수단)
  List<Map<String, dynamic>> _extractFromPlainText(String text) {
    debugPrint('[OCR파싱] 텍스트에서 추출 시도');
    
    final results = <Map<String, dynamic>>[];
    
    // "p.숫자" 또는 "pp.숫자" 패턴 찾기
    final pagePattern = RegExp(r'p+\.\s*(\d+)', caseSensitive: false);
    final matches = pagePattern.allMatches(text);
    
    for (final match in matches) {
      final pageNum = int.tryParse(match.group(1) ?? '');
      if (pageNum != null) {
        // 해당 페이지 번호 주변 텍스트 추출 (대략적)
        final startIdx = match.start;
        final endIdx = (startIdx + 500).clamp(0, text.length);
        final excerpt = text.substring(startIdx, endIdx);
        
        results.add({
          'pageNumber': pageNum,
          'content': excerpt.trim(),
          'unitName': '',
        });
        debugPrint('[OCR파싱] 텍스트에서 발견: p.$pageNum');
      }
    }
    
    // 중복 제거
    final seen = <int>{};
    results.removeWhere((r) {
      final pageNum = r['pageNumber'] as int;
      if (seen.contains(pageNum)) return true;
      seen.add(pageNum);
      return false;
    });
    
    debugPrint('[OCR파싱] 텍스트에서 ${results.length}페이지 추출');
    return results;
  }
}
