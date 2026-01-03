# BIG_109: PDF 청크 크기 축소 (10→5)

> 생성일: 2025-01-01
> 목표: max_tokens 초과로 JSON 잘리는 문제 해결

---

## 원인

- 청크당 10페이지 → 응답 토큰이 4000 초과
- JSON 중간에 잘림 → 파싱 실패
- allExtractedPages = 0

## 해결책

청크당 페이지 수: 10 → 5

---

## 스몰스텝

### 1. answer_camera_page.dart 수정

- [ ] 파일: `lib/features/my_books/pages/answer_camera_page.dart`
- [ ] 찾기: `pagesPerChunk: 10`
- [ ] 변경: `pagesPerChunk: 5`

### 2. 청크 범위 계산도 수정

- [ ] 같은 파일에서 찾기:
```dart
final chunkStart = i * 10 + 1;
final chunkEnd = ((i + 1) * 10).clamp(1, totalPages);
```
- [ ] 변경:
```dart
final chunkStart = i * 5 + 1;
final chunkEnd = ((i + 1) * 5).clamp(1, totalPages);
```

### 3. 디버그 로그 제거 (선택)

- [ ] `[DEBUG]` 로그 남겨둬도 됨 (확인용)

### 4. 빌드 및 테스트

```bash
flutter analyze
flutter run -d RFCY40MNBLL
```

- PDF 업로드 테스트
- `[DEBUG] allExtractedPages.length:` 값 확인 (0보다 커야 함)
- 인식 결과 다이얼로그에서 내용 확인

### 5. 성공 시 book_detail_page에서 확인

- 페이지 클릭 → 정답 내용 표시되는지 확인

---

## 보고서

`ai_bridge/report/big_109_report.md`에:
```
결과: allExtractedPages.length = [숫자]
정답 내용 저장: 성공/실패
```

---

## 컨텍스트 관리

- 스몰스텝 2개마다 /compact
