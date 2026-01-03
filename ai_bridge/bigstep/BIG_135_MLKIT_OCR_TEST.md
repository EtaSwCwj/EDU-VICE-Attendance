# BIG_135: ML Kit OCR + 정규식 파싱 테스트

> 생성일: 2026-01-03
> 목표: Claude API 대신 ML Kit OCR + 정규식으로 정답지 텍스트 추출

---

## 🎯 변경 내용

### 핵심 변경: Claude API → ML Kit OCR

**Before (BIG_133~134):**
```
PDF → 이미지 → 열 분리 → 병합 → [Claude API] → 결과
                                    ↓
                              - 윤리 거부
                              - JSON 불일치
                              - 82% 파싱 실패
```

**After (BIG_135):**
```
PDF → 이미지 → 열 분리 → 병합 → [ML Kit OCR] → [정규식 파싱] → 결과
                                    ↓                ↓
                              - 무료           - p.숫자 패턴
                              - 오프라인       - A) B) C) 섹션
                              - 일관된 출력    - 1. 2. 3. 정답
```

### 새 파일
- `lib/shared/services/answer_parser_service.dart`
  - `extractAnswers(File imageFile)` - 메인 메서드
  - `_parseText(String text)` - 페이지 단위 파싱
  - `_parseSections(String content)` - 섹션 파싱 (A, B, C...)
  - `_parseAnswers(String content)` - 정답 파싱 (1. 2. 3...)

### 수정 파일
- `answer_camera_page.dart`
  - import 추가
  - `_answerParser` 인스턴스 추가
  - `_pickPdfForAll`에서 Claude API 대신 `_answerParser.extractAnswers()` 사용

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- 테스트 PDF: Grammar Effect 2 정답지

---

## 스몰스텝

### 1. flutter analyze
- [ ] `cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1`
- [ ] `flutter analyze 2>&1 | tail -20`
- [ ] 에러 0개 확인

### 2. 테스트 실행
- [ ] `flutter run -d RFCY40MNBLL`
- [ ] 내 책 → Grammar Effect → 정답지 등록
- [ ] PDF 업로드

### 3. 로그 확인 (핵심!)

**A. ML Kit OCR 동작:**
```
[AnswerParser] 이미지 분석 시작: ...
[MlKitOcr] 분석 시작: ...
[MlKitOcr] 분석 완료: XX개 블록
[AnswerParser] OCR 텍스트 길이: XXXX
```
- [ ] ML Kit가 텍스트를 추출하는지 확인

**B. 정규식 파싱:**
```
[AnswerParser] 페이지 패턴 매칭: XX개
[AnswerParser] 페이지 발견: p.9
[AnswerParser]   섹션 A: 4개 정답
[AnswerParser]   섹션 B: 3개 정답
[AnswerParser] 파싱 완료: XX개 페이지
```
- [ ] 페이지 번호가 인식되는지 확인
- [ ] 섹션과 정답이 파싱되는지 확인

**C. UI에 표시:**
- [ ] "인식 결과 확인" 다이얼로그에 페이지들이 나오는지
- [ ] 각 페이지에 정답 내용이 있는지 (빈칸 아닌지!)

### 4. Before/After 비교

| 항목 | BIG_134 (Claude) | BIG_135 (ML Kit) |
|------|------------------|------------------|
| API 비용 | $$$ | 무료 |
| 윤리 거부 | 있음 | 없음 |
| JSON 파싱 | 82% 실패 | 해당없음 |
| 인식 페이지 | 8개 (빈칸) | 목표 15개+ |
| 정답 내용 | 빈칸 많음 | 내용 있음 |

- [ ] 위 표 기준 개선 확인

### 5. 로그 저장
- [ ] `ai_bridge/logs/big_135_test.log` 저장
- [ ] **[AnswerParser], [MlKitOcr] 로그 포함**

### 6. 보고서 작성
- [ ] `ai_bridge/report/big_135_report.md` 작성
- [ ] Before/After 비교표 포함
- [ ] ML Kit OCR 텍스트 추출 품질
- [ ] 정규식 파싱 정확도
- [ ] **보고서 작성 완료 직후 바로 /compact 실행**

---

## 완료 조건

1. flutter analyze 에러 0개
2. **ML Kit OCR 텍스트 추출 성공** (로그로 확인)
3. **정규식으로 페이지/섹션/정답 파싱 성공**
4. **인식 페이지 12개 이상** (BIG_134: 8개 빈칸에서 증가)
5. **정답 내용이 실제로 표시됨** (빈칸 아님!)
6. 로그 저장 완료
7. 보고서 작성 완료
8. /compact 실행
9. CP가 "테스트 종료" 입력

---

## ⚠️ 주의사항

1. **ML Kit는 영어/숫자에 강함** - 한글은 약할 수 있음
2. **정규식 패턴이 안 맞을 수 있음** - 로그 보고 조정 필요
3. **열 분리 + 병합은 그대로 유지** - 1열 이미지로 만들어서 OCR

---

## 실패 시 확인 사항

1. ML Kit 텍스트가 비어있다면:
   - 이미지 해상도 문제일 수 있음
   - 이미지 파일 경로 확인

2. 페이지 번호 인식 실패:
   - "p.숫자" 패턴이 다를 수 있음 (예: "P.9", "Page 9")
   - 정규식 패턴 확장 필요

3. 섹션/정답 파싱 실패:
   - 실제 텍스트 형식 확인 필요
   - 정규식 패턴 조정
