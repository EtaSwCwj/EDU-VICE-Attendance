# 개발 히스토리

> 이 문서는 중요한 결정, 변경, 교훈을 기록합니다.
> 새 Claude가 읽으면 맥락을 파악할 수 있습니다.

---

## 2025-12-21 (새벽) - 2실린더 v4 완성

### 🎯 목표

"커피 마시고 돌아오면 일 끝나있음" - 진정한 자동화

### 📈 진화 과정

| 버전 | 구조 | 문제점 |
|------|------|--------|
| v1 | 복붙 자동화 | 수동 개입 필요 |
| v2 | Manager + Worker watcher | 터미널 2개, 서버 실행 불가 |
| v3 | 교차검증 추가 | 거짓 보고 탐지 가능, but 여전히 2터미널 |
| v4 | **Worker 호출 방식** | Manager 1개만, 서버 실행 가능 |

### 🔑 핵심 변경 (v3 → v4)

**문제**: Worker가 계속 감시 모드라 서버 실행하면 막힘

**CP 아이디어**:
> "watcher를 계속 켜놓는건 매니저만 그렇게 하고,
> watcher-후임은 켰을때 파일이 있는지 검사하고 명령 완료되면 그냥 꺼!
> 매니저가 재지시 내릴때 watcher-후임을 다시 또 키면 되잖아?"

**해결**:
```javascript
// Manager가 Worker 호출
const worker = spawn('node', ['scripts/worker_watcher.js']);
worker.on('close', () => console.log('Worker 완료'));
```

### 🔍 교차검증 도입 배경

**문제**: Worker(Sonnet)가 거짓 보고함

**실제 사례 (BIG_019)**:
```
Worker 보고: "lib/domain/entities/invitation.dart 구현 완료!"
Manager 확인: 파일이 없음
→ FAIL 판단 → 재지시
Worker 재보고: "실제 파일 6개만 존재"
→ SUCCESS → 정확한 분석
```

**교훈**: AI 보고서만 믿으면 안 됨. 실제 코드 열어서 확인해야 함.

### 📊 작업 유형별 판단 도입 배경

**문제**: 분석 작업인데 "flutter analyze 에러" 기준으로 판단

**해결**: 키워드로 작업 유형 자동 판단
- 코드 → flutter analyze
- 분석 → 충실성
- 커밋 → git 성공 여부
- 정리 → 파일 삭제 여부

### 🌐 웹 서버 자동화

**문제**: `start cmd /k` 명령어가 제대로 안 먹음

**해결**: 배치 파일로 분리
```batch
# scripts/start_web.bat
start "Flutter Web Server" cmd /k "flutter run -d chrome --web-port=8080"
```

Worker가 배치 파일 호출 → 새 창에서 서버 시작 → Worker 종료

### 🐛 웹 DataStore 이슈

**문제**: 웹에서 MissingPluginException (DataStore 미지원)

**해결**:
```dart
if (!kIsWeb) {
  plugins.add(AmplifyDataStore(...));
}
```

### ✅ 오늘 완료한 빅스텝

| 번호 | 작업 | 결과 |
|------|------|------|
| BIG_017 | 테스트 파일 정리 | ✅ |
| BIG_018 | 코드 품질 개선 | ✅ |
| BIG_019 | Phase 2 분석 | ✅ (거짓말 탐지 성공) |
| BIG_020 | 자동화 개선 커밋 | ✅ |
| BIG_021 | 웹 테스트 환경 구성 | ✅ |
| BIG_024~025 | 새 구조 테스트 | ✅ |
| BIG_028 | 배치 파일 웹 서버 | ✅ |
| BIG_029 | DataStore 이슈 해결 | ✅ |
| BIG_030 | 웹 서버 재테스트 | ✅ |

### 💡 핵심 교훈

1. **거짓 보고 조심**: AI가 "완료했다"고 해도 실제 확인 필요
2. **프로세스 삭제 > 시간 단축**: CP 철학 - "줄이지 말고 없애라"
3. **습관 경계**: Desktop Opus도 "직접 해"라고 말하는 습관 있음 → Manager 시켜야 함
4. **작업 유형 구분**: 모든 작업을 코드 기준으로 판단하면 안 됨

---

## Phase 2 현재 상태 (BIG_019 분석 결과)

| 기능 | 진척도 | 상태 |
|------|--------|------|
| 초대 시스템 | 40% | 서비스 완료, UI 일부 미구현 |
| 서포터 시스템 | 30% | 서비스 완료, UI 기본만 |
| 컨텍스트 스위칭 | 60% | 기본 구조만, 동적 변경 없음 |
| **전체** | **43%** | |

### 미구현 항목

- 초대코드 입력 페이지
- 서포터 연결/해제 UI
- 런타임 역할/학원 변경

---

## 맥 테스트 환경 (2025-12-21)

### 디바이스

| 디바이스 | ID | 용도 |
|----------|-----|------|
| SM A356N (Android 폰) | RFCY40MNBLL | 모바일 테스트 |
| Chrome | chrome | 웹 테스트 |

### 스크립트

| 파일 | 용도 |
|------|------|
| scripts/start_web_mac.sh | 웹 서버 (Chrome) |
| scripts/start_phone_mac.sh | Android 폰 |

---

## 이전 히스토리 요약

### Profile 이미지 S3 업로드 (12/19~20)

- 5MB 제한, 512x512 리사이징
- 38개 디버그 로그 위치 추가
- 앱 테마 mint/teal로 통일

### Cognito → DynamoDB 연동 (12/18)

- 회원가입 시 자동으로 AppUser 생성
- userId = Cognito sub (cognitoUsername 아님!)

### DataStore 포기 → GraphQL API (12/17)

- DataStore 충돌, 캐시 문제 많음
- 직접 GraphQL 호출로 전환
