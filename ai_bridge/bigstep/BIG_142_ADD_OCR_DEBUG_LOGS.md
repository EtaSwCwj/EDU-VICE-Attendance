# BIG_142: OCR 텍스트 원본 + PDF 이미지 상세 로그 추가

> 생성일: 2026-01-04
> 목표: PDF 변환 이미지와 갤러리 이미지의 OCR 차이 원인 분석을 위한 상세 로그 추가

---

## ⚠️ 필수: 템플릿 먼저 읽기!

```
ai_bridge/templates/BIGSTEP_TEMPLATE.md 읽고 시작할 것!
```

---

## ⚠️ 작성 전 체크리스트

### 기본 확인
- [x] 로컬 코드 확인했나? → 선임이 view 도구로 확인 완료
- [x] 수정할 파일/줄 번호 특정했나? → 아래 명시됨
- [x] 삭제할 코드 vs 추가할 코드 구체적으로 작성했나? → O
- [x] 새 로그 추가 지시했나? → O (이번 작업의 핵심)

### 테스트 환경
- [ ] 테스트 계정 리셋 필요한가? → 불필요
- [ ] 빌드 필요한가? → 필요 (폰 빌드)

---

## 배경

### 현재 문제
같은 정답지 내용인데:
- **갤러리 이미지(316.png)**: p.9, 11, 13, 15 정상 인식 ✅
- **PDF 변환 이미지**: p.16, 17 오인식 ❌

### 로그 부족 문제
현재 로그에서 **OCR 텍스트 원본**이 안 찍혀서 원인 분석 불가:
- `[AnswerParser] OCR 텍스트 길이: 1824` ← 길이만 나옴, 내용 없음!
- `[Claude] OCR 텍스트 길이: 1824` ← 마찬가지

### 분석 필요 사항
1. **OCR 텍스트에서 "p.11"이 "p.16"으로 잘못 읽힌 건가?** → OCR 원본 확인 필요
2. **AI가 "p.11"을 보고 "p.16"으로 파싱한 건가?** → AI 응답 확인 필요
3. **PDF 이미지 품질 문제인가?** → 이미지 해상도 확인 필요

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 수정 파일:
  1. `lib/shared/services/answer_parser_service.dart`
  2. `lib/shared/services/claude_api_service.dart`
  3. `lib/features/my_books/pages/answer_camera_page.dart`

---

## 🎯 기대 결과

### 추가될 로그 예시
```
[AnswerParser] ========== OCR 텍스트 원본 ==========
[AnswerParser] OCR 앞 500자:
Unit 01 문장을 이루는 요소
Practice p. 09
A 1 목적어 2 동사 3 수식어 4 보어
...
[AnswerParser] OCR 뒤 500자:
...
D 1 Tom and I go to the same school.
[AnswerParser] ========================================
[AnswerParser] OCR 텍스트 총 길이: 1824자

[Claude] ========== AI 파싱 입력 ==========
[Claude] 입력 OCR 텍스트 앞 300자: ...
[Claude] ========== AI 파싱 출력 ==========
[Claude] 응답 전체:
{"pages":[{"pageNumber":9,...}]}
```

### 테스트 시나리오
```
1. 앱 실행 → "전체 PDF 업로드" → PDF 선택
2. 로그에서 확인:
   - [AnswerParser] OCR 앞 500자 → "p. 09" 또는 "p. 11" 있는지?
   - [Claude] 응답 전체 → pageNumber가 9인지 16인지?
3. 같은 PDF의 갤러리 이미지로 테스트 → 비교
```

---

## 스몰스텝

### 1. answer_parser_service.dart - OCR 텍스트 원본 로그 추가

- [ ] 파일: `lib/shared/services/answer_parser_service.dart`
- [ ] 위치: `extractAnswers()` 메서드 내, `fullText` 생성 후 (약 30줄)

**기존 코드 (이 부분 찾기):**
```dart
    // 3. 전체 텍스트 합치기
    final fullText = sortedBlocks.map((b) => b.text).join('\n');
    debugPrint('[AnswerParser] OCR 텍스트 길이: ${fullText.length}');
```

**새 코드로 교체:**
```dart
    // 3. 전체 텍스트 합치기
    final fullText = sortedBlocks.map((b) => b.text).join('\n');
    
    // ★ BIG_142: OCR 텍스트 원본 상세 로그
    debugPrint('[AnswerParser] ========== OCR 텍스트 원본 ==========');
    debugPrint('[AnswerParser] OCR 총 길이: ${fullText.length}자');
    if (fullText.length > 1000) {
      debugPrint('[AnswerParser] OCR 앞 500자:');
      debugPrint(fullText.substring(0, 500));
      debugPrint('[AnswerParser] ...(중략)...');
      debugPrint('[AnswerParser] OCR 뒤 500자:');
      debugPrint(fullText.substring(fullText.length - 500));
    } else {
      debugPrint('[AnswerParser] OCR 전체:');
      debugPrint(fullText);
    }
    debugPrint('[AnswerParser] ========================================');
```

### 2. claude_api_service.dart - AI 입출력 상세 로그 추가

- [ ] 파일: `lib/shared/services/claude_api_service.dart`
- [ ] 위치: `parseOcrTextToAnswers()` 메서드 내

**기존 코드 (이 부분 찾기):**
```dart
  Future<List<Map<String, dynamic>>> parseOcrTextToAnswers(String ocrText) async {
    debugPrint('[Claude] parseOcrTextToAnswers 시작');
    debugPrint('[Claude] OCR 텍스트 길이: ${ocrText.length}');
```

**새 코드로 교체:**
```dart
  Future<List<Map<String, dynamic>>> parseOcrTextToAnswers(String ocrText) async {
    debugPrint('[Claude] ========== parseOcrTextToAnswers 시작 ==========');
    debugPrint('[Claude] OCR 텍스트 길이: ${ocrText.length}자');
    
    // ★ BIG_142: AI 입력 텍스트 상세 로그
    debugPrint('[Claude] AI 입력 OCR 앞 300자:');
    debugPrint(ocrText.substring(0, ocrText.length > 300 ? 300 : ocrText.length));
    if (ocrText.length > 300) {
      debugPrint('[Claude] ...(중략)...');
    }
```

**그리고 응답 부분도 수정 (약 70줄 아래):**

**기존 코드 (이 부분 찾기):**
```dart
        debugPrint('[Claude] 응답 길이: ${content.length}');
        debugPrint('[Claude] 응답 앞 300자: ${content.substring(0, content.length > 300 ? 300 : content.length)}');
```

**새 코드로 교체:**
```dart
        debugPrint('[Claude] ========== AI 응답 ==========');
        debugPrint('[Claude] 응답 길이: ${content.length}자');
        // ★ BIG_142: AI 응답 전체 로그 (JSON이므로 전체 필요)
        debugPrint('[Claude] 응답 전체:');
        debugPrint(content);
        debugPrint('[Claude] ================================');
```

### 3. answer_camera_page.dart - PDF 이미지 상세 정보 로그 추가

- [ ] 파일: `lib/features/my_books/pages/answer_camera_page.dart`
- [ ] 위치: `_pickPdfForAll()` 메서드, 이미지 정보 로그 부분 (약 340줄)

**기존 코드 (이 부분 찾기):**
```dart
        // 각 이미지 정보 로그
        for (int i = 0; i < pageImages.length; i++) {
          final imgFile = pageImages[i];
          final imgSize = await imgFile.length();
          safePrint('[PDF처리] - 이미지 ${i + 1}: ${imgFile.path}, ${(imgSize / 1024).toStringAsFixed(1)} KB');
        }
```

**새 코드로 교체:**
```dart
        // ★ BIG_142: 각 이미지 상세 정보 로그
        for (int i = 0; i < pageImages.length; i++) {
          final imgFile = pageImages[i];
          final imgSize = await imgFile.length();
          
          // 이미지 해상도 확인
          final imgBytes = await imgFile.readAsBytes();
          final decodedImage = await decodeImageFromList(imgBytes);
          
          safePrint('[PDF처리] - 이미지 ${i + 1}:');
          safePrint('[PDF처리]   경로: ${imgFile.path}');
          safePrint('[PDF처리]   크기: ${(imgSize / 1024).toStringAsFixed(1)} KB');
          safePrint('[PDF처리]   해상도: ${decodedImage.width} x ${decodedImage.height}');
        }
```

**그리고 파일 상단에 import 추가 필요:**
```dart
import 'dart:ui' as ui;
```

**decodeImageFromList 사용을 위해 함수 추가 (클래스 내부에):**
```dart
  /// 이미지 바이트에서 해상도 추출
  Future<ui.Image> decodeImageFromList(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
```

### 4. flutter analyze

- [ ] `flutter analyze` 실행
- [ ] 에러 0개 확인

### 5. 테스트

- [ ] `flutter run -d RFCY40MNBLL`
- [ ] "전체 PDF 업로드" → Grammar Effect PDF 선택
- [ ] 로그 확인:
  ```bash
  adb logcat -d | grep -E "\[AnswerParser\]|\[Claude\]|\[PDF처리\]" | tail -300
  ```
- [ ] 로그 저장: `ai_bridge/logs/big_142_test.log`

---

## 로그 분석 포인트

테스트 후 다음을 확인:

### 1. OCR 단계 (ML Kit)
```
[AnswerParser] OCR 앞 500자:
```
여기서 **"p. 09"** 또는 **"p.9"** 또는 **"p. 11"** 이 보이는가?
- 보이면 → OCR 정상, AI 파싱 문제
- 안 보이면 → OCR 문제 (PDF 이미지 품질)

### 2. AI 파싱 단계 (Claude)
```
[Claude] 응답 전체:
{"pages":[{"pageNumber":???
```
여기서 **pageNumber**가 9인지 16인지?
- OCR에 "p.9"가 있는데 AI가 16을 반환하면 → AI 프롬프트 문제
- OCR에 "p.9"가 없으면 → OCR 문제

### 3. 이미지 해상도 비교
```
[PDF처리]   해상도: ??? x ???
```
갤러리 이미지(316.png)와 PDF 변환 이미지의 해상도 차이 확인

---

## 완료 조건

1. 3개 파일 수정 완료
2. flutter analyze 에러 0개
3. 테스트 실행 → 로그에서 OCR 텍스트 원본 확인 가능
4. 로그 저장 완료
5. 보고서 작성: `ai_bridge/report/big_142_report.md`
   - OCR 텍스트에 페이지 번호가 어떻게 나오는지 기록
   - AI 응답에서 pageNumber가 어떻게 파싱되는지 기록

---

## ⚠️ 컨텍스트 관리

- 스몰스텝 2개 완료 시마다 `/compact`
- 로그는 `tail -300`으로 제한
- 파일 전체 읽기 금지, 필요한 부분만

---

## 보고서 작성

### 필수 포함 사항
```markdown
# BIG_142 보고서

## OCR 텍스트 분석
- OCR 앞 500자에서 페이지 번호 패턴: [실제 내용]
- 발견된 페이지 번호: p.??, p.??, ...

## AI 파싱 결과
- 입력된 OCR 텍스트의 페이지 번호: [OCR에서 읽힌 것]
- AI가 반환한 pageNumber: [AI 응답]
- 불일치 여부: [있음/없음]

## 이미지 해상도 비교
| 소스 | 해상도 | 파일 크기 |
|------|--------|----------|
| PDF 이미지 | ???x??? | ??? KB |
| 갤러리 이미지 | ???x??? | ??? KB |

## 결론
- 문제 원인: [OCR 문제 / AI 파싱 문제 / 이미지 품질 문제]
- 다음 단계: [구체적인 수정 방향]
```
