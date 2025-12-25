# TASK_017: ai_bridge 이동 + 원장 초대 생성 UI 수정

> **작성자**: 윈선임 (메인 개발 4)
> **작성일**: 2025-12-21
> **담당**: 윈후임 (Sonnet)
> **결과 파일**: `C:\gitproject\EDU-VICE-Attendance\ai_bridge\task_017_result.md`
> **원칙**: 묻지 말고 끝까지 진행. 로그 필수.

---

## 📋 작업 A: ai_bridge 폴더 프로젝트로 이동

### 1단계: 폴더 복사

```cmd
xcopy /E /I C:\github\ai_bridge C:\gitproject\EDU-VICE-Attendance\ai_bridge
```

### 2단계: Git 추가

```bash
cd C:\gitproject\EDU-VICE-Attendance
git add ai_bridge
```

### 3단계: 확인

```bash
ls C:\gitproject\EDU-VICE-Attendance\ai_bridge\PROJECT_GUIDELINES.md
```

파일 존재하면 성공.

---

## 📋 작업 B: InvitationManagementPage 이메일 입력 추가

### 파일: `lib/features/invitation/invitation_management_page.dart`

---

### 변경 1: _showCreateDialog() 수정

**기존** (역할만 선택):
```dart
void _showCreateDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('초대 생성'),
      content: const Text('어떤 역할로 초대하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _createInvitation('teacher');
          },
          child: const Text('선생님'),
        ),
        // ...
      ],
    ),
  );
}
```

**수정 후** (이메일 + 역할 입력):
```dart
void _showCreateDialog() {
  final emailController = TextEditingController();
  String selectedRole = 'student';

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('초대 생성'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이메일 입력
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: '초대할 이메일',
                hintText: 'user@example.com',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            // 역할 선택
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
              _createInvitation(selectedRole, email);
            },
            child: const Text('초대하기'),
          ),
        ],
      ),
    ),
  );
}
```

---

### 변경 2: _createInvitation() 수정

**기존**:
```dart
Future<void> _createInvitation(String role) async {
```

**수정 후**:
```dart
Future<void> _createInvitation(String role, String targetEmail) async {
  safePrint('[InvitationManagementPage] Creating invitation: role=$role, email=$targetEmail');

  try {
    final authUser = await Amplify.Auth.getCurrentUser();

    final invitation = await _invitationService.createInvitation(
      academyId: widget.academyId,
      role: role,
      createdBy: authUser.userId,
      targetEmail: targetEmail,  // ← 추가
    );

    if (invitation != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$targetEmail에게 초대를 보냈습니다'),
          backgroundColor: Colors.green,
        ),
      );
      _loadInvitations();
    }
  } catch (e) {
    safePrint('[InvitationManagementPage] Error creating invitation: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('초대 생성 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
```

---

### 변경 3: 초대 목록 카드에 이메일 표시

기존 `ListTile`의 `subtitle` 수정:

**기존**:
```dart
subtitle: Text(
  '${_getRoleName(invitation.role)} • ${isUsed ? "사용됨" : isExpired ? "만료" : "유효"}',
),
```

**수정 후**:
```dart
subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    if (invitation.targetEmail != null)
      Text(
        invitation.targetEmail!,
        style: TextStyle(color: Colors.grey[600]),
      ),
    Text(
      '${_getRoleName(invitation.role)} • ${isUsed ? "사용됨" : isExpired ? "만료" : "유효"}',
    ),
  ],
),
```

---

### 변경 4: _showInvitationCode() 삭제 또는 수정

이제 코드 다이얼로그 대신 SnackBar만 보여주므로:
- `_showInvitationCode()` 메서드 삭제
- 또는 나중을 위해 남겨두기 (QR 용)

**삭제 권장** (사용 안 함)

---

## 📝 테스트 플로우 (코드 작성 후)

```
1. owner_test1 로그인
2. 관리 탭 → 초대 관리 탭
3. FAB "초대 생성" 클릭
4. 이메일: maknae12@gmail.com 입력
5. 역할: 학생 선택
6. "초대하기" 클릭
7. SnackBar: "maknae12@gmail.com에게 초대를 보냈습니다"
8. 초대 목록에 새 항목 표시
```

---

## 📝 flutter analyze

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze
```

0 에러 확인

---

## ✅ 완료 체크리스트

### 작업 A: ai_bridge 이동
- [ ] `C:\github\ai_bridge\` → `C:\gitproject\EDU-VICE-Attendance\ai_bridge\` 복사
- [ ] git add ai_bridge
- [ ] PROJECT_GUIDELINES.md 존재 확인

### 작업 B: 원장 초대 UI
- [ ] _showCreateDialog() 이메일 입력 폼 추가
- [ ] _createInvitation() targetEmail 파라미터 추가
- [ ] 초대 목록에 이메일 표시
- [ ] _showInvitationCode() 삭제 또는 주석
- [ ] flutter analyze 0 에러

---

## 📝 결과 보고 템플릿

```markdown
# TASK_017 결과

## 작업 A: ai_bridge 이동
- 복사 완료: O/X
- git add: O/X

## 작업 B: 원장 초대 UI
- 수정한 파일:
- 추가/변경한 메서드:

## flutter analyze
- 에러:
- 경고:

## 테스트 (옵션)
- 초대 생성 다이얼로그: 이메일 입력 폼 표시 여부
- 초대 생성 후: SnackBar 메시지

## 완료 체크리스트
- [ ] ai_bridge 이동
- [ ] 이메일 입력 폼
- [ ] flutter analyze 0 에러
```

---

**완료 후 `C:\gitproject\EDU-VICE-Attendance\ai_bridge\task_017_result.md`에 결과 저장할 것.**

**(주의: 경로가 바뀜! 프로젝트 안의 ai_bridge)**
