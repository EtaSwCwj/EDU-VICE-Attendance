# BIG_XXX: [제목]

> 생성일: YYYY-MM-DD
> 목표: [한 줄 목표]

---

## ⚠️ 작성 전 체크리스트 (Desktop Opus 필수 확인!)

> 이 체크리스트 완료 전에 스몰스텝 작성 금지!

### 기본 확인
- [ ] 로컬 코드 확인했나? (view 도구로 실제 파일 열어봄)
- [ ] 수정할 파일/줄 번호 특정했나?
- [ ] 삭제할 코드 vs 추가할 코드 구체적으로 작성했나?
- [ ] **새 함수/로직에 safePrint 로그 추가 지시했나?**

### 테스트 환경
- [ ] 테스트 계정 리셋 필요한가? (필요하면 0번 스텝에 추가)
- [ ] **테스트 계정 현재 상태 확인했나?** (이전 테스트로 오염됐을 수 있음)
- [ ] 빌드 필요한가? (코드 수정만이면 analyze만)
- [ ] 듀얼 빌드 필요한가? (2개 계정/기기 필요하면 듀얼)

### 플로우 확인
- [ ] **진입 경로 전체 확인했나?** (이 기능에 도달하는 모든 경로 확인)
- [ ] **영향 범위 확인했나?** (이 수정이 다른 파일/함수에 영향 주는가?)

### 의존성 확인
- [ ] 새로 import 필요한 패키지 있나?
- [ ] schema/모델 변경 필요한가?

### 에러 케이스
- [ ] 실패 시 사용자에게 어떻게 알려주나? (스낵바, 다이얼로그 등)
- [ ] 네트워크 오류 처리 있나?

### 작업 연결
- [ ] 이전 BIG에서 미완료된 것 있나?
- [ ] 이 작업이 다음 작업의 선행 조건인가?

---

## ⚠️ 사이드 이펙트 체크리스트 (필수!)

> **이거 안 하면 버그 만든다. 하나씩 체크하고 넘어갈 것!**

### 새 함수 추가 시
- [ ] 관련된 기존 함수 전부 나열
- [ ] 각 함수에서 새 필드/로직 반영 필요한지 확인
- [ ] 특히: create → update/delete 쌍으로 확인

### 새 필드 추가 시
- [ ] 해당 필드 사용하는 모든 곳 확인
- [ ] true/false 분기 처리 확인
- [ ] 초기값, 리셋값 확인

### 테스트 시 로그 분석
- [ ] 예상과 다른 값 나오면 즉시 원인 추적
- [ ] "왜 이 값이 나왔지?" 질문하고 답 찾기
- [ ] 이상한 로그는 보고서에 "문제점"으로 기록

---

## ⚠️ 필수: Opus는 직접 작업 금지!
가급적 코드/파일 작업은 Sonnet 호출해서 시킬 것.

### Sonnet 호출 방법
```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

### 예외 (Opus가 직접 해도 되는 것)
- AWS CLI (인증 필요)
- amplify 명령어 (대화형 입력 필요)

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- 수정 파일: [파일 경로]
- 테스트 계정: maknae12@gmail.com (AppUser ID: a498ad1c-6011-70c6-2f00-92a2fad64b02)

---

## 🎯 기대 결과 & 테스트 시나리오

> **CP 확인용**: 이 작업이 성공하면 어떻게 되는지

### 기대 결과
- [이 작업 완료 시 어떤 기능이 동작하는지]
- [사용자가 어떤 경험을 하게 되는지]

### 테스트 시나리오
```
1. [첫 번째 단계] → [예상 결과]
2. [두 번째 단계] → [예상 결과]
3. [세 번째 단계] → [예상 결과]
4. [최종 확인] → [성공 조건]
```

---

## 스몰스텝 (진행 시 체크박스 업데이트!)

### 0. 테스트 계정 초기화 (필요 시)
> 테스트에 maknae12@gmail.com 사용하면 필수!

- [ ] AcademyMember 삭제:
```bash
aws dynamodb scan --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "userId = :uid" --expression-attribute-values '{":uid":{"S":"a498ad1c-6011-70c6-2f00-92a2fad64b02"}}' --region ap-northeast-2

aws dynamodb delete-item --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --key '{"id":{"S":"조회된ID"}}' --region ap-northeast-2
```
- [ ] 삭제 확인

### 1. [작업 제목]

- [ ] 파일: [경로]
- [ ] 위치: [줄 번호]
- [ ] 기존 코드 (삭제):
```dart
// 삭제할 코드
```
- [ ] 새 코드 (추가):
```dart
// 추가할 코드
```

### 2. flutter analyze
- [ ] flutter analyze 실행
- [ ] 에러/경고 0개 확인

### 3. 테스트 (빌드 필요 시)

#### 폰 단독 (1개 계정으로 충분할 때)
- [ ] flutter run -d RFCY40MNBLL
- [ ] [테스트 시나리오]

#### 듀얼 빌드 (2개 계정 필요할 때)
- [ ] Sonnet 1: flutter run -d RFCY40MNBLL (폰 - 계정A)
- [ ] Sonnet 2: flutter run -d chrome --web-port=8080 (웹 - 계정B)
- [ ] [테스트 시나리오]

---

## 검증 규칙 (v7.3)

- 에러 메시지만 보고 실패 판정 금지
- 실제 화면/동작 확인 후 판정

---

## ⚠️ Opus 필수: 로그 직접 확인!

**보고서만 읽지 말고, 로그 파일도 직접 확인할 것!**

```
확인할 로그:
- ai_bridge/logs/big_XXX_step_YY.log
- 폰 빌드 시: Flutter 콘솔 로그 (safePrint 출력)
```

**로그에서 확인할 것:**
1. 예상한 함수가 호출됐나? (safePrint 메시지 있나?)
2. 데이터가 올바르게 전달됐나? (user id, email 등)
3. 에러가 어디서 발생했나? (스택트레이스)
4. API 응답이 정상인가? (GraphQL response)

**보고서만 읽으면 세부 정보 놓침!**

---

## ⚠️ 컨텍스트 관리 (CLI 오버플로우 방지)

> CLI에서 오래 작업하면 컨텍스트 초과로 세션 종료됨. 반드시 지키기!

### 필수 규칙
1. **스몰스텝 1~2개 완료할 때마다 /compact 실행**
2. **파일 전체 읽기 금지** - 필요한 부분만 (view_range 사용)
3. **로그는 필터링** - `grep`, `tail`, `head` 사용
4. **에러 시 전체 출력 금지** - 핵심 메시지만

### 예시
```bash
# 나쁜 예
cat 파일전체.dart
flutter analyze

# 좋은 예  
view 파일.dart [100, 150]  # 필요한 라인만
flutter analyze 2>&1 | tail -10  # 마지막 10줄만
grep "[ERROR]" 로그파일.log  # 에러만 필터
```

### /compact 타이밍
- 스몰스텝 1~2개 완료 후
- 긴 파일 수정 완료 후
- 빌드/테스트 완료 후
- 에러 수정 완료 후

---

## 로그 저장

각 스몰스텝 완료 시:
- ai_bridge/logs/big_XXX_step_YY.log
- **로그는 핵심만 짧게** (전체 저장 금지)

---

## 완료 조건

1. [조건 1]
2. [조건 2]
3. flutter analyze 에러 0개
4. CP가 "테스트 종료" 입력
5. 보고서 작성 완료 (ai_bridge/report/big_XXX_report.md)
