# BIG_090: 초대 수락 후 자동 화면 전환 테스트

> 생성일: 2025-12-25
> 목표: BIG_089 수정 후 초대 수락 시 자동 화면 전환 테스트

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
- 초대 수락 성공 후 **재로그인 없이** 바로 학원 홈 화면으로 자동 이동

### 테스트 시나리오
```
1. owner_test1 로그인 → maknae12@gmail.com에게 초대 발송
2. 로그아웃 → maknae12@gmail.com으로 로그인
3. "받은 초대" 목록에 초대 표시됨
4. "수락" 버튼 클릭
5. 바로 학원 홈 화면으로 자동 이동! (재로그인 필요 없음)
```

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 테스트 계정:
  - 초대자: owner_test1 (수학의 정석 학원 원장)
  - 피초대자: maknae12@gmail.com (AppUser ID: a498ad1c-6011-70c6-2f00-92a2fad64b02)

---

## 스몰스텝

### 1. 테스트 계정 리셋 (AWS CLI)

**Invitation 삭제:**
```bash
aws dynamodb scan --table-name Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "inviteeEmail = :email" --expression-attribute-values '{":email":{"S":"maknae12@gmail.com"}}' --region ap-northeast-2
```
→ 결과 있으면:
```bash
aws dynamodb delete-item --table-name Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --key '{"id":{"S":"조회된ID"}}' --region ap-northeast-2
```

**AcademyMember 삭제:**
```bash
aws dynamodb scan --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "userId = :uid" --expression-attribute-values '{":uid":{"S":"a498ad1c-6011-70c6-2f00-92a2fad64b02"}}' --region ap-northeast-2
```
→ 결과 있으면:
```bash
aws dynamodb delete-item --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --key '{"id":{"S":"조회된ID"}}' --region ap-northeast-2
```

### 2. 앱 빌드

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter run -d RFCY40MNBLL
```

### 3. 초대 발송 (owner_test1)

- [ ] owner_test1로 로그인
- [ ] 이메일 검색으로 maknae12@gmail.com 찾기
- [ ] 초대 발송
- [ ] 로그아웃

### 4. 초대 수락 테스트 (maknae12@gmail.com)

- [ ] maknae12@gmail.com으로 로그인
- [ ] "받은 초대" 목록에 초대 표시 확인
- [ ] **"수락" 버튼 클릭**
- [ ] **바로 학원 홈 화면으로 자동 이동하는지 확인!**

### 5. 결과 확인

**성공 조건:**
- 수락 클릭 후 재로그인 없이 바로 학원 화면으로 이동

**실패 시 확인:**
- Flutter 콘솔 로그에서 `[NoAcademyShell] Navigator를 사용한 홈 화면 전환 실행` 확인
- 에러 메시지 확인

---

## 완료 조건

1. 테스트 계정 리셋 완료
2. 초대 발송 성공
3. 초대 수락 성공
4. **수락 후 바로 학원 홈 화면으로 자동 이동**
5. 보고서 작성 완료 (ai_bridge/report/big_090_report.md)
