# BIG_097: 교재 자동 분석 시스템 (Claude API 연동)

> 생성일: 2025-12-26
> 목표: PDF/이미지 업로드 → Claude API 분석 → DB 저장

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- Claude API: https://api.anthropic.com/v1/messages
- 모델: claude-sonnet-4-20250514

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
- 선생님 앱에서 교재 이미지 선택
- Claude API로 분석 요청
- 분석 결과 JSON으로 표시
- 검토 후 DB 저장

### 테스트 시나리오
```
1. 선생님 로그인 → 교재 탭 → [교재 분석] 버튼
2. 갤러리에서 교재 이미지 선택
3. "분석 중..." 로딩
4. 분석 결과 JSON 표시
5. [저장] 버튼 → DB 저장
6. 교재 목록에서 확인
```

---

## 스몰스텝

### 1. 패키지 추가

**파일:** pubspec.yaml

```yaml
dependencies:
  # 기존 패키지들...
  http: ^1.1.0
  flutter_secure_storage: ^9.0.0
  image_picker: ^1.0.4
```

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter pub get
```

### 2. API 키 설정 페이지

**새 파일:** lib/features/settings/api_key_settings_page.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeySettingsPage extends StatefulWidget {
  const ApiKeySettingsPage({super.key});

  @override
  State<ApiKeySettingsPage> createState() => _ApiKeySettingsPageState();
}

class _ApiKeySettingsPageState extends State<ApiKeySettingsPage> {
  final _storage = const FlutterSecureStorage();
  final _controller = TextEditingController();
  bool _isObscured = true;
  bool _hasKey = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await _storage.read(key: 'claude_api_key');
    setState(() {
      _hasKey = key != null && key.isNotEmpty;
      if (_hasKey) {
        _controller.text = '••••••••••••••••';
      }
    });
  }

  Future<void> _saveKey() async {
    final key = _controller.text.trim();
    if (key.isEmpty || key == '••••••••••••••••') return;
    
    await _storage.write(key: 'claude_api_key', value: key);
    setState(() => _hasKey = true);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API 키가 저장되었습니다'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _deleteKey() async {
    await _storage.delete(key: 'claude_api_key');
    setState(() {
      _hasKey = false;
      _controller.clear();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API 키가 삭제되었습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API 키 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Claude API 키',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              obscureText: _isObscured,
              decoration: InputDecoration(
                hintText: 'sk-ant-...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveKey,
                  child: const Text('저장'),
                ),
                const SizedBox(width: 8),
                if (_hasKey)
                  TextButton(
                    onPressed: _deleteKey,
                    child: const Text('삭제', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '* API 키는 안전하게 암호화되어 저장됩니다.\n'
              '* https://console.anthropic.com 에서 발급받을 수 있습니다.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 3. Claude API 서비스

**새 파일:** lib/services/claude_api_service.dart

```dart
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

  Future<Map<String, dynamic>?> analyzeTextbookImage(File imageFile) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    // 이미지를 base64로 변환
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    // 확장자로 미디어 타입 결정
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mediaType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final prompt = '''
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
          'max_tokens': 4096,
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
}
```

### 4. 교재 분석 페이지

**새 파일:** lib/features/textbook/textbook_analyzer_page.dart

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/claude_api_service.dart';

class TextbookAnalyzerPage extends StatefulWidget {
  const TextbookAnalyzerPage({super.key});

  @override
  State<TextbookAnalyzerPage> createState() => _TextbookAnalyzerPageState();
}

class _TextbookAnalyzerPageState extends State<TextbookAnalyzerPage> {
  final _claudeService = ClaudeApiService();
  final _picker = ImagePicker();
  
  File? _selectedImage;
  Map<String, dynamic>? _analysisResult;
  bool _isLoading = false;
  String? _error;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _analysisResult = null;
        _error = null;
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _claudeService.analyzeTextbookImage(_selectedImage!);
      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToDatabase() async {
    if (_analysisResult == null) return;

    // TODO: Amplify API로 DB 저장 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('DB 저장 기능은 다음 단계에서 구현됩니다'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('교재 분석'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings/api-key'),
            tooltip: 'API 키 설정',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이미지 선택 영역
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('교재 이미지를 선택하세요', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 분석 버튼
            ElevatedButton.icon(
              onPressed: _selectedImage != null && !_isLoading ? _analyzeImage : null,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isLoading ? '분석 중...' : '이미지 분석'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            // 에러 표시
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),
            ],
            
            // 분석 결과
            if (_analysisResult != null) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '분석 결과',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveToDatabase,
                    icon: const Icon(Icons.save),
                    label: const Text('DB 저장'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(_analysisResult),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 5. 라우터 등록

**파일:** lib/app/app_router.dart

**추가할 import:**
```dart
import '../features/textbook/textbook_analyzer_page.dart';
import '../features/settings/api_key_settings_page.dart';
```

**추가할 라우트:**
```dart
GoRoute(
  path: '/textbook-analyzer',
  builder: (context, state) => const TextbookAnalyzerPage(),
),
GoRoute(
  path: '/settings/api-key',
  builder: (context, state) => const ApiKeySettingsPage(),
),
```

### 6. 선생님 Shell에 버튼 추가

**파일:** lib/features/teacher/teacher_shell.dart (또는 해당 파일)

교재 목록 페이지에 "교재 분석" 버튼 추가:
```dart
FloatingActionButton(
  onPressed: () => context.push('/textbook-analyzer'),
  child: const Icon(Icons.document_scanner),
  tooltip: '교재 분석',
),
```

---

## 7. flutter analyze

```bash
flutter analyze
```

에러 0개 확인

---

## 8. 테스트

1. 앱 실행
2. 설정 → API 키 입력
3. 교재 분석 페이지 → 이미지 선택
4. 분석 버튼 클릭
5. 결과 JSON 확인

---

## 완료 조건

1. API 키 저장/불러오기 동작
2. 이미지 선택 가능
3. Claude API 호출 성공
4. 분석 결과 JSON 표시
5. flutter analyze 에러 0개

---

## 보고서

ai_bridge/report/big_097_report.md
