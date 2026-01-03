# BIG_112: Map 문법 오류 수정 및 400 에러 디버깅

> 생성일: 2025-01-02
> 목표: extractPdfChunkText API 400 에러 해결

---

## 현재 상황

- PDF 업로드 시 "API 호출 실패: 400" 에러 발생
- 원인 추정: Dart Map 반환 문법 오류 또는 API 요청 형식 문제

---

## 스몰스텝

### 1. Map 문법 오류 수정

- [ ] 파일: `flutter_application_1/lib/shared/services/claude_api_service.dart`
- [ ] 위치: `extractPdfChunkText` 함수 내 JSON 파싱 부분 (line 1335 근처)
- [ ] 찾을 코드 (정확히 이 형태):
```dart
          final answers = (parsed['answers'] as List<dynamic>)
              .map((e) => {
                'pageNumber': e['textbookPage'],
                'content': e['content'],
              })
              .toList();
```

- [ ] 변경할 코드 (정확히 이렇게):
```dart
          final answers = (parsed['answers'] as List<dynamic>)
              .map((e) => <String, dynamic>{
                'pageNumber': e['textbookPage'],
                'content': e['content'],
              })
              .toList();
```

**설명**: `=> { }` 는 Dart에서 Set 또는 함수 body로 해석됨. Map 리터럴임을 명시하려면 `=> <String, dynamic>{ }` 형태로 써야 함.

---

### 2. 400 에러 상세 로그 추가

- [ ] 같은 파일, `extractPdfChunkText` 함수 내
- [ ] 위치: 응답 처리 부분 (line 1355 근처)
- [ ] 찾을 코드:
```dart
      } else {
        debugPrint('[ClaudeAPI] 에러: ${response.statusCode}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
```

- [ ] 변경할 코드:
```dart
      } else {
        debugPrint('[ClaudeAPI] 에러: ${response.statusCode}');
        debugPrint('[ClaudeAPI] 400 응답 body: ${response.body}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
```

---

### 3. flutter analyze 실행

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze 2>&1 | tail -15
```

- [ ] 에러 0개 확인
- [ ] 에러 있으면 수정 후 다시 analyze

---

### 4. 빌드 및 테스트

```bash
flutter run -d RFCY40MNBLL
```

**테스트 순서:**
1. Grammar Effect 책 선택
2. 정답지 등록 버튼 클릭
3. 전체 PDF 업로드 버튼 클릭
4. Grammar Effect 2 Answer Keys.pdf 선택
5. 처리 진행 상황 관찰

**확인할 것:**
- 400 에러가 다시 발생하는가?
- 발생하면 콘솔에서 `[ClaudeAPI] 400 응답 body:` 로그 확인
- 성공하면 인식 결과 다이얼로그 내용 확인

---

### 5. 결과에 따른 분기

**Case A: 400 에러 지속**
- 콘솔에서 `400 응답 body` 로그 복사
- 보고서에 에러 내용 기록
- CP에게 보고 후 다음 지시 대기

**Case B: 성공 (인식 결과 다이얼로그 표시)**
- 인식된 페이지 번호 확인 (Page 9, 11, 13... 형태인지)
- 정확함 - 저장 클릭
- book_detail_page에서 정답 내용 확인 가능한지 테스트

---

## ⚠️ 필수 규칙

### 테스트 종료 조건
- **CP가 "테스트 종료" 입력할 때까지 테스트 계속**
- 에러 발생해도 임의로 종료 금지
- 성공해도 CP 확인 전까지 종료 금지

### 보고서 작성 (필수)
테스트 완료 후 반드시 `ai_bridge/report/big_112_report.md` 작성:

```markdown
# BIG_112 보고서

## 수정 내용
- Map 문법 수정: `=> {` → `=> <String, dynamic>{`
- 400 에러 로그 추가

## 테스트 결과
- 400 에러 발생 여부: O/X
- 에러 발생 시 body 내용: [복사]
- 성공 시 인식된 페이지: [숫자들]

## 다음 단계
- [필요한 추가 작업]
```

### 컨텍스트 관리
- 스몰스텝 2개 완료할 때마다 /compact 실행
- 로그 전체 저장 금지 - 필요한 부분만

---

## 완료 조건

1. [ ] Map 문법 수정 완료
2. [ ] 400 에러 로그 추가 완료
3. [ ] flutter analyze 에러 0개
4. [ ] 테스트 실행 및 결과 확인
5. [ ] **보고서 작성 완료** (ai_bridge/report/big_112_report.md)
6. [ ] **CP에게 결과 보고**
7. [ ] CP가 "테스트 종료" 입력
