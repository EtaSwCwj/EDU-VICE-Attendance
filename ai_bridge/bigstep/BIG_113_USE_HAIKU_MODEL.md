# BIG_113: PDF 처리 Haiku 모델로 변경 (비용 절감)

> 생성일: 2025-01-02
> 목표: PDF 정답지 처리에 Haiku 모델 사용하여 API 비용 절감

---

## 배경

- Sonnet 모델로 PDF 처리 시 비용이 빠르게 소진됨
- Haiku 모델은 Sonnet 대비 약 10배 저렴
- PDF 텍스트 추출은 복잡한 추론이 필요 없으므로 Haiku로 충분

---

## 스몰스텝

### 1. Haiku 모델 상수 추가

- [ ] 파일: `flutter_application_1/lib/shared/services/claude_api_service.dart`
- [ ] 위치: 파일 상단 (line 8~10 근처)
- [ ] 찾을 코드:
```dart
class ClaudeApiService {
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-20250514';
  final _storage = const FlutterSecureStorage();
```

- [ ] 변경할 코드:
```dart
class ClaudeApiService {
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-20250514';
  static const _modelHaiku = 'claude-3-5-haiku-20241022';  // PDF 처리용 (저렴)
  final _storage = const FlutterSecureStorage();
```

---

### 2. extractPdfChunkText 함수에서 Haiku 사용

- [ ] 같은 파일
- [ ] 위치: `extractPdfChunkText` 함수 내 API 호출 부분 (line 1310 근처)
- [ ] 찾을 코드:
```dart
        body: jsonEncode({
          'model': _model,
          'max_tokens': 4000,  // 청크당 4000 토큰으로 제한
```

- [ ] 변경할 코드:
```dart
        body: jsonEncode({
          'model': _modelHaiku,  // PDF 처리는 저렴한 Haiku 사용
          'max_tokens': 4000,  // 청크당 4000 토큰으로 제한
```

---

### 3. extractPdfText 함수에서도 Haiku 사용

- [ ] 같은 파일
- [ ] 위치: `extractPdfText` 함수 내 API 호출 부분 (line 1190 근처)
- [ ] 찾을 코드:
```dart
        body: jsonEncode({
          'model': _model,
          'max_tokens': 16000,
```

- [ ] 변경할 코드:
```dart
        body: jsonEncode({
          'model': _modelHaiku,  // PDF 처리는 저렴한 Haiku 사용
          'max_tokens': 16000,
```

---

### 4. analyzePdfPages 함수에서도 Haiku 사용

- [ ] 같은 파일
- [ ] 위치: `analyzePdfPages` 함수 내 API 호출 부분 (line 1130 근처)
- [ ] 찾을 코드:
```dart
        body: jsonEncode({
          'model': _model,
          'max_tokens': 2048,
```

- [ ] 변경할 코드:
```dart
        body: jsonEncode({
          'model': _modelHaiku,  // PDF 처리는 저렴한 Haiku 사용
          'max_tokens': 2048,
```

---

### 5. flutter analyze

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze 2>&1 | tail -15
```

- [ ] 에러 0개 확인

---

### 6. 테스트

```bash
flutter run -d RFCY40MNBLL
```

**테스트 순서:**
1. Grammar Effect 책 선택
2. 정답지 등록 → 전체 PDF 업로드
3. Grammar Effect 2 Answer Keys.pdf 선택
4. 처리 완료 대기

**확인할 것:**
- API 호출 성공 여부 (크레딧 부족 에러 없이)
- 인식 결과 다이얼로그 표시 여부
- 페이지 번호가 9, 11, 13... 형태로 분리되는지

---

## ⚠️ 필수 규칙

### 테스트 종료 조건
- **CP가 "테스트 종료" 입력할 때까지 테스트 계속**
- 에러 발생해도 임의로 종료 금지
- 성공해도 CP 확인 전까지 종료 금지

### 보고서 작성 (필수)
테스트 완료 후 반드시 `ai_bridge/report/big_113_report.md` 작성:

```markdown
# BIG_113 보고서

## 수정 내용
- Haiku 모델 상수 추가: _modelHaiku = 'claude-3-5-haiku-20241022'
- PDF 관련 함수 3개에서 _model → _modelHaiku 변경

## 테스트 결과
- API 호출 성공 여부: O/X
- 크레딧 에러 발생 여부: O/X
- 인식된 페이지: [숫자들]
- 기대값: 9, 11, 13, 15, 16...

## 비용 비교 (예상)
- 기존 Sonnet: $X.XX per 1M tokens
- 변경 Haiku: $X.XX per 1M tokens (약 10배 저렴)
```

### 컨텍스트 관리
- 스몰스텝 2개 완료할 때마다 /compact 실행

---

## 완료 조건

1. [ ] Haiku 모델 상수 추가 완료
2. [ ] extractPdfChunkText에서 Haiku 사용
3. [ ] extractPdfText에서 Haiku 사용
4. [ ] analyzePdfPages에서 Haiku 사용
5. [ ] flutter analyze 에러 0개
6. [ ] 테스트 실행 및 결과 확인
7. [ ] **보고서 작성 완료** (ai_bridge/report/big_113_report.md)
8. [ ] **CP에게 결과 보고**
9. [ ] CP가 "테스트 종료" 입력
