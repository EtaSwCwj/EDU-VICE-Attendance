# TASK_016: NoAcademyShell에 초대 목록 자동 표시

> **작성자**: 윈선임 (메인 개발 4)
> **작성일**: 2025-12-21
> **담당**: 윈후임 (Sonnet)
> **결과 파일**: `C:\github\ai_bridge\task_016_result.md`
> **원칙**: 묻지 말고 끝까지 진행. 로그 필수.

---

## 📋 배경

TASK_015에서 `getInvitationsByTargetEmail` 메서드 추가함.
이제 NoAcademyShell에서 이 메서드를 호출해서 초대 목록을 자동으로 보여줘야 함.

**현재**: "초대코드로 참여하기" 버튼만 있음
**목표**: 내 이메일로 온 초대가 있으면 목록으로 표시 + 수락 버튼

---

## 📋 작업 내용

### 파일: `lib/features/home/no_academy_shell.dart`

---

### 1단계: StatefulWidget으로 변환

```dart
class NoAcademyShell extends StatefulWidget {
  const NoAcademyShell({super.key});

  @override
  State<NoAcademyShell> createState() => _NoAcademyShellState();
}

class _NoAcademyShellState extends State<NoAcademyShell> {
  final _invitationService = InvitationService();
  List<Invitation> _invitations = [];
  Map<String, String> _academyNames = {};  // academyId -> name
  bool _isLoading = true;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  // ... 나머지 메서드들
}
```

---

### 2단계: import 추가

```dart
import '../../shared/services/invitation_service.dart';
import '../../shared/services/academy_member_service.dart';
import '../../models/Invitation.dart';
import '../../models/Academy.dart';
```

---

### 3단계: 초대 목록 로딩 메서드

```dart
Future<void> _loadInvitations() async {
  safePrint('[NoAcademyShell] 초대 목록 로딩 시작');
  
  try {
    // 1. 현재 유저 이메일 가져오기
    final authUser = await Amplify.Auth.getCurrentUser();
    final attributes = await Amplify.Auth.fetchUserAttributes();
    final emailAttr = attributes.firstWhere(
      (attr) => attr.userAttributeKey.key == 'email',
      orElse: () => AuthUserAttribute(
        userAttributeKey: const CognitoUserAttributeKey.custom('email'),
        value: '',
      ),
    );
    _userEmail = emailAttr.value;
    
    safePrint('[NoAcademyShell] 유저 이메일: $_userEmail');
    
    if (_userEmail == null || _userEmail!.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    
    // 2. 이메일로 초대 조회
    final invitations = await _invitationService.getInvitationsByTargetEmail(_userEmail!);
    
    // 3. 각 초대의 학원명 조회
    final academyNames = <String, String>{};
    for (final inv in invitations) {
      if (!academyNames.containsKey(inv.academyId)) {
        final academies = await Amplify.DataStore.query(
          Academy.classType,
          where: Academy.ID.eq(inv.academyId),
        );
        if (academies.isNotEmpty) {
          academyNames[inv.academyId] = academies.first.name;
        } else {
          academyNames[inv.academyId] = '알 수 없는 학원';
        }
      }
    }
    
    setState(() {
      _invitations = invitations;
      _academyNames = academyNames;
      _isLoading = false;
    });
    
    safePrint('[NoAcademyShell] 초대 ${invitations.length}개 로딩 완료');
  } catch (e) {
    safePrint('[NoAcademyShell] 초대 로딩 실패: $e');
    setState(() => _isLoading = false);
  }
}
```

---

### 4단계: 초대 수락 메서드

```dart
Future<void> _acceptInvitation(Invitation invitation) async {
  safePrint('[NoAcademyShell] 초대 수락: ${invitation.id}');
  
  try {
    final authUser = await Amplify.Auth.getCurrentUser();
    final userId = authUser.userId;
    
    // 1. AcademyMember 생성
    final memberService = AcademyMemberService();
    final member = await memberService.createMemberFromInvitation(
      invitation: invitation,
      userId: userId,
    );
    
    if (member == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('학원 등록에 실패했습니다'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    
    // 2. Invitation 사용 처리
    await _invitationService.useInvitation(
      invitation: invitation,
      userId: userId,
    );
    
    safePrint('[NoAcademyShell] 초대 수락 완료');
    
    // 3. 홈으로 이동 (역할에 맞는 Shell로 전환됨)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getRoleName(invitation.role)}(으)로 등록되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/home');
    }
  } catch (e) {
    safePrint('[NoAcademyShell] 초대 수락 실패: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

String _getRoleName(String role) {
  switch (role) {
    case 'owner': return '원장';
    case 'teacher': return '선생님';
    case 'student': return '학생';
    case 'supporter': return '서포터';
    default: return role;
  }
}
```

---

### 5단계: 초대 목록 위젯

```dart
Widget _buildInvitationList() {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  
  if (_invitations.isEmpty) {
    return const SizedBox.shrink();  // 초대 없으면 아무것도 표시 안 함
  }
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
          '받은 초대 (${_invitations.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ..._invitations.map((inv) => _buildInvitationCard(inv)),
      const SizedBox(height: 24),
    ],
  );
}

Widget _buildInvitationCard(Invitation invitation) {
  final academyName = _academyNames[invitation.academyId] ?? '알 수 없는 학원';
  final roleName = _getRoleName(invitation.role);
  final expiresAt = invitation.expiresAt.getDateTimeInUtc().toLocal();
  final daysLeft = expiresAt.difference(DateTime.now()).inDays;
  
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  academyName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('역할: $roleName'),
          Text(
            '만료: ${daysLeft}일 후',
            style: TextStyle(
              color: daysLeft <= 1 ? Colors.red : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  safePrint('[NoAcademyShell] 초대 거절: ${invitation.id}');
                  // TODO: 거절 처리 (나중에 구현)
                  setState(() {
                    _invitations.remove(invitation);
                  });
                },
                child: const Text('거절'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _acceptInvitation(invitation),
                child: const Text('수락'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
```

---

### 6단계: build 메서드 수정

기존 Column의 children 맨 위에 초대 목록 추가:

```dart
@override
Widget build(BuildContext context) {
  final auth = context.watch<AuthState>();
  final user = auth.user;

  return Scaffold(
    appBar: AppBar(
      title: const Text('EDU-VICE'),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => auth.signOut(),
          tooltip: '로그아웃',
        ),
      ],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 24.0, 0, 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ★ 초대 목록 (맨 위에 추가)
            _buildInvitationList(),
            
            // 기존 코드들...
            const Icon(Icons.school_outlined, size: 100, color: Colors.grey),
            // ... 나머지 기존 코드
          ],
        ),
      ),
    ),
  );
}
```

---

## 📝 로그 확인 포인트

```
[NoAcademyShell] 초대 목록 로딩 시작
[NoAcademyShell] 유저 이메일: maknae12@gmail.com
[InvitationService] Fetching invitations for email: maknae12@gmail.com
[InvitationService] Found 1 valid invitations for maknae12@gmail.com
[NoAcademyShell] 초대 1개 로딩 완료
```

수락 시:
```
[NoAcademyShell] 초대 수락: xxx-xxx-xxx
[AcademyMemberService] Creating member...
[InvitationService] Using invitation...
[NoAcademyShell] 초대 수락 완료
```

---

## 📝 테스트 방법

이건 코드 작성 후 flutter analyze만 확인.
실제 테스트는 TASK_017 (원장 UI) 완료 후 전체 플로우로 진행.

```bash
cd C:\github\EDU-VICE-Attendance\flutter_application_1
flutter analyze
```

---

## ✅ 완료 체크리스트

- [ ] StatefulWidget으로 변환
- [ ] import 추가 (InvitationService, AcademyMemberService, Invitation, Academy)
- [ ] _loadInvitations 메서드 추가
- [ ] _acceptInvitation 메서드 추가
- [ ] _getRoleName 메서드 추가
- [ ] _buildInvitationList 메서드 추가
- [ ] _buildInvitationCard 메서드 추가
- [ ] build 메서드에 초대 목록 추가
- [ ] 로그 추가 (safePrint)
- [ ] flutter analyze 0 에러

---

## 📝 결과 보고 템플릿

```markdown
# TASK_016 결과: NoAcademyShell 초대 목록 표시

## 작업 내용
- 수정한 파일:
- 추가한 메서드:

## flutter analyze
- 에러:
- 경고:

## 완료 체크리스트
- [ ] StatefulWidget 변환
- [ ] 초대 목록 로딩
- [ ] 초대 카드 UI
- [ ] 수락 버튼 동작
- [ ] flutter analyze 0 에러
```

---

**완료 후 `C:\github\ai_bridge\task_016_result.md`에 결과 저장할 것.**
