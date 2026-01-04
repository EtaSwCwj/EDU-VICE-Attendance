# BIG_147: OCR + 이미지 동시 전송으로 레이아웃 인식 개선 보고서

## 작업 일시
- 2026년 1월 4일

## 작업 목표
AI가 OCR 텍스트 + 원본 이미지를 함께 분석하여 다열 레이아웃 순서 문제 해결

## 이전 문제
- 4열 레이아웃(A|B|C|D가 가로 배치)에서 OCR 순서가 뒤죽박죽
- ML Kit가 위→아래로 읽으면서 A-1, B-1, C-1, D-1을 섞어버림
- 결과: B 섹션이 통째로 A에 합쳐지는 등 누락 발생

## 해결 방법
- 변경 전: 이미지 → OCR(텍스트만) → AI 파싱
- 변경 후: 이미지 → OCR(텍스트) → AI에게 (텍스트 + 이미지) 둘 다 전송

## 수정 내용

### 1. claude_api_service.dart
- `parseOcrTextToAnswers` 메서드에 `File? imageFile` 파라미터 추가
- 이미지가 있으면 base64 인코딩하여 content에 포함
- 모델 선택 로직 추가: 이미지 있으면 Sonnet, 없으면 Haiku
- 프롬프트 개선: 이미지와 OCR 텍스트를 함께 분석하도록 명시

### 2. answer_parser_service.dart
- `extractAnswers` 메서드에서 Claude API 호출 시 이미지 파일도 전달
- `imageFile: imageFile` 파라미터 추가

## 테스트 결과

### 테스트 환경
- 기기: Galaxy A35 (RFCY40MNBLL)
- 이미지: 4열 레이아웃 정답지
- 페이지: Page 9, 11, 13, 15

### 성공 확인 포인트

1. **이미지 포함 여부 로그**
```
[Claude] 이미지 포함: true
```

2. **Page 11 섹션별 정답 확인** (BIG_147 기대값 일치)
- A 섹션: 4개 (angry, an artist, X, fantastic) ✅
- B 섹션: 4개 (well, happy, sweet, dark) ✅
- C 섹션: 4개 (bad, perfect, nice, rich) ✅
- D 섹션: 4개 (fur coat looks expensive 등) ✅

3. **전체 인식 결과**
- 열 1: Page 9, 11, 13
- 열 2: Page 15
- 총 4개 페이지, 모든 섹션 정확히 분리

### 주요 개선사항
1. **B 섹션 누락 문제 해결**: 이전에 A에 합쳐지던 B 섹션이 독립적으로 인식됨
2. **정답 순서 정확도 향상**: AI가 이미지를 보면서 레이아웃 구조 이해
3. **섹션별 정답 개수 일치**: 누락 없이 모든 정답 추출

## 비용 변화
- 텍스트만: Haiku 모델 (저비용)
- 이미지+텍스트: Sonnet 모델 (약 4배 비용)
- 정확도 향상을 위해 비용 증가 감수

## 코드 예시

### 이미지 처리 부분
```dart
if (imageFile != null) {
  final imgBytes = await imageFile.readAsBytes();
  final imgBase64 = base64Encode(imgBytes);
  final ext = imageFile.path.split('.').last.toLowerCase();
  final mediaType = switch (ext) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    _ => 'image/jpeg',
  };

  contentParts.add({
    'type': 'image',
    'source': {
      'type': 'base64',
      'media_type': mediaType,
      'data': imgBase64,
    },
  });
}
```

## 결론
BIG_147 작업이 성공적으로 완료되었습니다. OCR 텍스트와 이미지를 동시에 전송하는 방식으로 4열 레이아웃 정답지의 섹션 분리 문제를 해결했습니다. 테스트 결과 A/B/C/D 섹션이 정확히 분리되었고, 정답 누락 없이 모든 항목이 올바르게 인식되었습니다.

## 검증 완료
- ✅ A/B/C/D 섹션이 제대로 분리됨
- ✅ 정답 누락 없음 (Page 11 기준 각 섹션 4개씩)
- ✅ flutter analyze 에러 0개
- ✅ 실제 앱에서 정상 동작 확인