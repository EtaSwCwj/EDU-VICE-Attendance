# BIG_090: 초대 수락 후 자동 화면 전환 테스트 - 실패 보고서

> 작성일: 2025-12-25
> 상태: **실패 (미해결)**

---

## 📋 목표

BIG_089에서 구현한 초대 수락 후 자동 화면 전환 기능 테스트

**기대 결과**: 초대 수락 성공 후 재로그인 없이 바로 학원 홈 화면으로 자동 이동

---

## 🔍 테스트 환경

- **프로젝트**: `C:\gitproject\EDU-VICE-Attendance\flutter_application_1`
- **디바이스**: SM-A356N (Android)
- **테스트 계정**:
  - 초대자: owner_test1 (수학의 정석 학원 원장)
  - 피초대자: maknae12@gmail.com (AppUser ID: `a498ad1c-6011-70c6-2f00-92a2fad64b02`)

---

## 🧪 테스트 수행 내역

### 1차 시도 (12:30)
- **문제**: 초대 수락 버튼 클릭 후 로딩만 표시되고 화면 전환 안 됨
- **원인 분석**:
  - Lambda가 정상 작동하여 AcademyMember 생성됨 (12:38:12)
  - 하지만 BIG_089에서 추가한 코드가 적용되지 않음
  - Hot restart 문제로 추정

### 2차 시도 (12:43)
- **조치**:
  - 테스트 계정 리셋
  - `flutter clean` 실행
  - 앱 재빌드
- **문제**: 동일 증상 반복
- **DynamoDB 확인**:
  - Invitation: accepted (12:43:50)
  - AcademyMember: 정상 생성 (12:43:40)
- **로그 분석**: 수정된 polling 로직이 전혀 실행되지 않음

### 3차 시도 (12:48)
- **조치**: 완전 재시작
- **문제**: 동일 증상 반복
- **최종 확인**: Invitation이 accepted 상태로 변경됨

---

## 🐛 발견된 문제점

### 1. InvitationService 필터링 로직
**파일**: `lib/shared/services/invitation_service.dart:141`

```dart
filter: {
  inviteeEmail: { eq: $email }
  status: { eq: "pending" }  // ← 문제!
}
```

**문제**: `getInvitationsByTargetEmail()` 메서드가 **status가 "pending"인 초대만** 조회함
**결과**: 이미 accepted된 초대는 UI에 표시되지 않음

### 2. 테스트 플로우 문제
- 초대 발송 → 수락 시도 → Lambda가 즉시 AcademyMember 생성
- 하지만 Invitation status는 이미 "accepted"
- 재시도 시 새 초대가 필요하지만, 이전 초대가 여전히 accepted 상태로 남아있음
- UI에서는 pending 초대만 표시하므로 초대 목록이 비어보임

### 3. 미확인 사항
수정된 코드가 실제로 실행되었는지 불확실:
- 로그에 `[NoAcademyShell] Lambda 대기 중...` 출력 없음
- Hot reload/restart 문제 가능성
- 또는 초대 목록이 비어있어서 수락 버튼 자체가 없었을 가능성

---

## ✅ 확인된 정상 동작

1. **Lambda Trigger 정상 작동**
   - Invitation status를 "accepted"로 업데이트하면
   - DynamoDB Stream을 통해 Lambda가 트리거됨
   - AcademyMember가 정상 생성됨

2. **재로그인 시 정상 동작**
   - AcademyMember가 있으면 학원 홈 화면으로 정상 이동
   - 역할(role) 기반 화면 분기 정상 작동

---

## 📊 BIG_089 구현 코드 분석

### 수정된 _acceptInvitation 메서드
**파일**: `lib/features/home/no_academy_shell.dart:145-165`

```dart
// Lambda 완료 대기 (최대 10초, 0.5초 간격)
bool memberCreated = false;
for (int i = 0; i < 20; i++) {
  await Future.delayed(const Duration(milliseconds: 500));

  // AuthState 새로고침
  await auth.refreshAuth();

  // AcademyMember가 생성되었는지 확인
  if (auth.currentAcademy != null) {
    memberCreated = true;
    safePrint('[NoAcademyShell] Lambda 완료 감지: AcademyMember 생성됨 (시도 ${i + 1}/20)');
    break;
  }

  safePrint('[NoAcademyShell] Lambda 대기 중... (시도 ${i + 1}/20)');
}

if (!memberCreated) {
  throw Exception('Lambda 처리 시간 초과: AcademyMember가 생성되지 않았습니다.');
}
```

**로직**:
1. Invitation status를 "accepted"로 업데이트
2. Lambda가 비동기로 AcademyMember 생성하는 동안 대기
3. 0.5초마다 AuthState를 새로고침하여 AcademyMember 생성 확인
4. 생성 확인되면 `context.go('/home')`으로 화면 전환

---

## 🔧 근본 원인 추정

### 가설 1: UI에 초대가 표시되지 않음
- InvitationService가 pending 초대만 반환
- 테스트 중 생성된 초대가 이미 accepted 상태
- **결과**: UI에 초대 목록이 비어있어서 수락 버튼 자체가 없었을 가능성

### 가설 2: 코드가 실행되지 않음
- Hot restart가 제대로 작동하지 않음
- Flutter clean + 재빌드 후에도 동일
- **가능성 낮음**: 로그에 다른 수정사항들은 정상 반영됨

### 가설 3: 타이밍 이슈
- Lambda 실행 속도가 예상보다 빠름 (약 8-10초)
- refreshAuth()가 제대로 작동하지 않음
- **가능성 중간**: DynamoDB 확인 시 AcademyMember는 정상 생성됨

---

## 💡 개선 방안

### 단기 해결책
1. **테스트 데이터 완전 리셋**
   - Invitation 완전 삭제
   - AcademyMember 완전 삭제
   - 새로운 초대 발송 후 즉시 수락 테스트

2. **로그 강화**
   ```dart
   safePrint('[NoAcademyShell] 초대 수락 버튼 클릭됨!'); // 제일 먼저 추가
   safePrint('[NoAcademyShell] _acceptInvitation 메서드 진입');
   ```

3. **UI 디버깅**
   - 수락 버튼이 실제로 활성화되어 있는지 확인
   - onPressed 콜백이 제대로 연결되어 있는지 확인

### 중기 해결책
1. **InvitationService 개선**
   - pending 초대뿐 아니라 accepted 초대도 조회 (테스트용)
   - 또는 status 필터 제거 옵션 추가

2. **Lambda 완료 확인 방식 개선**
   - polling 대신 실시간 알림 (Firebase, Amplify Hub)
   - 또는 Lambda에서 완료 후 클라이언트에 push notification

3. **에러 처리 강화**
   - Lambda 실패 시 명확한 에러 메시지
   - 타임아웃 시 재시도 옵션 제공

### 장기 해결책 (아키텍처 개선)
1. **초대 수락 플로우 재설계**
   - GraphQL Subscription 활용
   - AcademyMember 생성 이벤트를 실시간으로 수신
   - 즉시 화면 전환

2. **DataStore Sync 활용**
   - Amplify DataStore의 자동 동기화 기능 활용
   - observeQuery()로 AcademyMember 변경 감지
   - 자동 UI 업데이트

---

## 📝 테스트 결과 요약

| 항목 | 결과 | 비고 |
|------|------|------|
| Lambda Trigger | ✅ 정상 | AcademyMember 정상 생성 |
| Invitation 업데이트 | ✅ 정상 | status: pending → accepted |
| 자동 화면 전환 | ❌ 실패 | 재로그인 시에만 동작 |
| polling 로직 실행 | ❌ 미확인 | 로그 출력 없음 |
| UI 초대 목록 표시 | ❌ 실패 | pending 초대만 표시 |

---

## 🎯 결론

### 성공한 부분
- ✅ Lambda Trigger를 통한 AcademyMember 자동 생성
- ✅ 재로그인 시 정상적인 화면 분기

### 실패한 부분
- ❌ 초대 수락 직후 자동 화면 전환
- ❌ polling 로직 실행 확인

### 미확인 사항
- 수정된 코드가 실제로 실행되었는지 불명확
- UI에 초대가 제대로 표시되었는지 불명확

### 최종 판단
**BIG_090 목표 달성 실패**

재로그인하면 정상 작동하지만, 초대 수락 직후 자동 전환은 작동하지 않음.
추가 디버깅과 로그 분석이 필요함.

---

## 📌 다음 단계 제안

1. **로그 강화 후 재테스트**
   - 수락 버튼 클릭 로그 추가
   - _acceptInvitation 메서드 진입 로그 추가
   - 각 polling 시도마다 상세 로그 추가

2. **UI 디버깅**
   - 초대 목록이 비어있는 이유 확인
   - pending 초대가 제대로 생성되는지 확인

3. **대안 검토**
   - 현재 방식(polling) vs 실시간 알림(subscription)
   - 사용자 경험 관점에서 재로그인 안내 vs 자동 전환

---

## 📎 참고 자료

- BIG_089: Lambda Trigger 구현 및 코드 수정
- BIG_088: 초대 수락 테스트 (수동 확인)
- Invitation 테이블: status 필터링 로직
- NoAcademyShell: 초대 수락 처리 로직
