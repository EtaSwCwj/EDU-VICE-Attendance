# BIG_086: 테스트 계정 리셋 (maknae12@gmail.com)

> 생성일: 2025-12-25
> 목표: maknae12@gmail.com 관련 AcademyMember, Invitation 데이터 삭제

---

## ⚠️ 필수: Opus가 AWS CLI로 직접 실행!

이 작업은 코드 수정 없이 **AWS CLI로 데이터만 삭제**하는 작업.

---

## 환경

- 테스트 계정: maknae12@gmail.com
- AppUser ID: a498ad1c-6011-70c6-2f00-92a2fad64b02
- 테이블:
  - AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
  - Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev

---

## 스몰스텝 (Opus가 AWS CLI로 직접!)

### 1. AcademyMember 조회 및 삭제

```bash
aws dynamodb scan --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "userId = :uid" --expression-attribute-values '{":uid":{"S":"a498ad1c-6011-70c6-2f00-92a2fad64b02"}}' --region ap-northeast-2
```

- [ ] 조회 결과 확인
- [ ] 결과가 있으면 삭제:
```bash
aws dynamodb delete-item --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --key '{"id":{"S":"조회된ID"}}' --region ap-northeast-2
```
- [ ] 삭제 확인 (다시 scan해서 빈 결과)

### 2. Invitation 조회 및 삭제

```bash
aws dynamodb scan --table-name Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "inviteeEmail = :email" --expression-attribute-values '{":email":{"S":"maknae12@gmail.com"}}' --region ap-northeast-2
```

- [ ] 조회 결과 확인
- [ ] 결과가 있으면 각각 삭제:
```bash
aws dynamodb delete-item --table-name Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --key '{"id":{"S":"조회된ID"}}' --region ap-northeast-2
```
- [ ] 삭제 확인 (다시 scan해서 빈 결과)

---

## 로그 저장 (필수!)

- [ ] ai_bridge/logs/big_086_step_01.log (AcademyMember 조회/삭제)
- [ ] ai_bridge/logs/big_086_step_02.log (Invitation 조회/삭제)

---

## 완료 조건

1. AcademyMember 테이블에서 maknae12 데이터 없음
2. Invitation 테이블에서 maknae12 데이터 없음
3. 로그 파일 저장 완료
4. 보고서 작성 완료 (ai_bridge/report/big_086_report.md)
