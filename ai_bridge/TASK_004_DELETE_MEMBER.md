# TASK_004: AcademyMember 데이터 삭제

> **작성자**: 윈 선임 (Opus)  
> **작성일**: 2025-12-20  
> **담당**: 윈 후임 (Sonnet)  
> **원칙**: 묻지 말고 끝까지 진행.

---

## 📋 작업 내용

maknae12@gmail.com 유저의 AcademyMember 데이터 삭제해서 "소속 없음" 상태로 만들기.

---

## 작업 순서

### 1. AppUser에서 userId 찾기

```bash
# AppUser 테이블에서 maknae12@gmail.com 조회
aws dynamodb scan \
  --table-name AppUser-3ozlrdq2pvesbe2mcnxgs5e6nu-dev \
  --filter-expression "email = :email" \
  --expression-attribute-values '{":email":{"S":"maknae12@gmail.com"}}' \
  --query "Items[0].id.S" --output text
```

userId 메모해둬.

---

### 2. AcademyMember에서 해당 유저 조회

```bash
# AcademyMember 테이블 이름 확인
aws dynamodb list-tables --query "TableNames[?contains(@, 'AcademyMember')]" --output table

# 해당 유저의 AcademyMember 조회
aws dynamodb scan \
  --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev \
  --filter-expression "userId = :userId" \
  --expression-attribute-values '{":userId":{"S":"[위에서_찾은_userId]"}}'
```

조회된 항목의 `id` 메모해둬.

---

### 3. AcademyMember 삭제

```bash
aws dynamodb delete-item \
  --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev \
  --key '{"id":{"S":"[조회된_AcademyMember_id]"}}'
```

---

### 4. 확인

```bash
# 삭제 확인
aws dynamodb scan \
  --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev \
  --filter-expression "userId = :userId" \
  --expression-attribute-values '{":userId":{"S":"[userId]"}}'
```

Count: 0 나오면 성공.

---

## ✅ 완료 체크리스트

- [ ] AppUser에서 userId 조회
- [ ] AcademyMember에서 해당 유저 데이터 조회
- [ ] AcademyMember 삭제
- [ ] 삭제 확인 (Count: 0)

---

## 📝 완료 보고

`C:\github\ai_bridge\task_004_result.md`에 결과 작성:

```markdown
# TASK_004 완료 보고

**상태**: ✅ 완료

## 삭제된 데이터
- userId: [값]
- AcademyMember id: [값]
- 삭제 확인: Count 0 ✅
```
