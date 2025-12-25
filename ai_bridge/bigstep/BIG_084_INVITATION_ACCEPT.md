# BIG_084: 초대 수락 플로우 구현

> 생성일: 2025-12-23
> 목표: NoAcademyShell에서 받은 초대 목록 표시 + 수락 시 AcademyMember 생성

---

## ⚠️ 작성 전 체크리스트 (Desktop Opus 필수 확인!)

### 기본 확인
- [x] 로컬 코드 확인함 (no_academy_shell.dart, invitation_service.dart)
- [x] InvitationService.getInvitationsByTargetEmail() 이미 존재
- [x] 수정할 파일: no_academy_shell.dart

### 테스트 환경
- [x] 테스트 계정: maknae12@gmail.com (초대 받은 상태)
- [x] Invitation 레코드 존재 확인됨 (status: pending)

### 플로우 확인
- [x] 진입 경로: 로그인 → AcademyMember 없음 → NoAcademyShell
- [x] 초대 수락 → AcademyMember 생성 → refreshAuth() → 홈으로 이동

---

## ⚠️ 필수: Opus는 직접 작업 금지!

### Sonnet 호출 방법
```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

---

## 환경

- 프로젝트: ~/gitproject/EDU-VICE-Attendance
- Flutter 앱: flutter_application_1/
- 수정 파일: lib/features/home/no_academy_shell.dart
- 테스트 계정: maknae12@gmail.com

---

## 스몰스텝

### 1. no_academy_shell.dart 수정

**수정 내용:**
1. StatelessWidget → StatefulWidget 변환
2. initState에서 초대 목록 조회 (getInvitationsByTargetEmail)
3. 초대 목록 UI 추가 (리스트로 표시)
4. 수락 버튼 클릭 → AcademyMember 생성 → Invitation status='accepted' 업데이트 → refreshAuth()

**필요한 import:**
```dart
import '../../shared/services/invitation_service.dart';
import '../../models/ModelProvider.dart';
```

**UI 구조:**
```
[기존 UI - 이메일/QR]

--- 받은 초대 ---
| 학원명 | 역할 | [수락] [거절] |
| 학원명 | 역할 | [수락] [거절] |
```

**수락 로직:**
1. AcademyMember 생성 (GraphQL mutation)
2. Invitation.status = 'accepted', usedAt = now, usedBy = userId
3. auth.refreshAuth() 호출
4. 자동으로 홈 화면 이동

### 2. flutter analyze
- [ ] 에러/경고 0개 확인

### 3. 테스트
- [ ] flutter run -d [디바이스ID]
- [ ] maknae12@gmail.com 로그인
- [ ] NoAcademyShell에서 받은 초대 목록 표시 확인
- [ ] 수락 버튼 클릭 → OwnerHomeShell 또는 StudentHomeShell로 이동 확인
- [ ] DynamoDB에서 AcademyMember 생성 확인

---

## 검증 규칙

- 에러 메시지만 보고 실패 판정 금지
- 실제 화면/동작 확인 후 판정

---

## ⚠️ 코드 작성 시 주의

- DataStore 사용 금지 → GraphQL API 사용
- safePrint 로그 필수 추가
- 학원명 조회 시 Academy 테이블에서 가져올 것

---

## 완료 조건

1. NoAcademyShell에서 받은 초대 목록 표시
2. 수락 시 AcademyMember 생성 + Invitation 업데이트
3. 수락 후 자동으로 홈 화면 이동
4. flutter analyze 에러 0개
5. CP가 "테스트 종료" 입력
6. 보고서 작성 (ai_bridge/report/big_084_report.md)
