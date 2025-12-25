# BIG_085: 초대 시스템 디버깅

> 생성일: 2025-12-25
> 목표: 초대 메일 발송 + 받은 초대 목록 조회 문제 해결

---

## 문제 상황

1. owner_test1로 maknae12@gmail.com한테 초대 발송함
2. 메일 안 옴 (SES 미구현이라 정상)
3. **maknae12@gmail.com으로 로그인해도 받은 초대 목록 없음** ← 이게 문제!

---

## ⚠️ 필수: Opus는 직접 작업 금지!

### Sonnet 호출 방법
```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

### 예외 (Opus가 직접 해도 되는 것)
- AWS CLI (인증 필요)

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- 테스트 계정: maknae12@gmail.com (AppUser ID: a498ad1c-6011-70c6-2f00-92a2fad64b02)

---

## 스몰스텝

### 1. Invitation 테이블 데이터 확인 (Opus가 AWS CLI로 직접)

```bash
aws dynamodb scan --table-name Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2
```

**확인할 것:**
- maknae12@gmail.com으로 보낸 초대가 있는지?
- inviteeEmail 값이 정확한지? (대소문자 주의!)
- status가 'pending'인지?

### 2. 앱 빌드 & 로그 확인

- [ ] Sonnet: flutter run -d RFCY40MNBLL
- [ ] maknae12@gmail.com으로 로그인
- [ ] 로그에서 확인:
  - `[NoAcademyShell] 초대 목록 조회 시작:` 뜨는지?
  - `[InvitationService] Fetching invitations for email:` 뜨는지?
  - `[InvitationService] GraphQL errors:` 에러 있는지?
  - `[InvitationService] Found X valid invitations` 몇 개인지?

### 3. 원인 분석

**가능한 원인들:**
1. Invitation 테이블에 데이터가 없음 (발송 실패)
2. inviteeEmail 대소문자 불일치 (DB: Maknae12@gmail.com vs 조회: maknae12@gmail.com)
3. GraphQL query 문법 오류
4. status 필터 문제

### 4. 수정 및 재테스트

원인에 따라 수정 후 재테스트

---

## ⚠️ Opus 필수: 로그 직접 확인!

**보고서만 읽지 말고, Flutter 콘솔 로그 직접 확인!**

---

## 로그 저장 (필수!)

- [ ] ai_bridge/logs/big_085_step_01.log (DynamoDB 조회 결과)
- [ ] ai_bridge/logs/big_085_step_02.log (Flutter 로그)

---

## 완료 조건

1. 문제 원인 파악
2. 수정 완료
3. maknae12@gmail.com 로그인 시 받은 초대 목록 표시됨
4. CP가 "테스트 종료" 입력
5. 보고서 작성 완료
