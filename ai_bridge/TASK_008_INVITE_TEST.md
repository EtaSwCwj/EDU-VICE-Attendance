# TASK_008: 초대 시스템 UI 연결 및 테스트

> **작성자**: 윈 선임 (Opus)  
> **작성일**: 2025-12-20  
> **담당**: 윈 후임 (Sonnet)  
> **원칙**: 묻지 말고 끝까지 진행. 로그 필수. 앱 종료 = 테스트 끝.

---

## 📋 현재 상태

- InvitationManagementPage 구현됨 (TASK_002)
- 라우터에 `/invitations/:academyId` 등록됨
- **문제**: OwnerHomeShell/OwnerManagementPage에서 초대 관리 페이지로 가는 버튼 없음

---

## 📋 작업 내용

### 1단계: OwnerManagementPage에 초대 관리 탭 추가

**파일**: `lib/features/owner/pages/owner_management_page.dart`

현재 3개 탭 → 4개 탭으로 변경:
- 선생 관리
- 학생 관리
- 배정 관리
- **초대 관리 (추가)**

TabController length 3 → 4로 변경.

4번째 탭에 InvitationManagementPage 추가.

로그: `[OwnerManagementPage] 초대 관리 탭 진입`

---

### 2단계: Import 추가

```dart
import '../../invitation/invitation_management_page.dart';
```

---

### 3단계: 테스트 플로우

1. **owner_test1 로그인** → OwnerHomeShell
2. **관리 탭** → OwnerManagementPage
3. **초대 관리 탭** → InvitationManagementPage
4. **초대코드 생성** (역할: student)
5. **생성된 코드 메모**
6. **로그아웃**
7. **maknae12@gmail.com 로그인** → NoAcademyShell
8. **"초대코드로 참여하기" 클릭** → JoinByCodePage
9. **초대코드 입력**
10. **AcademyMember 생성 → StudentShell 진입**

모든 단계에서 터미널 로그 확인.

---

### 4단계: 로그 확인 포인트

```
[InvitationManagementPage] 초대 생성: role=student
[InvitationService] Creating invitation...
[InvitationService] Invitation created: code=XXXXXX

[JoinByCodePage] 초대코드 입력: XXXXXX
[InvitationService] Looking up invitation...
[AcademyMemberService] Creating member...
[JoinByCodePage] 성공적으로 참여

[AuthState] 역할 판단 시작
[AuthState] AcademyMember 조회 결과: 있음
[AuthState] 최종 role: student
```

---

## ✅ 완료 체크리스트

- [ ] OwnerManagementPage에 초대 관리 탭 추가
- [ ] flutter analyze 0 에러
- [ ] owner_test1 로그인 → 초대 관리 탭 보이는지 확인
- [ ] 초대코드 생성 (역할: student)
- [ ] maknae12@gmail.com으로 초대코드 입력
- [ ] AcademyMember 생성 확인 (로그)
- [ ] StudentShell 진입 확인

---

## 📝 완료 보고

`C:\github\ai_bridge\task_008_result.md`에 결과 작성:

```markdown
# TASK_008 완료 보고

**상태**: ✅ 완료 / ❌ 실패

## 1. 코드 수정 내용
- 파일: ???
- 변경 사항: ???

## 2. flutter analyze
(결과)

## 3. 테스트 로그 (전체)
```
(터미널 로그 전체 붙여넣기)
```

## 4. 테스트 결과
- owner_test1 초대코드 생성: ✅/❌
- 생성된 코드: XXXXXX
- maknae12@gmail.com 초대코드 입력: ✅/❌
- AcademyMember 생성: ✅/❌
- StudentShell 진입: ✅/❌

## 5. 이슈
(있으면 작성)
```
