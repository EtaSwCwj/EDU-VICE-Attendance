# BIG_080: 초대 시스템 버그 수정

> 생성일: 2025-12-23
> 목표: DataStore → GraphQL API 변경 + 검색 다이얼로그에 초대 버튼 추가

---

## ⚠️ 필수: Opus는 직접 작업 금지!
가급적 코드/파일 작업은 Sonnet 호출해서 시킬 것.

### Sonnet 호출 방법
```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- 수정 파일: flutter_application_1/lib/features/invitation/invitation_management_page.dart

---

## 발견된 버그 (079_2 테스트 결과)

### 버그 1: 초대 메일 발송이 안 됨
- **증상**: "초대 메일 발송" 눌러도 Invitation이 DB에 안 들어감
- **원인**: `_sendInvitationEmail` 함수가 `Amplify.DataStore.save()` 사용
- **위치**: 659줄 근처
- **해결**: GraphQL API mutation으로 변경

### 버그 2: 검색 다이얼로그에 "초대 메일 발송" 버튼 없음
- **증상**: 이메일 검색 후 "추가" 버튼만 있음
- **원인**: `_showUserConfirmationDialogFromSearch` 함수에 버튼 누락
- **위치**: 687줄 근처 actions 배열
- **해결**: QR 다이얼로그처럼 "초대 메일 발송" 버튼 추가

### 버그 3: QR 스캔 후 유저 조회가 DataStore 사용
- **증상**: QR 인식 후 유저 정보 조회 실패 가능성
- **원인**: `_showQRScanner` 내 onDetect에서 `Amplify.DataStore.query()` 사용
- **위치**: 488줄 근처
- **해결**: GraphQL API query로 변경

---

## 스몰스텝 (진행 시 체크박스 업데이트!)

### 1. `_sendInvitationEmail` 함수 수정 (659줄 근처)

- [ ] 기존 코드 (삭제):
```dart
await Amplify.DataStore.save(invitation);
```

- [ ] 새 코드 (추가):
```dart
const createInvitationMutation = '''
  mutation CreateInvitation(\$input: CreateInvitationInput!) {
    createInvitation(input: \$input) {
      id
      academyId
      inviterUserId
      inviteeEmail
      inviteeUserId
      role
      status
      inviteCode
      expiresAt
    }
  }
''';

final response = await Amplify.API.mutate(
  request: GraphQLRequest<String>(
    document: createInvitationMutation,
    variables: {
      'input': {
        'academyId': widget.academyId,
        'inviterUserId': currentUser.id,
        'inviteeEmail': user.email,
        'inviteeUserId': user.id,
        'role': role,
        'status': 'pending',
        'inviteCode': inviteCode,
        'expiresAt': expiresAt.format(),
      }
    },
  ),
).response;

if (response.errors?.isNotEmpty ?? false) {
  throw Exception(response.errors!.first.message);
}

final responseData = json.decode(response.data!);
final createdId = responseData['createInvitation']['id'];
safePrint('[InvitationManagementPage] Invitation 생성 성공: id=$createdId');
```

### 2. `_showUserConfirmationDialogFromSearch` 함수 수정 (687줄 근처)

- [ ] 기존 actions (2개 버튼):
```dart
actions: [
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: const Text('취소'),
  ),
  FilledButton(
    onPressed: () {
      Navigator.pop(context);
      _addMember(selectedRole, user.email);
    },
    child: const Text('추가'),
  ),
],
```

- [ ] 새 actions (3개 버튼):
```dart
actions: [
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: const Text('취소'),
  ),
  OutlinedButton(
    onPressed: () {
      Navigator.pop(context);
      _sendInvitationEmail(user, selectedRole);
    },
    child: const Text('초대 메일 발송'),
  ),
  FilledButton(
    onPressed: () {
      Navigator.pop(context);
      _addMember(selectedRole, user.email);
    },
    child: const Text('바로 추가'),
  ),
],
```

### 3. `_showQRScanner` 함수 내 유저 조회 수정 (488줄 근처)

- [ ] 기존 코드 (삭제):
```dart
final users = await Amplify.DataStore.query(
  AppUser.classType,
  where: AppUser.ID.eq(userId),
);
```

- [ ] 새 코드 (추가):
```dart
const getUserQuery = '''
  query GetAppUser(\$id: ID!) {
    getAppUser(id: \$id) {
      id
      cognitoUsername
      name
      email
      profileImageUrl
    }
  }
''';

final userResponse = await Amplify.API.query(
  request: GraphQLRequest<String>(
    document: getUserQuery,
    variables: {'id': userId},
  ),
).response;

AppUser? foundUser;
if (userResponse.data != null) {
  final userData = json.decode(userResponse.data!);
  final userJson = userData['getAppUser'];
  if (userJson != null) {
    foundUser = AppUser(
      id: userJson['id'],
      cognitoUsername: userJson['cognitoUsername'] ?? '',
      name: userJson['name'],
      email: userJson['email'],
      profileImageUrl: userJson['profileImageUrl'],
    );
  }
}
```

- [ ] 그리고 아래 분기도 수정:
```dart
// 기존: if (users.isNotEmpty) { _showUserConfirmationDialog(users.first); }
// 변경:
if (foundUser != null) {
  _showUserConfirmationDialog(foundUser);
} else {
  // 사용자 없음 처리
}
```

### 4. flutter analyze
- [ ] flutter analyze 실행
- [ ] 에러/경고 0개 확인

### 5. 테스트 (폰 단독)
- [ ] flutter run -d RFCY40MNBLL
- [ ] 원장 계정 로그인
- [ ] 이메일 검색 → "초대 메일 발송" 버튼 표시 확인
- [ ] "초대 메일 발송" 클릭 → Invitation 생성 확인 (AWS DynamoDB 콘솔 또는 로그)
- [ ] "바로 추가" 클릭 → AcademyMember 생성 확인

---

## 검증 규칙 (v7.3)

- 에러 메시지만 보고 실패 판정 금지
- 실제 화면/동작 확인 후 판정

---

## 로그 저장

각 스몰스텝 완료 시:
- ai_bridge/logs/big_080_step_XX.log

---

## 완료 조건

1. `_sendInvitationEmail`이 GraphQL API 사용
2. 검색 다이얼로그에 "초대 메일 발송" 버튼 있음
3. QR 스캔 유저 조회가 GraphQL API 사용
4. flutter analyze 에러 0개
5. 실제 Invitation 생성 테스트 성공
6. CP가 "테스트 종료" 입력
7. 보고서 작성 완료 (ai_bridge/report/big_080_report.md)
