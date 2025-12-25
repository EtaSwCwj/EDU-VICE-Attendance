# BIG_092: 실시간 로그 모니터링 디버깅

> 생성일: 2025-12-25
> 목표: 초대 수락 후 화면 전환 실패 원인 파악 (실시간 로그 분석)

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
- 실시간 로그로 화면 전환 실패 원인 파악
- Lambda 완료 감지 여부 확인
- AuthState 갱신 여부 확인

### 테스트 시나리오
```
1. 테스트 계정 리셋
2. 앱 빌드 + 로그 파일 저장
3. owner_test1로 초대 발송
4. maknae12@gmail.com으로 수락
5. 로그 실시간 분석
```

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 로그 파일: ai_bridge/logs/realtime.log
- 테스트 계정:
  - 초대자: owner_test1
  - 피초대자: maknae12@gmail.com

---

## 터미널 구성

| 터미널 | 모델 | 역할 |
|--------|------|------|
| 터미널 1 | Opus | CP 대화 + 로그 모니터링 |
| 터미널 2 | Sonnet | 테스트 계정 리셋 + flutter run + 로그 저장 |

---

## 확인할 핵심 로그

```
[NoAcademyShell] 수락 클릭: {id}
[NoAcademyShell] Invitation 업데이트 완료
[NoAcademyShell] Lambda 대기 중... (X/20)
[NoAcademyShell] Lambda 완료 감지 (시도 X/20)   ← 이거 나오는지!
[AuthState] 로드 완료: user=..., role=..., academy=...   ← 이거 나오는지!
[NoAcademyShell] 홈 화면 전환 실행
```

---

## 완료 조건

1. ✅ 로그에서 실패 원인 파악 → **Cognito 토큰 캐싱 문제**
2. ✅ 수정 방향 결정 → **forceRefresh: true 옵션 추가**

---

## 결과

### 문제 원인
- Lambda는 정상 작동했으나 Cognito 캐시된 토큰으로 인해 이전 역할(student) 유지
- 재로그인 시에만 새 토큰 발급되어 정상 작동

### 해결 방법
- refreshAuth에서 Cognito 세션 강제 새로고침 추가
- `FetchAuthSessionOptions(forceRefresh: true)` 사용

**상세 내용**: [보고서](../../report/big_092_report.md) 참조
