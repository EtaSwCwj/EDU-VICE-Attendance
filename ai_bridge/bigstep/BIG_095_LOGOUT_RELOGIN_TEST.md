# BIG_095: 초대 수락 후 로그아웃→재로그인 방식 테스트

> 생성일: 2025-12-25
> 목표: 초대 수락 후 로그아웃 → 자동 로그인으로 학원 화면 진입

---

## 🎯 기대 결과

1. 수락 클릭
2. 2초 로딩
3. "초대를 수락했습니다! 다시 로그인해주세요." 메시지
4. 로그인 화면으로 이동
5. 자동 로그인 → 학원 홈 화면

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 로그 파일: ai_bridge/logs/realtime.log
- 테스트 계정:
  - 초대자: owner_test1
  - 피초대자: maknae12@gmail.com (ID: a498ad1c-6011-70c6-2f00-92a2fad64b02)

---

## 스몰스텝

### 1. 테스트 계정 리셋

```bash
# Invitation 삭제
aws dynamodb scan --table-name Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "inviteeEmail = :email" --expression-attribute-values '{":email":{"S":"maknae12@gmail.com"}}' --region ap-northeast-2 --query "Items[*].id.S" --output text

# 있으면 삭제
aws dynamodb delete-item --table-name Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --key '{"id":{"S":"ID값"}}' --region ap-northeast-2

# AcademyMember 삭제
aws dynamodb scan --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "userId = :uid" --expression-attribute-values '{":uid":{"S":"a498ad1c-6011-70c6-2f00-92a2fad64b02"}}' --region ap-northeast-2 --query "Items[*].id.S" --output text

# 있으면 삭제
aws dynamodb delete-item --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --key '{"id":{"S":"ID값"}}' --region ap-northeast-2
```

### 2. 앱 빌드 + 로그 저장

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter run -d RFCY40MNBLL 2>&1 | tee ../ai_bridge/logs/realtime.log
```

### 3. CP 테스트

앱 실행되면 CP한테 알려줘. CP가 직접 테스트:
1. owner_test1 로그인 → 초대 발송 → 로그아웃
2. maknae12 로그인 (자동 로그인 체크!)
3. 수락 클릭
4. 로그인 화면 → 자동으로 학원 홈 이동 확인

### 4. 로그 확인

```bash
grep "\[LOG\]" ../ai_bridge/logs/realtime.log
```

---

## 확인할 핵심 로그

```
[LOG] 수락 버튼 클릭
[LOG] Invitation 업데이트 완료
[LOG] Lambda 완료 대기 중...
[LOG] 초대 수락 완료 → 로그인 화면으로 이동
[LOG] 로그아웃
[LOG] 로그인 성공: maknae12@gmail.com
```

---

## 성공 조건

1. 수락 후 로그인 화면으로 이동
2. 자동 로그인으로 학원 홈 진입
3. StudentShell 또는 TeacherShell 정상 표시

---

## 완료 후

보고서: ai_bridge/report/big_095_report.md
