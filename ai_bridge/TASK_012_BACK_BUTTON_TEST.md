# TASK_012: 뒤로가기 버튼 테스트

> **작성일**: 2025-12-21
> **작성자**: 윈선임 (메인 개발 4)
> **수행자**: 윈후임 (Claude Code CLI)
> **결과 파일**: `C:\github\ai_bridge\TASK_012_RESULT.md`

---

## 🎯 목표

JoinByCodePage 뒤로가기 버튼 동작 확인

---

## 📋 테스트 플로우

### 1단계: 앱 실행
```bash
cd C:\github\EDU-VICE-Attendance\flutter_application_1
flutter run
```

### 2단계: maknae12@gmail.com 로그인
- 이 계정은 AppUser/AcademyMember 없음
- NoAcademyShell로 진입해야 함

### 3단계: "초대코드로 참여하기" 버튼 클릭
- JoinByCodePage로 이동

### 4단계: 확인 사항
1. **AppBar에 뒤로가기 버튼 있는가?** (← 아이콘)
2. **뒤로가기 버튼 클릭 시 NoAcademyShell로 돌아가는가?**
3. **안드로이드 백 버튼 (하단 ◁) 눌렀을 때 동작은?**
   - NoAcademyShell로 돌아감 ✅
   - 앱 종료됨 ❌ (버그)

---

## 📝 로그 확인 포인트

```
[NoAcademyShell] 초대코드로 참여하기 버튼 클릭
[JoinByCodePage] 페이지 진입
[JoinByCodePage] 뒤로가기 (pop 또는 back button)
[NoAcademyShell] 페이지 복귀
```

---

## 📄 결과 보고서 템플릿

```markdown
# TASK_012 결과: 뒤로가기 버튼 테스트

## 테스트 환경
- 디바이스: (Android 에뮬레이터 / 실기기)
- 테스트 계정: maknae12@gmail.com

## 결과

### 1. NoAcademyShell 진입
- 성공/실패: 

### 2. JoinByCodePage 진입
- 성공/실패:
- AppBar 뒤로가기 버튼 표시: O/X

### 3. AppBar 뒤로가기 버튼 클릭
- 결과: (NoAcademyShell 복귀 / 앱 종료 / 기타)

### 4. 안드로이드 백 버튼 (◁)
- 결과: (NoAcademyShell 복귀 / 앱 종료 / 기타)

## 로그 (관련 부분만)
```
(터미널 로그 복붙)
```

## 결론
- 버그 있음/없음:
- 수정 필요 여부:
```

---

## ⚠️ 주의사항

1. **코드 수정하지 말 것** - 테스트만
2. **로그 꼼꼼히 기록**
3. **앱 종료 시 명확히 보고** (앱꺼졌다고 말해줘야 함)

---

**테스트 완료 후 결과 파일 작성해서 저장할 것.**
