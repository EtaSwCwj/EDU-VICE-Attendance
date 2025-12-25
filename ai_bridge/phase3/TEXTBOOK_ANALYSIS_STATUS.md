# Phase 3: 교재 자동 분석 시스템

> 최종 업데이트: 2025-12-26

---

## 📊 진행 상황

| 기능 | 상태 | 비고 |
|------|------|------|
| Claude API 연동 | ✅ 완료 | claude_api_service.dart |
| API 키 설정 UI | ✅ 완료 | api_key_settings_page.dart |
| 이미지 분석 | ✅ 완료 | JPG, PNG, GIF, WEBP |
| PDF 분석 | ✅ 완료 | file_picker 사용 |
| 분석 결과 표시 | ✅ 완료 | JSON 형식 |
| DB 저장 | ✅ 완료 | Amplify API |
| 선생님 UI 연결 | ✅ 완료 | teacher_shell.dart 5번 탭 |
| 문제 개별 추출 | ❌ 보류 | Vision AI 한계 |

---

## 📁 관련 파일

### 신규 생성
```
lib/shared/services/claude_api_service.dart    # Claude API 호출
lib/features/settings/api_key_settings_page.dart  # API 키 설정
lib/features/textbook/textbook_analyzer_page.dart  # 교재 분석 UI
```

### 수정됨
```
lib/app/app_router.dart           # 라우트 추가
lib/features/teacher/teacher_shell.dart  # 교재 탭 연결
pubspec.yaml                      # 패키지 추가
```

---

## 🔧 사용된 패키지

```yaml
http: ^1.1.0                    # API 호출
flutter_secure_storage: ^9.0.0  # API 키 암호화 저장
file_picker: ^8.0.0             # 파일 선택 (이미지 + PDF)
```

---

## 🎯 Claude API 분석 결과 형식

```json
{
  "pageInfo": {
    "pageNumber": 6,
    "chapterTitle": "유리수와 순환소수",
    "section": "1단원"
  },
  "problems": [
    {
      "number": "1",
      "question": "다음 보기 중 유한소수인 것의 개수는?",
      "difficulty": "BASIC",
      "category": "CONCEPT",
      "answer": "3개",
      "concepts": ["유한소수", "무한소수"]
    }
  ]
}
```

---

## 🚀 테스트 방법

1. 선생님 계정 로그인
2. 하단 [교재] 탭 선택
3. 우측 상단 설정 아이콘 → API 키 입력
4. 이미지/PDF 선택 → [파일 분석]
5. 결과 확인 → [DB 저장]

---

## 🔜 다음 단계

### Phase 3 남은 작업
- [ ] 저장된 교재 목록 조회
- [ ] 분석 결과 수정 기능
- [ ] 로컬 서버 구축 (오프라인 분석)

### Phase 4 예정
- [ ] 교재 DB 마켓플레이스
- [ ] OCR 기반 문제 영역 자동 탐지
- [ ] 수익 배분 시스템

---

## ⚠️ 알려진 제한사항

1. **Windows DataStore 미지원**
   - Amplify DataStore가 Windows에서 동작 안 함
   - 모바일(Android/iOS)에서 테스트 필요

2. **문제 개별 추출 불가**
   - Vision AI 좌표 추출 한계
   - 페이지 단위 분석으로 대체

3. **하드코딩된 기본값**
   - 과목: MATH (수학)
   - 학년: 중2
   - 출판사: 비상교육
   - → 향후 사용자 입력으로 변경 필요
