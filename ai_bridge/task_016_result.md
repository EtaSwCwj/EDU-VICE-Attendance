# TASK_016 완료 보고서

**작성일**: 2025-12-21
**작업**: NoAcademyShell 초대 목록 UI 구현
**상태**: ✅ 완료

---

## 📋 작업 내용

### 1. 수정한 파일

**파일**: `lib/features/home/no_academy_shell.dart`

**변경 사항**: StatelessWidget → StatefulWidget 변환 및 초대 목록 기능 추가

**코드 크기**:
- 기존: 153줄 (StatelessWidget)
- 수정 후: 387줄 (StatefulWidget)
- **증가**: +234줄

---

## 📝 주요 변경 사항

### 1. 클래스 구조 변경

**기존 (StatelessWidget)**:
```dart
class NoAcademyShell extends StatelessWidget {
  const NoAcademyShell({super.key});

  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

**수정 후 (StatefulWidget)**:
```dart
class NoAcademyShell extends StatefulWidget {
  const NoAcademyShell({super.key});

  @override
  State<NoAcademyShell> createState() => _NoAcademyShellState();
}

class _NoAcademyShellState extends State<NoAcademyShell> {
  // State 변수 및 메서드
}
```

---

### 2. 추가된 import

```dart
import '../../shared/services/invitation_service.dart';
import '../../shared/services/academy_member_service.dart';
import '../../models/Invitation.dart';
import '../../models/Academy.dart';
```

**이유**:
- `InvitationService`: 이메일로 초대 목록 조회
- `AcademyMemberService`: 초대 수락 시 멤버 생성
- `Invitation`: 초대 모델
- `Academy`: 학원명 조회용

---

### 3. State 변수 추가

```dart
final _invitationService = InvitationService();
List<Invitation> _invitations = [];
Map<String, String> _academyNames = {};  // academyId -> name
bool _isLoading = true;
String? _userEmail;
```

**역할**:
- `_invitationService`: 초대 서비스 싱글톤 인스턴스
- `_invitations`: 받은 초대 목록
- `_academyNames`: 학원 ID → 학원명 매핑
- `_isLoading`: 로딩 상태
- `_userEmail`: 현재 유저 이메일

---

### 4. 추가된 메서드

#### (1) `_loadInvitations()` - 초대 목록 로딩

**위치**: 34-87줄

**동작 플로우**:
```
1. Cognito에서 현재 유저 이메일 가져오기
   ↓
2. InvitationService.getInvitationsByTargetEmail(email) 호출
   ↓
3. 각 초대의 academyId로 Academy 조회 (학원명)
   ↓
4. setState로 UI 업데이트
```

**코드**:
```dart
Future<void> _loadInvitations() async {
  safePrint('[NoAcademyShell] 초대 목록 로딩 시작');

  try {
    // 1. 현재 유저 이메일 가져오기
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

**로그**:
- `[NoAcademyShell] 초대 목록 로딩 시작`
- `[NoAcademyShell] 유저 이메일: user@example.com`
- `[NoAcademyShell] 초대 3개 로딩 완료`

---

#### (2) `_acceptInvitation()` - 초대 수락

**위치**: 89-138줄

**동작 플로우**:
```
1. AcademyMemberService.createMemberFromInvitation() 호출
   ↓
2. InvitationService.useInvitation() 호출 (사용 처리)
   ↓
3. SnackBar로 성공 메시지 표시
   ↓
4. /home으로 이동 (역할에 맞는 Shell로 자동 전환)
```

**코드**:
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
```

**성공 시 플로우**:
```
NoAcademyShell
  ↓ (초대 수락)
AcademyMember 생성
  ↓
/home 이동
  ↓
AuthState가 역할 재판단
  ↓
역할에 맞는 Shell로 자동 라우팅
- owner → OwnerShell
- teacher → TeacherShell
- student → StudentShell
- supporter → SupporterShell
```

---

#### (3) `_getRoleName()` - 역할 코드 → 한글명 변환

**위치**: 140-148줄

**코드**:
```dart
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

**사용처**:
- 초대 수락 성공 SnackBar: "학생(으)로 등록되었습니다!"
- 초대 카드 UI: "역할: 학생"

---

#### (4) `_buildInvitationList()` - 초대 목록 UI

**위치**: 150-175줄

**조건부 렌더링**:
```dart
if (_isLoading) {
  return const Center(child: CircularProgressIndicator());
}

if (_invitations.isEmpty) {
  return const SizedBox.shrink();  // 초대 없으면 아무것도 표시 안 함
}

// 초대 있으면 목록 표시
return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Padding(..., child: Text('받은 초대 (${_invitations.length})')),
    ..._invitations.map((inv) => _buildInvitationCard(inv)),
  ],
);
```

**UI 상태**:
1. **로딩 중**: CircularProgressIndicator
2. **초대 없음**: 아무것도 표시 안 함 (SizedBox.shrink)
3. **초대 있음**: "받은 초대 (3)" + 카드 목록

---

#### (5) `_buildInvitationCard()` - 개별 초대 카드

**위치**: 177-237줄

**카드 내용**:
```
┌─────────────────────────────────┐
│ 📧 서울컴퓨터학원                │
│                                 │
│ 역할: 학생                       │
│ 만료: 5일 후                     │
│                                 │
│          [거절]  [수락]         │
└─────────────────────────────────┘
```

**코드**:
```dart
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
            '만료: $daysLeft일 후',
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

**특징**:
- 만료일이 1일 이하면 빨간색 표시
- 거절 버튼: TODO (임시로 목록에서만 제거)
- 수락 버튼: `_acceptInvitation()` 호출

---

### 5. initState 추가

**위치**: 28-32줄

```dart
@override
void initState() {
  super.initState();
  _loadInvitations();
}
```

**동작**:
- NoAcademyShell 진입 시 자동으로 초대 목록 로딩 시작

---

### 6. build() 메서드 수정

**변경 사항**: 기존 UI 위에 초대 목록 추가

**위치**: 262줄

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // ★ 초대 목록 (맨 위에 추가)
    _buildInvitationList(),

    // 기존 UI (아이콘, 안내 문구, QR 코드 등)
    // ...
  ],
)
```

**UI 배치**:
```
┌─────────────────────────────────┐
│  받은 초대 (2)                   │  ← 신규 추가
│  [초대 카드 1]                   │  ← 신규 추가
│  [초대 카드 2]                   │  ← 신규 추가
│                                 │
│  🏫                             │  ← 기존 UI
│  학원에 등록되지 않았습니다      │
│  [QR 코드]                       │
│  [초대코드로 참여하기]            │
└─────────────────────────────────┘
```

---

## 🔄 사용 플로우

### 시나리오 1: 초대 목록이 있는 경우

```
1. 유저가 NoAcademyShell 진입
   ↓
2. initState → _loadInvitations() 자동 호출
   ↓
3. 로딩 스피너 표시
   ↓
4. Cognito에서 이메일 가져오기
   ↓
5. InvitationService.getInvitationsByTargetEmail(email)
   ↓
6. 각 초대의 학원명 조회 (Academy 테이블)
   ↓
7. setState → UI 업데이트
   ↓
8. 화면 상단에 초대 카드 목록 표시
   ↓
9. 유저가 "수락" 버튼 클릭
   ↓
10. _acceptInvitation() 호출
   ↓
11. AcademyMember 생성
   ↓
12. Invitation 사용 처리 (usedAt, usedBy 업데이트)
   ↓
13. SnackBar: "학생(으)로 등록되었습니다!"
   ↓
14. /home으로 이동
   ↓
15. AuthState가 역할 재판단
   ↓
16. 학생용 Shell(StudentShell)로 자동 라우팅
```

### 시나리오 2: 초대 목록이 없는 경우

```
1. 유저가 NoAcademyShell 진입
   ↓
2. initState → _loadInvitations() 자동 호출
   ↓
3. 로딩 스피너 표시
   ↓
4. InvitationService.getInvitationsByTargetEmail(email)
   ↓
5. 빈 리스트 반환
   ↓
6. setState → _invitations = []
   ↓
7. _buildInvitationList() → SizedBox.shrink() (아무것도 표시 안 함)
   ↓
8. 기존 UI만 표시 (QR 코드, 초대코드 입력 버튼 등)
```

---

## 📊 전체 파일 구조 (수정 후)

```dart
// lib/features/home/no_academy_shell.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../shared/services/auth_state.dart';
import '../../shared/services/invitation_service.dart';      // 신규
import '../../shared/services/academy_member_service.dart';  // 신규
import '../../models/Invitation.dart';                       // 신규
import '../../models/Academy.dart';                          // 신규

/// 소속 학원이 없는 유저용 화면
class NoAcademyShell extends StatefulWidget {               // StatelessWidget → StatefulWidget
  const NoAcademyShell({super.key});

  @override
  State<NoAcademyShell> createState() => _NoAcademyShellState();
}

class _NoAcademyShellState extends State<NoAcademyShell> {
  // State 변수
  final _invitationService = InvitationService();
  List<Invitation> _invitations = [];
  Map<String, String> _academyNames = {};
  bool _isLoading = true;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadInvitations();                                      // 신규
  }

  Future<void> _loadInvitations() async { /* ... */ }       // 신규 (34-87줄)
  Future<void> _acceptInvitation(Invitation invitation) async { /* ... */ } // 신규 (89-138줄)
  String _getRoleName(String role) { /* ... */ }            // 신규 (140-148줄)
  Widget _buildInvitationList() { /* ... */ }               // 신규 (150-175줄)
  Widget _buildInvitationCard(Invitation invitation) { /* ... */ } // 신규 (177-237줄)

  @override
  Widget build(BuildContext context) {
    // ...
    Column(
      children: [
        _buildInvitationList(),  // ← 신규 추가
        // 기존 UI...
      ],
    )
  }
}
```

**총 줄 수**: 387줄

**구성**:
- import: 11줄
- State 변수: 5개
- 메서드: 6개 (initState, _loadInvitations, _acceptInvitation, _getRoleName, _buildInvitationList, _buildInvitationCard)

---

## 🧪 flutter analyze

```bash
cd /c/gitproject/EDU-VICE-Attendance/flutter_application_1
flutter analyze
```

**결과**:
```
Analyzing flutter_application_1...
No issues found! (ran in 8.0s)
```

✅ **에러**: 0개
✅ **경고**: 0개

---

## 🔧 수정한 내용 (IDE 경고 해결)

### 경고 1: Unused variable 'authUser'

**위치**: 39줄

**기존**:
```dart
final authUser = await Amplify.Auth.getCurrentUser();
final attributes = await Amplify.Auth.fetchUserAttributes();
```

**수정 후**:
```dart
final attributes = await Amplify.Auth.fetchUserAttributes();
```

**이유**: `authUser` 변수가 사용되지 않음 (이메일만 필요)

---

### 경고 2: Unnecessary braces in string interpolation

**위치**: 207줄

**기존**:
```dart
'만료: ${daysLeft}일 후'
```

**수정 후**:
```dart
'만료: $daysLeft일 후'
```

**이유**: 단순 변수 출력 시 중괄호 불필요

---

## ✅ 완료 체크리스트

- [x] NoAcademyShell을 StatefulWidget으로 변환
- [x] State 변수 추가 (_invitations, _academyNames, _isLoading, _userEmail)
- [x] initState에서 _loadInvitations() 호출
- [x] _loadInvitations() 구현 (Cognito 이메일 조회 + 초대 목록 + 학원명)
- [x] _acceptInvitation() 구현 (AcademyMember 생성 + Invitation 사용 처리)
- [x] _getRoleName() 구현 (역할 코드 → 한글명)
- [x] _buildInvitationList() 구현 (로딩/없음/목록 조건부 렌더링)
- [x] _buildInvitationCard() 구현 (학원명, 역할, 만료일, 수락/거절 버튼)
- [x] build() 메서드에 초대 목록 추가
- [x] IDE 경고 수정 (unused variable, unnecessary braces)
- [x] flutter analyze 0 에러
- [x] 로그 추가 (safePrint)
- [x] mounted 체크 (SnackBar, Navigator)

---

## 📝 코드 통계

| 항목 | 수량 |
|------|------|
| 수정된 파일 | 1개 |
| 기존 코드 줄 | 153줄 |
| 수정 후 코드 줄 | 387줄 |
| 증가 | +234줄 |
| 추가된 import | 4개 |
| 추가된 State 변수 | 5개 |
| 추가된 메서드 | 6개 |
| flutter analyze 에러 | 0개 |

---

## 🔜 다음 단계 (TASK_017)

**예정 작업**: 원장 UI에서 초대 생성 기능 구현

**목표**:
- InvitationManagementPage에서 "이메일로 초대 생성" 버튼 추가
- 이메일 입력 다이얼로그
- InvitationService.createInvitation(targetEmail: email) 호출
- 생성된 초대 목록 표시

**전체 플로우 테스트**:
```
1. 원장이 "student@example.com"으로 학생 초대 생성
   ↓
2. student@example.com 이메일로 가입한 유저가 로그인
   ↓
3. NoAcademyShell 진입
   ↓
4. 자동으로 초대 목록 표시 (1개)
   ↓
5. "수락" 클릭
   ↓
6. AcademyMember 생성 → StudentShell로 자동 이동
```

---

## 📝 참고사항

### TODO 남은 작업

**위치**: 219줄

```dart
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
```

**현재 동작**: 목록에서만 제거 (임시)

**향후 작업**:
- Invitation.status = 'rejected' 필드 추가?
- 또는 그냥 usedBy를 특수값으로 설정?
- 또는 삭제?

---

## 📚 사용된 기술

| 기술 | 용도 |
|------|------|
| StatefulWidget | 상태 관리 (초대 목록, 로딩) |
| Amplify.Auth.fetchUserAttributes() | Cognito 유저 이메일 조회 |
| InvitationService.getInvitationsByTargetEmail() | 이메일로 초대 조회 |
| Amplify.DataStore.query() | Academy 조회 (학원명) |
| AcademyMemberService.createMemberFromInvitation() | 멤버 생성 |
| InvitationService.useInvitation() | 초대 사용 처리 |
| SnackBar | 성공/실패 메시지 |
| context.go('/home') | 라우팅 |
| mounted 체크 | 위젯 생명주기 안전성 |
| safePrint | 로깅 |

---

**✅ TASK_016 완료 - NoAcademyShell 초대 목록 UI 구현 성공**
