# BIG_108: PDF 정답지 인식 디버깅

> 생성일: 2025-01-01
> 목표: PDF 정답지 업로드 시 정답 내용이 저장되지 않는 문제 디버깅

---

## 현재 상황

- PDF 업로드 → 페이지 번호만 저장됨
- 정답 내용(answerContents)이 저장 안 됨

---

## 스몰스텝

### 1. 잘못 수정된 부분 원복

- [ ] 파일: `lib/features/my_books/pages/answer_camera_page.dart`
- [ ] 찾기: `if (totalPages <= 20)`
- [ ] 변경: `if (totalPages <= 10)`
- [ ] 찾기: `safePrint('[AnswerCamera] 소용량 PDF - 단일 처리 (totalPages: $totalPages)');`
- [ ] 변경: `safePrint('[AnswerCamera] 소용량 PDF - 단일 처리');`

### 2. 디버그 로그 추가

- [ ] 같은 파일에서 `setState(() => _isAnalyzing = false);` 찾기 (line 240 근처)
- [ ] 그 바로 아래에 추가:

```dart
        // ★ 디버그 로그
        safePrint('[DEBUG] allExtractedPages.length: ${allExtractedPages.length}');
```

### 3. 빌드 및 테스트

```bash
flutter analyze
flutter run -d RFCY40MNBLL
```

- PDF 업로드 테스트
- 콘솔에서 `[DEBUG] allExtractedPages.length:` 값 확인

### 4. 보고서

`ai_bridge/report/big_108_report.md`에 한 줄:
```
결과: allExtractedPages.length = [숫자]
```

---

## 컨텍스트 관리

- 로그 전체 저장 금지
- 보고서 한 줄만
- 스몰스텝 2개마다 /compact
