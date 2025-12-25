# TASK_005: AWS DynamoDB 전체 테이블 덤프

> **작성자**: 윈 선임 (Opus)  
> **작성일**: 2025-12-20  
> **담당**: 윈 후임 (Sonnet)  
> **원칙**: 묻지 말고 끝까지 진행.

---

## 📋 작업 내용

모든 DynamoDB 테이블 데이터를 덤프해서 보고서에 첨부.

---

## 작업 순서

### 1. 테이블 목록 확인

```bash
aws dynamodb list-tables --output table
```

---

### 2. 각 테이블 전체 스캔

아래 테이블들 전부 스캔해서 결과 저장:

```bash
# AppUser
aws dynamodb scan --table-name AppUser-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --output json > appuser_dump.json

# AcademyMember
aws dynamodb scan --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --output json > academymember_dump.json

# Academy
aws dynamodb scan --table-name Academy-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --output json > academy_dump.json

# Invitation (있으면)
aws dynamodb scan --table-name Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --output json > invitation_dump.json

# StudentSupporter (있으면)
aws dynamodb scan --table-name StudentSupporter-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --output json > studentsupporter_dump.json
```

없는 테이블은 스킵.

---

### 3. Cognito 유저 목록도 확인

```bash
aws cognito-idp list-users --user-pool-id ap-northeast-2_SExWRqKCB --output json > cognito_users.json
```

---

## 📝 완료 보고

`C:\github\ai_bridge\task_005_result.md`에 각 테이블 내용 전부 붙여넣기:

```markdown
# TASK_005: DB 덤프 결과

## Cognito Users
(cognito_users.json 내용)

## AppUser 테이블
(appuser_dump.json 내용)

## AcademyMember 테이블
(academymember_dump.json 내용)

## Academy 테이블
(academy_dump.json 내용)

## Invitation 테이블
(invitation_dump.json 내용 또는 "테이블 없음")

## StudentSupporter 테이블
(studentsupporter_dump.json 내용 또는 "테이블 없음")
```

JSON 그대로 붙여넣어. 내가 분석할게.
