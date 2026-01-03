# 후임 지시 메시지 (복붙용)

---

## Claude Code CLI 실행 명령어
```bash
cd C:\gitproject\EDU-VICE-Attendance
npm run claude:opus:c
```
또는
```bash
claude --model claude-opus-4-20250514 --dangerously-skip-permissions -c
```

---

## 복붙 메시지

```
ai_bridge/bigstep/BIG_105_PROBLEM_SPLIT_TEST.md 읽고 테스트 진행해줘.

수정된 파일 3개:
1. lib/features/my_books/services/problem_split_service.dart - 문제 분할 로직 (ocr_test_page.dart 성공 로직으로 교체)
2. lib/features/my_books/pages/problem_camera_page.dart - 임시파일 즉시 영구저장
3. lib/features/my_books/pages/book_detail_page.dart - 초기화 시 problems DB + 이미지 폴더 삭제

테스트:
1. flutter run -d RFCY40MNBLL
2. 문제 촬영 → 분할 로그 확인
3. 촬영 기록 초기화 → DB/파일 삭제 확인

결과는 ai_bridge/report/BIG_105_RESULT.md 에 작성해줘.
```

---

## 빠른 테스트만 원하면

```
flutter run -d RFCY40MNBLL 해서 문제 촬영 테스트해줘.

확인할 로그:
[ProblemSplit] 감지된 섹션: [A, B, C, D]
[OCR] A: 1 발견
[ProblemSplit] ✓ A.1 저장

실패하면 에러 로그 전체 보여줘.
```
