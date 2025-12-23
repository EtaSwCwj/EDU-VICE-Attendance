# BIG_079: 초대 시스템 검증 및 테스트

> 생성일: 2025-12-23
> 목표: BIG_078에서 구현한 초대 시스템 검증 + 실제 테스트

---

## ⚠️ 필수: Opus는 직접 작업 금지!
가급적 코드/파일 작업은 Sonnet 호출해서 시킬 것.

### Sonnet 호출 방법
```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

### 예외 (Opus가 직접 해도 되는 것)
- AWS CLI (인증 필요)
- 시스템 환경변수 접근

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- Flutter 앱: flutter_application_1/
- 테스트 계정: maknae12@gmail.com

---

## 스몰스텝 (진행 시 체크박스 업데이트!)

### 1. 테스트 계정 초기화
- [ ] maknae12@gmail.com의 AcademyMember 레코드 삭제
- [ ] GraphQL API로 확인 (listAcademyMembers where userId = ?)

### 2. AWS SES 설정 확인 및 설정
- [ ] SES 샌드박스 상태 확인
- [ ] 발신자 이메일 인증 (noreply@... 또는 다른 이메일)
- [ ] 테스트용 수신자 이메일 인증 (maknae12@gmail.com)
- [ ] Lambda 역할에 SES 권한 확인

### 3. 구현 연결 확인
- [ ] QR 토큰 유틸 import 확인 (설정 페이지)
- [ ] QR 생성 버튼 → 다이얼로그 연결 확인
- [ ] QR 스캔 버튼 → 카메라 연결 확인
- [ ] 스캔 → DB 조회 → 확인 다이얼로그 플로우 확인

### 4. Lambda 연결 확인
- [ ] Invitation 테이블 DynamoDB 스트림 활성화 확인
- [ ] Lambda 트리거 연결 확인
- [ ] amplify push 필요 여부 확인

### 5. flutter analyze 경고 수정
- [ ] BuildContext 비동기 사용 경고 수정 (mounted 체크)
- [ ] 불필요한 null 체크 제거
- [ ] flutter analyze 재실행 → 경고 0개 목표

### 6. 실제 테스트 (폰에서)
- [ ] 앱 빌드 후 폰 설치
- [ ] 계정 A: 설정 → "내 QR 코드" 표시
- [ ] 계정 B(원장): 멤버 관리 → QR 스캔
- [ ] 스캔 결과 확인 다이얼로그 뜨는지 확인
- [ ] 초대 완료 시 AcademyMember 생성 확인
- [ ] 초대 메일 발송 확인 (SES 설정 완료 시)

---

## 검증 규칙 (v7.3)

- 에러 메시지만 보고 실패 판정 금지
- 실제 프로세스/화면 확인 후 판정

---

## 로그 저장

각 스몰스텝 완료 시:
- ai_bridge/logs/big_079_step_XX.log

---

## 완료 조건

1. 테스트 계정 초기화 완료
2. SES 설정 완료 (또는 설정 방법 CP에게 안내)
3. 구현 연결 모두 확인
4. flutter analyze 경고 0개
5. 실제 QR 스캔 테스트 성공
6. CP가 "테스트 종료" 입력
7. 보고서 작성 완료 (ai_bridge/report/big_079_report.md)
