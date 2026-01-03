# BIG_120: 목차 기능 화면 표시 문제 해결

> 생성일: 2025-01-03
> 목표: 목차 섹션이 화면에 표시되도록 확인 및 수정

---

## 현재 상황

코드 분석 결과:
1. `book_detail_page.dart` - `_buildTableOfContentsSection()` 존재 ✅
2. `build()` 메서드에서 호출됨 ✅
3. `app_router.dart` - `/toc-camera/:bookId` 등록됨 ✅
4. `toc_camera_page.dart` - 파일 정상 ✅

**문제:** 코드는 있는데 화면에 안 보임 → 앱 재빌드 필요

---

## 스몰스텝 (디버깅은 후임 담당)

### 1. 앱 완전 종료 후 재빌드

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1

# 빌드 캐시 삭제
flutter clean

# 의존성 다시 받기
flutter pub get

# 앱 재빌드 및 실행
flutter run -d RFCY40MNBLL
```

---

### 2. 책 상세 페이지에서 목차 섹션 확인

**확인 순서:**
1. 내 책장 → Grammar Effect 선택
2. 책 상세 페이지에서 **스크롤 다운**
3. "등록된 정답지 페이지" 아래에 "목차 (X개)" 섹션 있는지 확인

**기대 화면:**
```
페이지 맵
├── 본책 (19p) / Workbook (10p)
└── 페이지 번호 그리드

> 등록된 정답지 페이지 (0개)   ← 닫힌 상태

> 목차 (0개)                  ← 이게 보여야 함!

v 문제 촬영 기록 (0건)         ← 열린 상태
```

---

### 3. 목차 섹션이 보이면

**테스트 진행:**
1. "목차 (0개)" 터치해서 펼치기
2. "목차 페이지 촬영" 버튼 클릭
3. 카메라 화면 진입 확인
4. Grammar Effect 목차 페이지 촬영
5. AI 인식 결과 확인
6. "저장" 클릭

---

### 4. 그래도 안 보이면

**코드 확인:**
```bash
# book_detail_page.dart에서 목차 섹션 호출 확인
grep -n "_buildTableOfContentsSection" lib/features/my_books/pages/book_detail_page.dart
```

**기대 결과:**
- `build()` 메서드 내에 `_buildTableOfContentsSection(),` 호출이 있어야 함
- `_buildTableOfContentsSection` 메서드 정의가 있어야 함

만약 없으면 → 코드가 저장 안 된 것 → 다시 추가 필요

---

## ⚠️ 필수 규칙

### 디버깅 및 로그 관리
- **디버깅과 로그 분석은 후임(소넷)이 담당**
- 로그 파일 전체 읽기 금지 (토큰 초과)
- `grep -i "error\|toc" [파일] | tail -30` 사용

### 테스트 종료 조건
- **CP가 "테스트 종료" 입력할 때까지 테스트 계속**

### 보고서 작성 (필수)
테스트 완료 후 반드시 `ai_bridge/report/big_120_report.md` 작성:

```markdown
# BIG_120 보고서

## 재빌드 결과
- flutter clean 실행: O/X
- flutter run 성공: O/X

## 화면 확인
- 목차 섹션 표시 여부: O/X
- 위치: [정답지 섹션 아래 / 안 보임]

## 기능 테스트 (섹션 보이면)
- 목차 펼치기: O/X
- 촬영 버튼 동작: O/X
- 카메라 진입: O/X
- AI 인식: O/X
- 저장: O/X

## 문제점 (있으면)
- [발견된 문제점]
```

### 컨텍스트 관리
- 스몰스텝 2개 완료할 때마다 /compact 실행
- **보고서 작성 완료 직후 반드시 /compact 실행**

---

## 완료 조건

1. [ ] flutter clean && flutter run 실행
2. [ ] 목차 섹션 화면 표시 확인
3. [ ] (보이면) 목차 촬영 테스트
4. [ ] **보고서 작성 완료** (ai_bridge/report/big_120_report.md)
5. [ ] **/compact 실행**
6. [ ] **CP에게 결과 보고**
7. [ ] CP가 "테스트 종료" 입력
