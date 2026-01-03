# BIG_137 테스트 보고서: 단일 페이지 OCR+AI 파싱 검증

> 작성일: 2026-01-03
> 목표: 1페이지 이미지만으로 OCR+AI 파싱 정확도 검증

---

## 요약

**테스트 결과: 실패 ❌**

- 갤러리 선택: ✅ 성공
- OCR 텍스트 추출: ✅ 성공 (59개 블록, 800자)
- AI API 호출: ✅ 성공 (200 OK, 2869자 응답)
- 정답 내용 파싱: ❌ 실패 (빈 값)
- 원인: BIG_136과 동일한 문제 재현

---

## 작업 내용

### 1. 갤러리 기능 추가
- 기존: 카메라 촬영, PDF 업로드만 가능
- 신규: "갤러리에서 선택" 버튼 추가됨
- 테스트에 갤러리 이미지 선택 기능 사용

### 2. 테스트 수행
- 이미지: 309.png (450x1237)
- 1페이지 정답지 이미지로 테스트
- ML Kit OCR → Claude AI 파싱 파이프라인 실행

### 3. OCR 결과 (성공)
```
[MlKitOcr] 분석 완료: 59개 블록
[AnswerParser] OCR 텍스트 길이: 800
```
- ML Kit OCR이 정상적으로 텍스트 추출
- 800자의 텍스트 확보

### 4. AI 파싱 결과 (부분 성공)
```
[Claude] 응답 길이: 2869
[Claude] 총 11개 섹션 파싱 완료
```
- Claude API 호출 성공
- 11개 섹션으로 파싱됨
- p.9(4섹션) + p.11(4섹션) + p.13(3섹션)

### 5. 데이터 변환 실패
```
[DEBUG] pages[0]: {pageNumber: 9, sections: {}, content: }
```
- API는 정답 내용을 반환했으나
- answer_parser_service.dart에서 변환 시 내용이 사라짐
- 최종적으로 빈 sections와 빈 content로 저장됨

---

## 문제점 분석

### 1. 페이지 중복 문제
- 1페이지 이미지에서 3개 페이지(9, 11, 13) 감지
- 각 페이지가 4개씩 중복 생성 (총 11개)
- 중복 원인: 섹션별로 별도 페이지 객체 생성

### 2. 정답 내용 누락 문제 (핵심)
- Claude API는 정답 개수를 정확히 파악 (예: "섹션 A: 1개 정답")
- 하지만 실제 정답 텍스트가 전달되지 않음
- sections 맵이 비어있음: `{}`
- content 문자열도 비어있음: `""`

### 3. 데이터 타입 불일치 가능성
```dart
// API 결과를 ParsedPage로 변환하는 코드
final rawSections = result['sections'] as Map<String, dynamic>? ?? {};
```
- API 응답의 sections 구조와 코드가 기대하는 구조가 다를 수 있음
- 타입 캐스팅 실패로 데이터 손실

---

## BIG_136과의 비교

| 항목 | BIG_136 (전체 PDF) | BIG_137 (1페이지) |
|------|-------------------|------------------|
| OCR | 성공 | 성공 |
| API 호출 | 성공 | 성공 |
| 페이지 인식 | 207페이지 (오류) | 9,11,13페이지 (정상) |
| 정답 내용 | 비어있음 | 비어있음 |
| 토큰 사용 | 183K+21K (초과) | 문제없음 |

**결론**: 1페이지로 테스트해도 동일한 문제 발생. 토큰 초과는 원인이 아님.

---

## 근본 원인

### answer_parser_service.dart의 데이터 변환 로직 문제
```dart
// 43-51줄: API 결과를 ParsedPage로 변환
final sections = <String, List<String>>{};
final rawSections = result['sections'] as Map<String, dynamic>? ?? {};

for (final entry in rawSections.entries) {
  if (entry.value is List) {
    sections[entry.key] = (entry.value as List).map((e) => e.toString()).toList();
  }
}
```

**문제점**:
1. `result['sections']`의 실제 구조를 확인하지 않고 가정
2. 중첩된 데이터 구조를 평면화하는 과정에서 손실
3. 에러 처리 없이 빈 맵(`{}`)으로 대체

---

## 개선 방안

### Option 1: 디버깅 강화 (추천)
1. Claude API 응답 전체를 로그로 출력
2. `result['sections']`의 실제 구조 파악
3. 데이터 변환 로직 수정

### Option 2: API 응답 형식 단순화
1. Claude 프롬프트 수정
2. 더 단순한 JSON 구조로 응답받기
3. 변환 과정 최소화

### Option 3: OCR+AI 방식 포기
1. 정규식 기반 파싱으로 회귀
2. 교재별 하드코딩
3. 사용자 수동 입력

---

## 다음 단계

### 즉시 시도할 수 있는 것
```dart
// claude_api_service.dart의 parseOcrTextToAnswers() 수정
debugPrint('[Claude] 원본 응답: ${jsonEncode(parsedAnswers)}');
```
- API 응답 구조를 정확히 파악
- 데이터가 어디서 사라지는지 추적

### 장기적 개선
1. 단위 테스트 추가
2. 에러 처리 강화
3. 타입 안정성 개선

---

## 결론

OCR+AI 파싱 방식 자체는 작동하지만, **데이터 변환 로직의 버그**로 인해 최종 결과가 비어있게 됩니다. 이는 비교적 간단한 코드 수정으로 해결 가능한 문제이며, OCR+AI 접근법을 포기할 필요는 없습니다.

핵심은 Claude API가 반환하는 JSON 구조와 Flutter 코드가 기대하는 구조를 일치시키는 것입니다.