# TASK_015: InvitationService에 getByEmail 추가

> **작성자**: 윈선임 (메인 개발 4)
> **작성일**: 2025-12-21
> **담당**: 윈후임 (Sonnet)
> **결과 파일**: `C:\github\ai_bridge\task_015_result.md`
> **원칙**: 묻지 말고 끝까지 진행. 로그 필수.

---

## 📋 배경

현재 초대 시스템이 "랜덤 코드 입력" 방식으로 구현되어 있음.
올바른 플로우는 "원장이 이메일로 초대 → 피초대자 앱에서 초대 목록 확인"임.

이를 위해 이메일로 초대 목록을 조회하는 메서드가 필요함.

---

## 📋 작업 내용

### 파일: `lib/shared/services/invitation_service.dart`

### 추가할 메서드

```dart
/// 이메일로 받은 초대 목록 조회 (피초대자용)
Future<List<Invitation>> getInvitationsByTargetEmail(String email) async {
  safePrint('[InvitationService] Fetching invitations for email: $email');

  try {
    final invitations = await Amplify.DataStore.query(
      Invitation.classType,
      where: Invitation.TARGETEMAIL.eq(email.toLowerCase()),
    );

    // 유효한 초대만 필터링 (만료 안 됨 + 사용 안 됨)
    final validInvitations = invitations.where((inv) {
      final notExpired = inv.expiresAt.getDateTimeInUtc().isAfter(DateTime.now().toUtc());
      final notUsed = inv.usedAt == null;
      return notExpired && notUsed;
    }).toList();

    safePrint('[InvitationService] Found ${validInvitations.length} valid invitations for $email');
    return validInvitations;
  } catch (e) {
    safePrint('[InvitationService] Error fetching invitations by email: $e');
    return [];
  }
}
```

### 위치

기존 `getInvitationsByAcademy` 메서드 아래에 추가.

---

## 📝 전체 파일 구조 (수정 후)

```dart
class InvitationService {
  // ... 기존 코드 ...

  /// 초대코드로 초대 조회
  Future<Invitation?> getInvitationByCode(String code) async { ... }

  /// 초대 사용 처리
  Future<bool> useInvitation(...) async { ... }

  /// 학원의 초대 목록 조회 (원장용)
  Future<List<Invitation>> getInvitationsByAcademy(String academyId) async { ... }

  /// 이메일로 받은 초대 목록 조회 (피초대자용) ← 신규
  Future<List<Invitation>> getInvitationsByTargetEmail(String email) async { ... }
}
```

---

## 📝 테스트 방법

코드 추가 후 flutter analyze만 확인.
실제 동작 테스트는 TASK_016 (NoAcademyShell UI)에서 진행.

```bash
cd C:\github\EDU-VICE-Attendance\flutter_application_1
flutter analyze
```

---

## ✅ 완료 체크리스트

- [ ] `getInvitationsByTargetEmail` 메서드 추가
- [ ] 이메일 소문자 변환 처리 (.toLowerCase())
- [ ] 만료/사용 필터링 로직 포함
- [ ] 로그 추가
- [ ] flutter analyze 0 에러

---

## 📝 결과 보고 템플릿

```markdown
# TASK_015 결과: InvitationService getByEmail 추가

## 작업 내용
- 수정한 파일:
- 추가한 메서드:

## flutter analyze
- 에러:
- 경고:

## 완료 체크리스트
- [ ] getInvitationsByTargetEmail 추가
- [ ] flutter analyze 0 에러
```

---

**완료 후 `C:\github\ai_bridge\task_015_result.md`에 결과 저장할 것.**
