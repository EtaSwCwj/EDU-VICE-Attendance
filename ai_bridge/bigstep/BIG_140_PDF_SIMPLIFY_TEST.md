# BIG_140: PDF 처리 단순화 테스트 (열 분리/병합 제거)

> 생성일: 2026-01-03
> 목표: PDF → 이미지 → 직접 OCR+AI (열 분리/병합 없이)

---

## ⚠️ 필수: 템플릿 읽고 작업할 것!

**Opus가 작업 전 반드시 읽어야 할 파일:**
```
C:\gitproject\EDU-VICE-Attendance\ai_bridge\templates\BIGSTEP_TEMPLATE.md
```

---

## 배경

### BIG_138~139 결과
| 테스트 | 입력 | 결과 |
|--------|------|------|
| BIG_138 | 1열 이미지 (갤러리) | ✅ 성공 |
| BIG_139 | 2열 이미지 (갤러리) | ✅ 성공 |
| 기존 PDF | PDF 전체 | ❌ 실패 (61페이지 오인식) |

### 가설
- 갤러리 선택: 이미지 그대로 → OCR+AI → **성공**
- PDF 처리: 이미지 → 열 분리 → 세로 병합 → OCR+AI → **실패**
- **열 분리/병합 과정에서 품질 저하 발생?**

### 수정 내용
`_pickPdfForAll()` 메서드에서:
- ❌ 제거: 열 개수 감지 (`detectColumnCount`)
- ❌ 제거: 열별 크롭 (`cropByColumns`)
- ❌ 제거: 세로 병합 (`mergeVertically`)
- ✅ 유지: PDF → 이미지 변환
- ✅ 변경: 이미지 그대로 `extractAnswers()` 호출

---

## 환경

- 프로젝트: `C:\gitproject\EDU-VICE-Attendance\flutter_application_1`
- 수정 파일: `lib/features/my_books/pages/answer_camera_page.dart`
- 테스트 기기: 폰 (RFCY40MNBLL)
- **테스트 PDF**: Grammar Effect 정답지 PDF

---

## 🎯 기대 결과 & 테스트 시나리오

### CP 예상: 실패할 것 같다
- 이유: 2열 레이아웃에서 여러 페이지에 걸친 정답 처리 문제
- 예: Task 4가 1열 끝 → 2열 시작으로 이어지는 경우

### 성공 기준 (만약 성공한다면)
```
로그에서 확인:
[PDF처리] Step 1 완료: X개 페이지
[PDF처리] 페이지 1 → 교재 p.9
[PDF처리] 페이지 1 → 교재 p.11
...
[PDF처리] 총 추출 결과: N개 교재 페이지 (N >= 3)
```

### 실패 기준
- `[PDF처리] 총 추출 결과: 0개 교재 페이지`
- 페이지 번호 오인식 (61페이지 등)
- 정답 내용이 빈 값

---

## 스몰스텝

### 1. flutter analyze
```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze
```
- [ ] 에러 0개 확인

### 2. 폰 빌드 & 실행
```bash
flutter run -d RFCY40MNBLL
```
- [ ] 빌드 성공 확인

### 3. PDF 테스트

#### 3-1. 테스트 실행
- [ ] 앱에서 나의 책 탭 이동
- [ ] GRAMMAR EFFECT 교재 선택
- [ ] 정답지 촬영 화면 진입
- [ ] **"전체 PDF 업로드"** (주황색 버튼) 탭
- [ ] 정답지 PDF 선택

#### 3-2. 로그 확인 (핵심!)

**Step 1: PDF → 이미지 변환**
```
[PDF처리] ========================================
[PDF처리] PDF 선택 시작 (BIG_140: 단순화 방식)
[PDF처리] 열 분리/병합 제거, 이미지 그대로 OCR+AI
[PDF처리] ========================================
[PDF처리] PDF 선택됨: /path/to/file.pdf
[PDF처리] 파일 크기: XXX KB
[PDF처리] Step 1: PDF → 이미지 변환 시작
[PDF처리] Step 1 완료: X개 페이지, XXXms
[PDF처리] - 이미지 1: /path/pdf_page_1.png, XXX KB
```

**Step 2: 각 페이지 OCR+AI**
```
[PDF처리] ====== PDF 페이지 1/X ======
[PDF처리] 페이지 1: extractAnswers() 호출
[PDF처리] 페이지 1: extractAnswers() 완료, XXXms
[PDF처리] 페이지 1: N개 교재 페이지 인식  ← 핵심!
[PDF처리] 페이지 1 → 교재 p.9
[PDF처리]   - sections: [A, B, C, D]
[PDF처리]   - content 길이: XXX자
```

**Step 4: 결과 정리**
```
[PDF처리] Step 4: 결과 정리
[PDF처리] 총 추출 결과: N개 교재 페이지  ← 핵심!
[PDF처리] 정렬 후 페이지 번호: [9, 11, 13, ...]
```

#### 3-3. 성공/실패 판정

**성공 조건:**
- [ ] `총 추출 결과: N개` 에서 N >= 3
- [ ] 페이지 번호가 정상 (9, 11, 13 등)
- [ ] 다이얼로그에 정답 내용 표시

**실패 조건:**
- [ ] `총 추출 결과: 0개`
- [ ] 페이지 번호 오인식 (61페이지 등)
- [ ] 에러 발생

---

## 로그 저장

테스트 완료 후 반드시 저장:
```
ai_bridge/logs/big_140_test.log
```

**⚠️ 로그 필터링 필수! (오버플로우 방지)**

```bash
# 핵심 로그만 필터링해서 저장
adb logcat -d | grep -E "\[PDF처리\]|\[Claude\]|\[MlKitOcr\]|ERROR|Exception" | tail -200
```

**저장할 내용 (필터링된 것만!):**
1. `[PDF처리]` 태그 로그 (grep 필터링)
2. `[Claude]` 태그 로그 (grep 필터링)
3. `ERROR`, `Exception` 포함 라인만
4. **최대 200줄까지만** (tail -200)

**저장하지 말 것:**
- Flutter 빌드 로그 전체
- 일반 I/flutter 로그
- 시스템 로그

---

## 완료 조건

### 성공 시
1. PDF에서 3개 이상 교재 페이지 인식
2. 페이지 번호 정상 (61페이지 같은 오인식 없음)
3. 정답 내용 포함
4. **결론: 열 분리/병합이 문제였음! 단순화 방식 채택**

### 실패 시
1. 인식 결과 0개 또는 오인식
2. **결론: PDF 자체의 OCR 품질 문제? 또는 다른 원인?**
3. 다음 단계: 원인 분석 후 다른 접근 필요

---

## 다음 단계 (결과에 따라)

### 성공하면
- 기존 열 분리/병합 코드 정리
- 성능 최적화 (병렬 처리 등)

### 실패하면
- PDF → 이미지 변환 품질 확인
- OCR 입력 이미지와 갤러리 이미지 비교 분석
- 다른 접근법 검토

---

## ⚠️ Opus 필수 확인사항

1. **템플릿 먼저 읽기**: `ai_bridge/templates/BIGSTEP_TEMPLATE.md`
2. **로그 필터링 저장**: grep으로 `[PDF처리]`, `[Claude]` 태그만, 최대 200줄
3. **성공/실패 명확히 판정**: 위 기준 참고
4. **보고서 작성**: `ai_bridge/report/big_140_report.md`
