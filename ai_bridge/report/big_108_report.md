결과: allExtractedPages.length = 0

## JSON 파싱 실패 원인 분석

### 1. 오류 내용
- 청크 1: `FormatException: Unterminated string (at line 33, character 87)`
  - 내용: "Chapter 10 관계사\n\nUnit 01 주격, 목적격, 소유격 관계대명사\nPractice (p. 113)\nA 1" 에서 끊김
- 청크 2: `FormatException: Unterminated string (at line 21, character 41)`
  - 내용: "Chapter 11 수동태\n\nUnit" 에서 끊김

### 2. 원인 분석
1. **응답 크기 제한**: max_tokens가 4000으로 설정되어 있지만, JSON 형식으로 감싸진 긴 텍스트가 중간에 잘림
2. **JSON 문자열 파싱 로직 문제**:
   - `content.substring(start, end)`에서 `lastIndexOf('}')`가 잘못된 위치를 찾음
   - JSON이 완전하지 않은 상태에서 파싱 시도
3. **특수문자 이스케이프**: PDF 내용의 특수문자(줄바꿈, 따옴표 등)가 제대로 이스케이프되지 않았을 가능성

### 3. 결과
- 두 청크 모두 JSON 파싱 실패
- 텍스트 추출 실패로 fallback 모드 실행 (페이지 번호만 인식)
- 정답 내용은 전혀 추출되지 않음