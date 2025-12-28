import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ClaudeApiService {
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-20250514';
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
          'model': _model,
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
}
