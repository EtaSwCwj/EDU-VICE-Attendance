# BIG_082: 플로팅 버튼 다이얼로그에 "초대 메일 발송" 버튼 추가

> 생성일: 2025-12-23
> 목표: 멤버 추가 진입 경로 3개 모두 "초대 메일 발송" 버튼 통일

---

## ⚠️ 작성 전 체크리스트 (완료됨)

- [x] 로컬 코드 확인했나? → 433줄 `_showAddMemberDialog` 확인
- [x] 수정할 파일/줄 번호 특정했나? → 433줄 근처
- [x] 삭제/추가 코드 구체적으로? → 아래 명시
- [x] 테스트 계정 리셋? → 081에서 함, 불필요
- [x] 빌드 필요? → ✅ 폰 단독
- [x] 듀얼 필요? → ❌ 1개 계정으로 테스트 가능
- [x] **진입 경로 전체 확인?** → 아래 정리

---

## 📍 진입 경로 분석

| 진입 경로 | 다이얼로그 함수 | 버튼 상태 |
|----------|----------------|----------|
| 이메일 검색 | `_showUserConfirmationDialogFromSearch` | ✅ 3버튼 |
| QR 스캔 | `_showUserConfirmationDialog` | ✅ 3버튼 |
| **플로팅 버튼** | `_showAddMemberDialog` | ❌ **2버튼만!** |

**수정 대상: `_showAddMemberDialog` 함수**

---

## ⚠️ 필수: Opus는 직접 작업 금지!

### Sonnet 호출 방법
```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

### 예외
- AWS CLI (인증 필요)

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- 수정 파일: flutter_application_1/lib/features/invitation/invitation_management_page.dart
- 테스트 계정: maknae12@gmail.com (이미 리셋됨)

---

## 스몰스텝 (진행 시 체크박스 업데이트!)

### 1. `_showAddMemberDialog` 함수 수정 (433줄 근처)

현재 문제: 이메일 입력 후 바로 `_addMember` 호출 → AppUser 객체 없이 동작

**해결 방법**: 이메일로 AppUser 조회 후, 다른 다이얼로그들처럼 3버튼 다이얼로그 표시

- [ ] 파일: `lib/features/invitation/invitation_management_page.dart`
- [ ] 위치: `_showAddMemberDialog` 함수 내 actions 배열 (475줄 근처)

- [ ] 기존 코드 (삭제) - 전체 `_showAddMemberDialog` 함수:
```dart
void _showAddMemberDialog() {
  final emailController = TextEditingController();
  String selectedRole = 'student';

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('멤버 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이미 앱에 가입한 사용자만 추가할 수 있습니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                hintText: 'user@example.com',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const Text('역할 선택'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'teacher', label: Text('선생님')),
                ButtonSegment(value: 'student', label: Text('학생')),
              ],
              selected: {selectedRole},
              onSelectionChanged: (Set<String> selection) {
                setDialogState(() {
                  selectedRole = selection.first;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('이메일을 입력해주세요')),
                );
                return;
              }
              if (!email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('올바른 이메일 형식이 아닙니다')),
                );
                return;
              }
              Navigator.pop(context);
              _addMember(selectedRole, email);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] 새 코드 (추가) - 이메일 검색 후 AppUser 찾아서 다이얼로그 표시:
```dart
void _showAddMemberDialog() {
  final emailController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('멤버 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이미 앱에 가입한 사용자만 추가할 수 있습니다.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: '이메일',
              hintText: 'user@example.com',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () async {
            final email = emailController.text.trim();
            if (email.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('이메일을 입력해주세요')),
              );
              return;
            }
            if (!email.contains('@')) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('올바른 이메일 형식이 아닙니다')),
              );
              return;
            }
            Navigator.pop(context);
            
            // 이메일로 AppUser 검색 후 확인 다이얼로그 표시
            await _searchAndShowConfirmDialog(email);
          },
          child: const Text('검색'),
        ),
      ],
    ),
  );
}

Future<void> _searchAndShowConfirmDialog(String email) async {
  safePrint('[InvitationManagementPage] 멤버 추가 다이얼로그에서 검색: $email');
  
  // 로딩 표시
  if (mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  try {
    // 이메일로 AppUser 조회
    const listUsersQuery = '''
      query ListAppUsers(\$filter: ModelAppUserFilterInput) {
        listAppUsers(filter: \$filter) {
          items {
            id
            cognitoUsername
            name
            email
            profileImageUrl
          }
        }
      }
    ''';

    final usersResponse = await Amplify.API.query(
      request: GraphQLRequest<String>(
        document: listUsersQuery,
        variables: {
          'filter': {
            'email': {'eq': email.toLowerCase()}
          }
        },
      ),
    ).response;

    // 로딩 다이얼로그 닫기
    if (mounted) Navigator.pop(context);

    if (usersResponse.data == null) {
      throw Exception('Failed to query users');
    }

    final usersJson = json.decode(usersResponse.data!);
    final usersList = usersJson['listAppUsers']['items'] as List;

    if (usersList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$email은(는) 가입되지 않은 사용자입니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final targetUserJson = usersList.first;
    
    // 이미 멤버인지 확인
    final targetUserId = targetUserJson['id'] as String;
    final isAlreadyMember = _members.any((member) => member.userId == targetUserId);

    if (isAlreadyMember) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${targetUserJson['name']}님은 이미 등록된 멤버입니다'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // AppUser 객체 생성
    final user = AppUser(
      id: targetUserId,
      cognitoUsername: targetUserJson['cognitoUsername'] as String? ?? '',
      name: targetUserJson['name'] as String,
      email: targetUserJson['email'] as String,
      profileImageUrl: targetUserJson['profileImageUrl'] as String?,
    );

    // 기존 확인 다이얼로그 재사용 (3버튼: 취소/초대 메일 발송/바로 추가)
    if (mounted) {
      _showUserConfirmationDialogFromSearch(user);
    }
  } catch (e) {
    safePrint('[InvitationManagementPage] 멤버 추가 검색 실패: $e');
    
    // 로딩 다이얼로그가 열려있다면 닫기
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('사용자 검색 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### 2. flutter analyze
- [ ] flutter analyze 실행
- [ ] 에러/경고 0개 확인

### 3. 테스트 (폰 단독)
- [ ] flutter run -d RFCY40MNBLL
- [ ] 원장 계정 로그인
- [ ] 멤버 관리 페이지 진입
- [ ] **플로팅 버튼 "멤버 추가" 클릭**
- [ ] 이메일 입력 (maknae12@gmail.com) → "검색" 버튼
- [ ] 확인 다이얼로그에 **3개 버튼** 표시 확인:
  - "취소"
  - "초대 메일 발송"
  - "바로 추가"
- [ ] "초대 메일 발송" 클릭 → Invitation 생성 확인 (로그)
- [ ] DynamoDB에서 Invitation 레코드 확인

---

## 검증 규칙 (v7.3)

- 에러 메시지만 보고 실패 판정 금지
- 실제 화면/동작 확인 후 판정

---

## 로그 저장

각 스몰스텝 완료 시:
- ai_bridge/logs/big_082_step_XX.log

---

## 완료 조건

1. 플로팅 버튼 → 멤버 추가 다이얼로그가 3버튼 ("취소/초대 메일 발송/바로 추가") 표시
2. 모든 진입 경로에서 동일한 UX 제공
3. flutter analyze 에러 0개
4. 실제 Invitation 생성 테스트 성공
5. CP가 "테스트 종료" 입력
6. 보고서 작성 완료 (ai_bridge/report/big_082_report.md)
