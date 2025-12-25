# BIG_093: 초대 수락 자동 화면 전환 최종 테스트

> 생성일: 2025-12-25
> 목표: Cognito 세션 강제 새로고침 적용 후 테스트

---

## 🎯 기대 결과

- 초대 수락 후 **재로그인 없이** 바로 학원 홈 화면으로 자동 이동
- 로그에 `[AuthState] Cognito 세션 강제 새로고침 완료` 출력

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 로그 파일: ai_bridge/logs/realtime.log (마지막 100줄만 유지)
- 테스트 계정:
  - 초대자: owner_test1
  - 피초대자: maknae12@gmail.com (AppUser ID: a498ad1c-6011-70c6-2f00-92a2fad64b02)

---

## 스몰스텝

### 1. 테스트 계정 리셋

**Invitation 삭제:**
```bash
aws dynamodb scan --table-name Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "inviteeEmail = :email" --expression-attribute-values '{":email":{"S":"maknae12@gmail.com"}}' --region ap-northeast-2 --query "Items[*].id.S" --output text
```
→ ID 나오면:
```bash
aws dynamodb delete-item --table-name Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --key '{"id":{"S":"ID값"}}' --region ap-northeast-2
```

**AcademyMember 삭제:**
```bash
aws dynamodb scan --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "userId = :uid" --expression-attribute-values '{":uid":{"S":"a498ad1c-6011-70c6-2f00-92a2fad64b02"}}' --region ap-northeast-2 --query "Items[*].id.S" --output text
```
→ ID 나오면:
```bash
aws dynamodb delete-item --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --key '{"id":{"S":"ID값"}}' --region ap-northeast-2
```

### 2. 앱 빌드 + 실시간 로그 (마지막 100줄만)

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter run -d RFCY40MNBLL 2>&1 | tail -100 > ../ai_bridge/logs/realtime.log &
flutter run -d RFCY40MNBLL
```

또는 PowerShell:
```powershell
flutter run -d RFCY40MNBLL 2>&1 | Tee-Object -FilePath ../ai_bridge/logs/realtime.log
```

### 3. CP한테 알려주기

앱 실행되면 CP한테 알려줘. CP가 직접 테스트함:
1. owner_test1로 초대 발송
2. maknae12@gmail.com으로 수락
3. 자동 화면 전환 확인

---

## 확인할 로그

```
[AuthState] refreshAuth 호출
[AuthState] Cognito 세션 강제 새로고침 완료   ← 새로 추가된 로그!
[AuthState] 로드 완료: user=최우준, role=..., academy=...
[NoAcademyShell] 홈 화면 전환 실행
```

---

## 완료 조건

1. 테스트 계정 리셋 완료
2. 앱 실행 완료
3. CP 테스트 대기
