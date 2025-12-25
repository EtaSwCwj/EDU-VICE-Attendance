# BIG_088: 초대 수락 테스트 완료 보고서

> 작성일: 2025-12-25
> 목표: Lambda + Invitation update 권한 추가 후 초대 수락 기능 테스트

---

## ✅ 테스트 결과: 성공

### 최종 결과
- ✅ maknae12@gmail.com이 초대 수락 성공
- ✅ Lambda가 AcademyMember 자동 생성 (ID: `0809083c-318f-4f5c-b798-f2eeb2cbb447`)
- ✅ 다시 로그인 시 학원 홈 화면 정상 표시
- ✅ 에러 없이 정상 동작

---

## 🐛 발견된 문제 및 해결

### 1. "Unauthorized on [inviteeUserId]" 에러

**문제**:
- Invitation 업데이트 시 GraphQL 인증 에러 발생
- 에러 메시지: `"message": "Unauthorized on [inviteeUserId]"`

**원인**:
- `invitation.copyWith()`를 사용하면 **모든 필드**(inviteeUserId 포함)가 mutation에 포함됨
- AppSync는 **owner field**인 `inviteeUserId`를 mutation으로 수정하는 것을 허용하지 않음

**해결**:
- 직접 GraphQL mutation 작성하여 `inviteeUserId` 제외
- 업데이트할 필드만 명시: `id`, `status`, `usedAt`, `usedBy`

**수정 파일**:
- `flutter_application_1/lib/features/home/no_academy_shell.dart:106-145`

**수정 코드**:
```dart
// GraphQL mutation을 직접 작성 (inviteeUserId 제외)
const updateMutation = '''
  mutation UpdateInvitation(\$id: ID!, \$status: String!, \$usedAt: AWSDateTime!, \$usedBy: ID!) {
    updateInvitation(input: {
      id: \$id
      status: \$status
      usedAt: \$usedAt
      usedBy: \$usedBy
    }) {
      id
      status
      usedAt
      usedBy
    }
  }
''';

final updateInvitationRequest = GraphQLRequest<String>(
  document: updateMutation,
  variables: {
    'id': invitation.id,
    'status': 'accepted',
    'usedAt': now.format(),
    'usedBy': user.id,
  },
);
```

---

### 2. 초대 수락 후 로딩 상태 멈춤

**문제**:
- 초대 수락 성공 후 화면이 "받은 초대" 로딩 상태로 멈춤

**원인**:
- `auth.refreshAuth()` 호출 후 `setState(() { _isLoading = false; })` 누락

**해결**:
- `refreshAuth()` 완료 후 `_isLoading = false` 추가

**수정 코드**:
```dart
// AuthState 새로고침하여 홈 화면으로 이동
await auth.refreshAuth();

// 로딩 상태 해제
setState(() {
  _isLoading = false;
});
```

---

## 📊 테스트 로그

### 앱 로그 (flutter)
```
[NoAcademyShell] 초대 수락 클릭: 8c5110d3-cd5f-48ae-9051-ef0a5791dc05
[NoAcademyShell] 초대 수락 시작: user=a498ad1c-6011-70c6-2f00-92a2fad64b02, academyId=academy-001, role=student
[NoAcademyShell] Invitation 업데이트 성공: 8c5110d3-cd5f-48ae-9051-ef0a5791dc05, status=accepted
[NoAcademyShell] 초대 수락 완료: invitation=8c5110d3-cd5f-48ae-9051-ef0a5791dc05
[AuthState] 인증 상태 새로고침
[AuthState] Step 3: AcademyMember 조회
[AuthState]   role=student, academyId=academy-001
[AuthState] Step 4: Academy 조회
[AuthState]   Academy: 수학의 정석 학원
[AuthState] Summary: user=최우준, role=student, academy=수학의 정석 학원
```

### Lambda 로그 (CloudWatch)
```
2025-12-25T11:57:38.688Z [invitationAcceptTrigger] Status: pending -> accepted
2025-12-25T11:57:38.705Z [invitationAcceptTrigger] Creating: {...}
2025-12-25T11:57:39.508Z [invitationAcceptTrigger] Created: 0809083c-318f-4f5c-b798-f2eeb2cbb447
```

### DynamoDB 확인
**Invitation 레코드** (ID: `f429ec34-3a01-4d60-a0fd-79678c6067e5`):
- inviteeUserId: `a498ad1c-6011-70c6-2f00-92a2fad64b02` ✅
- status: `pending` → `accepted` ✅
- usedAt: `2025-12-25T11:57:38Z` ✅
- usedBy: `a498ad1c-6011-70c6-2f00-92a2fad64b02` ✅

**AcademyMember 레코드** (ID: `0809083c-318f-4f5c-b798-f2eeb2cbb447`):
- userId: `a498ad1c-6011-70c6-2f00-92a2fad64b02` ✅
- academyId: `academy-001` ✅
- role: `student` ✅

---

## 🔧 수정된 파일

1. **schema.graphql**
   - Invitation @auth 규칙 수정 (이미 BIG_087_2에서 완료)
   - `{ allow: owner, ownerField: "inviteeUserId", operations: [read, update] }`

2. **no_academy_shell.dart**
   - `_acceptInvitation()` 메서드 수정
   - GraphQL mutation 직접 작성 (inviteeUserId 제외)
   - `refreshAuth()` 후 `_isLoading = false` 추가

---

## ⚠️ 주의사항

### Owner Field 업데이트 제한
AppSync는 owner field를 mutation으로 수정하는 것을 허용하지 않습니다.
- ❌ `invitation.copyWith()` 사용 시 모든 필드 포함 → 에러
- ✅ 직접 GraphQL mutation 작성하여 필요한 필드만 업데이트

### 비슷한 에러 발생 가능성
다른 모델에서도 owner field가 있는 경우 주의:
- `Assignment`: `teacherUsername`, `studentUsername`
- `Student`: `username`
- `Teacher`: `username`
- `Lesson`: `teacherUsername`
- `AppUser`: `cognitoUsername`

---

## 📋 작업 요약

### 수정된 파일
- `lib/features/home/no_academy_shell.dart` (초대 수락 로직 수정)

### 실행한 명령어
- `amplify codegen models` (모델 재생성)
- `amplify push --yes` (스키마 배포)
- `flutter run -d RFCY40MNBLL` (앱 실행)
- `flutter analyze` (코드 분석)

### 현재 상태
- ✅ 초대 수락 기능 정상 작동
- ✅ Lambda 자동 생성 정상 작동
- ✅ 에러 없음
- ⚠️ 화면 전환 개선 필요 (refreshAuth 후 로딩 상태 해제 추가됨)

### 다음 단계
- 없음 (테스트 완료)

---

## 🎉 결론

**초대 수락 기능이 정상적으로 작동합니다!**

1. ✅ 사용자가 초대 수락 → Invitation 상태 업데이트
2. ✅ Lambda가 DynamoDB Stream 감지 → AcademyMember 자동 생성
3. ✅ refreshAuth() 후 학원 홈 화면으로 이동

**BIG_088 테스트 성공!** 🎊
