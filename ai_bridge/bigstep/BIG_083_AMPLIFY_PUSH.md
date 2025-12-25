# BIG_083: Invitation 테이블 생성 (amplify push)

> 생성일: 2025-12-23
> 목표: DynamoDB에 Invitation 테이블 생성 후 초대 기능 테스트

---

## ⚠️ 작성 전 체크리스트 (Desktop Opus 필수 확인!)

### 기본 확인
- [x] 로컬 코드 확인했나? → schema.graphql에 Invitation 모델 정의됨
- [x] Invitation.dart 모델 파일 존재 확인함
- [x] DynamoDB에 Invitation 테이블 없음 확인함 (커밋 메시지)

### 테스트 환경
- [ ] 테스트 계정 리셋 필요? → 아니오 (신규 테이블 생성만)
- [x] 빌드 필요한가? → amplify push 후 테스트 빌드

### 플로우 확인
- [x] 영향 범위: Invitation 테이블 신규 생성

### 의존성 확인
- [x] schema 변경? → 이미 반영됨 (BIG_082에서)
- [x] amplify codegen models → 이미 완료됨 (Invitation.dart 존재)

### 에러 케이스
- [ ] amplify push 실패 시 → 에러 로그 확인 후 재시도

---

## ⚠️ 필수: Opus는 직접 작업 금지!
가급적 코드/파일 작업은 Sonnet 호출해서 시킬 것.

### Sonnet 호출 방법
```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

### 예외 (Opus가 직접 해도 되는 것)
- AWS CLI (인증 필요)
- amplify push (인증 필요)

---

## 환경

- 프로젝트: ~/gitproject/EDU-VICE-Attendance (Mac)
- Flutter 앱: flutter_application_1/
- 테스트 계정: maknae12@gmail.com

---

## 스몰스텝 (진행 시 체크박스 업데이트!)

### 1. amplify push 실행

- [ ] 디렉토리 이동:
```bash
cd ~/gitproject/EDU-VICE-Attendance/flutter_application_1
```

- [ ] amplify push 실행:
```bash
amplify push --yes
```

- [ ] CloudFormation 스택 업데이트 완료 확인
- [ ] Invitation 테이블 생성 확인

### 2. DynamoDB 테이블 확인

- [ ] AWS 콘솔 또는 CLI로 Invitation 테이블 존재 확인:
```bash
aws dynamodb list-tables --region ap-northeast-2 | grep -i invitation
```

### 3. 폰 빌드 및 테스트

- [ ] flutter run -d [디바이스ID]
- [ ] 테스트 시나리오:
  1. 로그인 (maknae12@gmail.com)
  2. 학원 선택
  3. 멤버 관리 → 플로팅 버튼 클릭
  4. 이메일 검색 → "초대 메일 발송" 버튼 클릭
  5. DynamoDB Invitation 테이블에 레코드 생성 확인

### 4. 로그 확인

- [ ] safePrint 로그에서 Invitation 생성 로그 확인
- [ ] GraphQL mutation 성공 확인

---

## 검증 규칙 (v7.3)

- 에러 메시지만 보고 실패 판정 금지
- 실제 화면/동작 확인 후 판정

---

## 완료 조건

1. DynamoDB에 Invitation 테이블 존재
2. 플로팅 버튼 → 이메일 검색 → 초대 메일 발송 동작
3. Invitation 테이블에 레코드 생성됨
4. CP가 "테스트 종료" 입력
5. 보고서 작성 완료 (ai_bridge/report/big_083_report.md)
