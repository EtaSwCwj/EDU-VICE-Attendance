# BIG_078: 초대 시스템 구현

> 생성일: 2025-12-23
> 목표: QR 기반 초대 + 이메일 발송 시스템 구현

---

## 배경

원장이 선생님/학생을 초대하는 시스템 구현
- QR 스캔으로 유저 정보 자동 입력
- 이메일 직접 입력도 가능
- AWS SES로 초대 메일 발송
- 초대 수락은 웹페이지 (별도 빅스텝)

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- Flutter 앱: flutter_application_1/
- 백엔드: AWS Amplify (GraphQL, Lambda, SES)

---

## 스몰스텝

### 1. AWS SES 상태 확인
- AWS CLI로 SES 샌드박스 상태 확인
- 발신 이메일 인증 여부 확인
- Lambda에서 SES 호출 권한 확인
- 결과 보고 (설정 필요하면 CP에게 알림)

### 2. Invitation 스키마 추가
- amplify/backend/api 에서 schema.graphql 수정
- Invitation 모델 추가:
  ```graphql
  type Invitation @model @auth(...) {
    id: ID!
    academyId: ID!
    inviterUserId: ID!      # 초대한 사람 (원장)
    inviteeEmail: String!   # 초대받은 사람 이메일
    inviteeUserId: ID       # 초대받은 사람 userId (DB에 있으면)
    role: String!           # teacher / student
    status: String!         # pending / accepted / rejected / expired
    expiresAt: AWSDateTime!
    createdAt: AWSDateTime
    updatedAt: AWSDateTime
  }
  ```
- `amplify codegen models` 실행

### 3. QR 토큰 생성/복호화 유틸
- lib/shared/utils/qr_token_util.dart 생성
- AES 암호화로 userId 암호화/복호화
- 패키지: `encrypt` 사용
- 토큰 형식: AES(userId + timestamp)

### 4. QR 생성 UI (프로필/설정 페이지)
- 설정 페이지에 "내 QR 코드" 버튼 추가
- QR 코드 표시 다이얼로그
- 패키지: `qr_flutter` 사용
- QR 내용: 암호화된 토큰

### 5. QR 스캔 UI (원장 앱)
- 원장 홈/멤버관리에 "QR 스캔" 버튼 추가
- 카메라로 QR 스캔
- 패키지: `mobile_scanner` 사용
- 스캔 → 토큰 복호화 → DB 조회 → 확인 다이얼로그

### 6. 초대 메일 발송 (Lambda + SES)
- Lambda 함수 생성 또는 수정
- Invitation 생성 시 트리거
- SES로 초대 메일 발송
- 메일 내용: 학원명, 역할, 수락 링크

---

## Sonnet 호출 방법

```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "..."
```

---

## 주의사항

- 각 스몰스텝 완료 후 로그 저장 (ai_bridge/logs/big_078_step_XX.log)
- SES 설정 안 되어있으면 CP에게 보고 후 대기
- flutter analyze 에러 없이 완료할 것
- 웹 플랫폼 호환성 체크 (QR 스캔은 모바일만)

---

## 검증 규칙 (v7.3)

- 에러 메시지만 보고 실패 판정 금지
- 실제 동작 확인 후 판정

---

## 완료 조건

1. SES 상태 확인 완료
2. Invitation 스키마 추가 + codegen 완료
3. QR 토큰 유틸 구현
4. QR 생성 UI 동작
5. QR 스캔 UI 동작
6. 초대 메일 발송 동작
7. flutter analyze 에러 없음
8. CP가 "테스트 종료" 입력
9. 보고서 작성 완료 (ai_bridge/report/big_078_report.md)
