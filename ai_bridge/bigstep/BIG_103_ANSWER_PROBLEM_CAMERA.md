# BIG_103: 정답지/문제지 촬영 기능 구현

> 생성일: 2024-12-28
> 목표: 책 상세에서 정답지 등록(카메라+PDF) / 문제 촬영 버튼 동작

---

## ⚠️ 작성 전 체크리스트

### 기본 확인
- [x] 로컬 코드 확인함 (BookDetailPage, BookCameraPage, VolumeSelector, ClaudeApiService)
- [x] 수정할 파일/줄 번호 특정함
- [x] 삭제할 코드 vs 추가할 코드 구체적으로 작성함
- [x] 새 함수/로직에 safePrint 로그 추가 지시함

### 테스트 환경
- [ ] 빌드 필요: ✅ (UI 확인 필요)
- [ ] 듀얼 빌드: ❌ (1개 계정으로 충분)

### 플로우 확인
- [x] 진입 경로: BookDetailPage → 버튼 클릭 → 촬영/PDF 페이지
- [x] 영향 범위: my_books 폴더 + app_router.dart + claude_api_service.dart

---

## ⚠️ 필수: Opus는 직접 작업 금지!

**Sonnet에게 파일 1개씩 나눠서 시킬 것!**

```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

---

## ⚠️ 컨텍스트 관리 (필수!)

```
1. 스몰스텝 2~3개 완료할 때마다 로그 저장
2. 로그 저장 후 /compact 실행 → 확인 묻지 말고 바로 다음 작업 진행
3. 파일 생성은 Sonnet한테 1개씩 시키기 (한 번에 여러 파일 X)
```

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- Flutter 앱: flutter_application_1/
- 폰 디바이스: RFCY40MNBLL

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
- "정답지 등록" → 카메라 촬영 OR PDF 업로드 선택 가능
- PDF 업로드 시 여러 페이지 한번에 분석 → 등록
- "문제 촬영" → Volume 선택 → 촬영 → 기록
- 촬영/업로드 후 페이지맵에 등록된 페이지 표시

### CP 테스트 시나리오

**사전 조건:**
- 책이 최소 1개 등록되어 있어야 함
- 2권 구성 책이면 Volume 선택 UI 테스트 가능

**테스트 1: 정답지 - 카메라 촬영**
```
1. 내 책 목록 → 책 선택 → 상세 페이지
2. "정답지 등록" 클릭
3. Volume 선택 (2권 이상이면)
4. "카메라 촬영" 선택
5. 정답지 페이지 촬영 → 페이지 번호 인식
6. "확인" → "X페이지 등록 완료" 스낵바
7. 상세 페이지 → 페이지맵 녹색 표시 확인
```

**테스트 2: 정답지 - PDF 업로드**
```
1. 상세 페이지 → "정답지 등록" 클릭
2. Volume 선택
3. "PDF 업로드" 선택
4. PDF 파일 선택 (여러 페이지)
5. 분석 진행 표시 → 각 페이지 번호 인식
6. "X페이지 등록 완료" 스낵바
7. 페이지맵 확인
```

**테스트 3: 문제 촬영**
```
1. 상세 페이지 → "문제 촬영" 클릭
2. Volume 선택
3. 촬영 → 페이지 번호 인식
4. "Xp 촬영 완료" 스낵바
```

**테스트 4: Volume 1개일 때**
```
1. 1권 구성 책 선택
2. "정답지 등록" 클릭 → Volume 선택 UI 간소화됨
3. 바로 촬영/업로드 선택 가능
```

**실패 케이스:**
```
- 촬영 취소 → 아무것도 저장 안 됨
- PDF 분석 실패 → "분석 실패" 스낵바
- 페이지 인식 실패 → "페이지 번호를 인식하지 못했습니다" 스낵바
```

---

## 📁 수정할 파일 목록

| 순서 | 파일 | 작업 |
|:---:|------|------|
| 1 | `lib/shared/services/claude_api_service.dart` | PDF 여러 페이지 분석 메서드 추가 |
| 2 | `lib/features/my_books/pages/answer_camera_page.dart` | **신규** - 정답지 촬영+PDF |
| 3 | `lib/features/my_books/pages/problem_camera_page.dart` | **신규** - 문제 촬영 |
| 4 | `lib/features/my_books/pages/book_detail_page.dart` | 버튼 동작 수정 |
| 5 | `lib/app/app_router.dart` | 라우트 추가 |

---

## 스몰스텝

### 1. ClaudeApiService에 PDF 여러 페이지 분석 추가

- [ ] 파일: `lib/shared/services/claude_api_service.dart`
- [ ] 위치: 파일 끝부분에 새 메서드 추가
- [ ] Sonnet 지시:
```
lib/shared/services/claude_api_service.dart 파일 끝에 아래 메서드 추가해줘.

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
```

- [ ] 완료 후 로그 저장: `ai_bridge/logs/big_103_step_01.log`

---

### 2. 정답지 촬영 페이지 생성 (카메라 + PDF)

- [ ] 파일: `lib/features/my_books/pages/answer_camera_page.dart` (신규)
- [ ] Sonnet 지시:
```
lib/features/my_books/pages/answer_camera_page.dart 파일 새로 만들어줘.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../models/local_book.dart';
import '../data/local_book_repository.dart';
import '../widgets/volume_selector.dart';
import '../../textbook/book_camera_page.dart';
import '../../../shared/services/claude_api_service.dart';

/// 정답지 촬영/업로드 페이지
/// 1. Volume 선택
/// 2. 카메라 촬영 OR PDF 업로드 선택
/// 3. 분석 → 페이지 번호 인식
/// 4. 저장
class AnswerCameraPage extends StatefulWidget {
  final String bookId;

  const AnswerCameraPage({super.key, required this.bookId});

  @override
  State<AnswerCameraPage> createState() => _AnswerCameraPageState();
}

class _AnswerCameraPageState extends State<AnswerCameraPage> {
  final _repository = LocalBookRepository();
  final _claudeService = ClaudeApiService();
  LocalBook? _book;
  int _selectedVolumeIndex = 0;
  bool _isLoading = true;
  bool _isAnalyzing = false;
  String _analysisStatus = '';

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    safePrint('[AnswerCamera] 진입: ${widget.bookId}');
    try {
      final book = await _repository.getBook(widget.bookId);
      setState(() {
        _book = book;
        _isLoading = false;
      });
      safePrint('[AnswerCamera] 책 로드: ${book?.title}, volumes: ${book?.volumes.length}');
    } catch (e) {
      safePrint('[AnswerCamera] 책 로드 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startCamera() async {
    safePrint('[AnswerCamera] 카메라 촬영 시작 - Volume: ${_book!.volumes[_selectedVolumeIndex].name}');
    
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const BookCameraPage()),
    );

    if (result != null && mounted) {
      safePrint('[AnswerCamera] 촬영 결과: pages=${result['pages']}');
      await _savePages(result['pages'] as List<int>? ?? []);
    }
  }

  Future<void> _pickPdf() async {
    safePrint('[AnswerCamera] PDF 선택 시작');
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        safePrint('[AnswerCamera] PDF 선택됨: ${file.path}');
        
        setState(() {
          _isAnalyzing = true;
          _analysisStatus = 'PDF 분석 중...';
        });

        final pages = await _claudeService.analyzePdfPages(file);
        
        setState(() => _isAnalyzing = false);
        
        if (pages.isNotEmpty) {
          safePrint('[AnswerCamera] PDF 분석 완료: $pages');
          await _savePages(pages);
        } else {
          safePrint('[AnswerCamera] PDF에서 페이지 번호 인식 실패');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('페이지 번호를 인식하지 못했습니다')),
            );
          }
        }
      }
    } catch (e) {
      safePrint('[AnswerCamera] PDF 처리 실패: $e');
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 처리 실패: $e')),
        );
      }
    }
  }

  Future<void> _savePages(List<int> pages) async {
    if (pages.isEmpty) {
      safePrint('[AnswerCamera] 저장할 페이지 없음');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('페이지 번호를 인식하지 못했습니다')),
      );
      return;
    }

    try {
      safePrint('[AnswerCamera] 페이지 저장: $pages');
      await _repository.updateRegisteredPages(widget.bookId, pages);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pages.length}페이지 등록 완료')),
        );
        context.pop(true);
      }
    } catch (e) {
      safePrint('[AnswerCamera] 저장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정답지 등록'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _book == null
              ? const Center(child: Text('책 정보를 불러올 수 없습니다'))
              : _isAnalyzing
                  ? _buildAnalyzingView()
                  : _buildContent(),
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_analysisStatus),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final book = _book!;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 책 제목
          Text(
            book.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            book.publisher,
            style: TextStyle(color: Colors.grey[600]),
          ),
          
          const SizedBox(height: 24),
          
          // Volume 선택
          const Text(
            '어느 부분의 정답지인가요?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          VolumeSelector(
            volumes: book.volumes,
            initialIndex: _selectedVolumeIndex,
            onVolumeChanged: (index) {
              setState(() => _selectedVolumeIndex = index);
              safePrint('[AnswerCamera] Volume 선택: ${book.volumes[index].name}');
            },
          ),
          
          const SizedBox(height: 24),
          
          // 안내
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"${book.volumes[_selectedVolumeIndex].name}" 정답지를 등록합니다',
                    style: const TextStyle(color: Colors.teal),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // 카메라 촬영 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startCamera,
              icon: const Icon(Icons.camera_alt, size: 24),
              label: const Text('카메라 촬영', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // PDF 업로드 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickPdf,
              icon: const Icon(Icons.picture_as_pdf, size: 24),
              label: const Text('PDF 업로드', style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
```

- [ ] 완료 후 로그 저장: `ai_bridge/logs/big_103_step_02.log`
- [ ] `/compact` 실행

---

### 3. 문제 촬영 페이지 생성

- [ ] 파일: `lib/features/my_books/pages/problem_camera_page.dart` (신규)
- [ ] Sonnet 지시:
```
lib/features/my_books/pages/problem_camera_page.dart 파일 새로 만들어줘.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:go_router/go_router.dart';
import '../models/local_book.dart';
import '../models/book_volume.dart';
import '../data/local_book_repository.dart';
import '../widgets/volume_selector.dart';
import '../../textbook/book_camera_page.dart';
import '../../../core/services/answer_validation_service.dart';

/// 문제 촬영 페이지
class ProblemCameraPage extends StatefulWidget {
  final String bookId;

  const ProblemCameraPage({super.key, required this.bookId});

  @override
  State<ProblemCameraPage> createState() => _ProblemCameraPageState();
}

class _ProblemCameraPageState extends State<ProblemCameraPage> {
  final _repository = LocalBookRepository();
  LocalBook? _book;
  int _selectedVolumeIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    safePrint('[ProblemCamera] 진입: ${widget.bookId}');
    try {
      final book = await _repository.getBook(widget.bookId);
      setState(() {
        _book = book;
        _isLoading = false;
      });
      safePrint('[ProblemCamera] 책 로드: ${book?.title}, volumes: ${book?.volumes.length}');
    } catch (e) {
      safePrint('[ProblemCamera] 책 로드 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startCamera() async {
    final volume = _book!.volumes[_selectedVolumeIndex];
    safePrint('[ProblemCamera] 촬영 시작 - Volume: ${volume.name}');
    
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const BookCameraPage()),
    );

    if (result != null && mounted) {
      safePrint('[ProblemCamera] 촬영 결과: pages=${result['pages']}');
      await _processResult(result, volume);
    }
  }

  Future<void> _processResult(Map<String, dynamic> result, BookVolume volume) async {
    final pages = result['pages'] as List<int>? ?? [];
    if (pages.isEmpty) {
      safePrint('[ProblemCamera] 인식된 페이지 없음');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('페이지 번호를 인식하지 못했습니다')),
      );
      return;
    }

    // 정답지 범위 검증
    for (final page in pages) {
      final validation = AnswerValidationService.validateAnswer(
        volume: volume,
        problemPage: page,
        problemNumber: '1',
      );
      
      if (!validation.isValid) {
        safePrint('[ProblemCamera] 검증 실패: ${validation.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.message ?? '검증 실패'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // TODO: 향후 틀린문제 기록 DB에 저장
    safePrint('[ProblemCamera] 문제 촬영 완료: pages=$pages, volume=${volume.name}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${pages.join(", ")}p 촬영 완료')),
      );
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('문제 촬영'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _book == null
              ? const Center(child: Text('책 정보를 불러올 수 없습니다'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final book = _book!;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            book.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            book.publisher,
            style: TextStyle(color: Colors.grey[600]),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            '어느 부분을 촬영하나요?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          VolumeSelector(
            volumes: book.volumes,
            initialIndex: _selectedVolumeIndex,
            onVolumeChanged: (index) {
              setState(() => _selectedVolumeIndex = index);
              safePrint('[ProblemCamera] Volume 선택: ${book.volumes[index].name}');
            },
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"${book.volumes[_selectedVolumeIndex].name}" 문제를 촬영합니다',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startCamera,
              icon: const Icon(Icons.camera_alt, size: 28),
              label: const Text('촬영 시작', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
```

- [ ] 완료 후 로그 저장: `ai_bridge/logs/big_103_step_03.log`

---

### 4. BookDetailPage 버튼 수정

- [ ] 파일: `lib/features/my_books/pages/book_detail_page.dart`
- [ ] 위치: 약 165줄 `_buildActionButtons()` 메서드
- [ ] Sonnet 지시:
```
lib/features/my_books/pages/book_detail_page.dart에서
_buildActionButtons() 메서드를 찾아서 아래 코드로 교체해줘.

Widget _buildActionButtons() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        // 정답지 등록
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              safePrint('[BookDetail] 버튼 클릭: 정답지 등록');
              final result = await context.push<bool>('/my-books/${widget.bookId}/answer-camera');
              if (result == true) {
                _loadBook(); // 페이지맵 새로고침
              }
            },
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('정답지 등록'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 문제 촬영
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              safePrint('[BookDetail] 버튼 클릭: 문제 촬영');
              final result = await context.push<bool>('/my-books/${widget.bookId}/problem-camera');
              if (result == true) {
                _loadBook(); // 새로고침
              }
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('문제 촬영'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    ),
  );
}
```

- [ ] 완료 후 로그 저장: `ai_bridge/logs/big_103_step_04.log`
- [ ] `/compact` 실행

---

### 5. 라우터에 경로 추가

- [ ] 파일: `lib/app/app_router.dart`
- [ ] Sonnet 지시:
```
lib/app/app_router.dart 파일 수정해줘.

1. 파일 상단 import에 추가:
import '../features/my_books/pages/answer_camera_page.dart';
import '../features/my_books/pages/problem_camera_page.dart';

2. 기존 '/my-books/:bookId' 라우트 바로 뒤에 추가 (약 145줄 근처):
        // 정답지 촬영 페이지
        GoRoute(
          path: '/my-books/:bookId/answer-camera',
          builder: (context, state) {
            final bookId = state.pathParameters['bookId'] ?? '';
            return AnswerCameraPage(bookId: bookId);
          },
        ),
        // 문제 촬영 페이지
        GoRoute(
          path: '/my-books/:bookId/problem-camera',
          builder: (context, state) {
            final bookId = state.pathParameters['bookId'] ?? '';
            return ProblemCameraPage(bookId: bookId);
          },
        ),
```

- [ ] 완료 후 로그 저장: `ai_bridge/logs/big_103_step_05.log`

---

### 6. flutter analyze

- [ ] flutter analyze 실행
- [ ] 에러/경고 0개 확인
- [ ] 완료 후 로그 저장: `ai_bridge/logs/big_103_step_06.log`
- [ ] `/compact` 실행

---

### 7. 테스트

- [ ] flutter run -d RFCY40MNBLL
- [ ] 위 테스트 시나리오대로 테스트
- [ ] CP 명령 대기

---

## 완료 조건

1. ClaudeApiService에 analyzePdfPages 추가됨
2. answer_camera_page.dart 생성됨 (카메라 + PDF)
3. problem_camera_page.dart 생성됨
4. BookDetailPage 버튼 동작함
5. 라우터에 경로 추가됨
6. flutter analyze 에러 0개
7. 테스트 통과
8. CP가 "테스트 종료" 입력
9. 보고서 작성 완료 (ai_bridge/report/big_103_report.md)
