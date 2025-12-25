# BIG_094: 프로그래매틱 재로그인 방식 테스트

> 생성일: 2025-12-25
> 목표: 초대 수락 후 재로그인 방식으로 학원 화면 자동 전환 테스트

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
- 초대 수락 → 2초 대기 → 자동 재로그인 → 학원 홈 화면 이동
- 사용자 입장에서 자연스러운 화면 전환

### 테스트 시나리오
```
1. owner_test1 로그인 → maknae12@gmail.com 초대 발송 → 로그아웃
2. maknae12@gmail.com 로그인 (자동 로그인 체크!)
3. "수락" 버튼 클릭
4. 잠시 로딩 후 학원 홈 화면으로 자동 이동
```

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
# Invitation 조회 및 삭제
aws dynamodb scan --table-name Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "inviteeEmail = :email" --expression-attribute-values '{":email":{"S":"maknae12@gmail.com"}}' --region ap-northeast-2 --query "Items[*].id.S" --output text

# 있으면 삭제 (ID 바꿔서)
aws dynamodb delete-item --table-name Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --key '{"id":{"S":"ID값"}}' --region ap-northeast-2

# AcademyMember 조회 및 삭제
aws dynamodb scan --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "userId = :uid" --expression-attribute-values '{":uid":{"S":"a498ad1c-6011-70c6-2f00-92a2fad64b02"}}' --region ap-northeast-2 --query "Items[*].id.S" --output text

# 있으면 삭제 (ID 바꿔서)
aws dynamodb delete-item --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --key '{"id":{"S":"ID값"}}' --region ap-northeast-2
```

### 2. 앱 빌드 + 로그 저장

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter run -d RFCY40MNBLL 2>&1 | tee ../ai_bridge/logs/realtime.log
```

### 3. CP한테 알려주기

앱 실행되면 CP한테 알려줘. CP가 직접 테스트함.

### 4. 테스트 완료 후 로그 분석

```bash
grep "\[LOG\]" ../ai_bridge/logs/realtime.log
```

---

## 확인할 핵심 로그

```
[LOG] 수락 버튼 클릭
[LOG] Invitation 업데이트 완료
[LOG] Lambda 완료 대기 중...
[LOG] 프로그래매틱 재로그인 시작
[LOG] 로그인 성공: maknae12@gmail.com
[LOG] 재로그인 성공 → 홈 화면 전환
```

---

## 성공 조건

1. 수락 클릭 후 학원 홈 화면으로 자동 이동
2. 재로그인 없이 (사용자 입장에서) 자연스러운 전환
3. 로그에서 `재로그인 성공 → 홈 화면 전환` 확인

---

## 완료 조건

1. 테스트 계정 리셋 완료
2. 앱 실행 완료
3. CP 테스트 → 성공/실패 확인
4. [LOG] 로그 캡쳐
5. 보고서 작성 (ai_bridge/report/big_094_report.md)
