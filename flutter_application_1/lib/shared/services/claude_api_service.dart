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
}
