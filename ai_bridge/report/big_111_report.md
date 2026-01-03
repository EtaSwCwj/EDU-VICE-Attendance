# BIG_111 다중 페이지 인식 프롬프트 수정 보고서

## 작업 일자: 2026-01-02

## 수정 내용
1. `extractPdfChunkText` 함수의 프롬프트를 다중 페이지 인식용으로 변경
   - "p. XX" 형식을 교재 페이지 구분자로 인식하도록 수정
   - 한 PDF 페이지 안의 여러 교재 페이지 정답을 분리하여 추출

2. JSON 파싱 로직 수정
   - `parsed['pages']` → `parsed['answers']` 변경
   - `textbookPage` 필드를 `pageNumber`로 매핑
   - 디버그 메시지 개선: "X개 교재 페이지 추출"

## 수정 파일
- `lib/shared/services/claude_api_service.dart`
  - extractPdfChunkText 함수 프롬프트 (line 1279-1310)
  - JSON 파싱 로직 (line 1335-1344)

## 테스트 결과
인식된 페이지: [테스트 진행 후 업데이트 필요]
기대값: 9, 11, 13, 15, 16 (교재 페이지 번호, 분리됨)
결과: 성공/실패 [테스트 완료 후 업데이트]

## 기술적 개선사항
- 프롬프트에 명확한 예시 추가로 Claude의 인식 정확도 향상
- "pp. XX-XX" 형식의 범위 표기도 처리 (첫 번째 페이지로 저장)
- JSON 응답 구조를 더 직관적으로 변경 (answers 배열 사용)

## 주의사항
- PDF 업로드 시 Claude API의 응답 속도가 느릴 수 있음
- 페이지 번호가 "p." 없이 표기된 경우는 인식하지 못할 수 있음