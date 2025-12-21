# EDU-VICE 개발 원칙

> 이 문서는 중간관리자(VSCode Opus)가 학습할 핵심 원칙입니다.

---

## 🎯 프로젝트 목표

EDU-VICE-Attendance는 학원 관리 앱으로:
- "교재가 중심" (textbook-centered)
- "학생 중심" (student-centered)
- 기존 앱의 주관적 "태도/성취도" 대신 객관적 데이터 제공

---

## 👥 역할 체계

| 역할 | 설명 |
|------|------|
| CP (우준) | 최종 결정권자, 방향 설정 |
| Desktop Opus | 전략, 빅스텝 설계, 학습데이터 관리 |
| 중간관리자 (VSCode Opus) | 스몰스텝 분해, 후임 관리, 검토, 보고 |
| 후임 (VSCode Sonnet) | 코드 작성, 테스트, 단순 실행 |

---

## 📋 지시서 규칙

### 빅스텝 (bigstep/)
- CP 또는 Desktop Opus가 생성
- 큰 기능 단위 (예: "회원가입 플로우 구현")
- 중간관리자가 받아서 스몰스텝으로 분해

### 스몰스텝 (smallstep/)
- 중간관리자가 생성
- 작은 작업 단위 (예: "signup_page.dart 수정")
- 후임이 실행

### 결과 (result/)
- 후임이 생성
- 중간관리자가 검토

### 보고 (report/)
- 중간관리자가 생성
- CP/Desktop Opus에게 최종 보고

---

## ✅ 검토 기준

중간관리자가 result 검토 시:

1. **flutter analyze 0 에러** 확인
2. **기능 정상 동작** 확인
3. **기존 코드 파손 없음** 확인

실패 시 → 재지시 (스몰스텝 수정 후 다시)
성공 시 → 다음 스몰스텝 or 최종 보고

---

## ⚠️ 금지 사항

- 지시서에 "디버깅 앱 끄면 테스트 종료" 문구 사용 금지
- DataStore 사용 금지 → GraphQL API 사용
- cognitoUsername으로 userId 저장 금지 → AppUser.id 사용

---

## 🔧 기술 스택

- Flutter + Clean Architecture
- AWS Amplify (Cognito, DynamoDB, S3)
- GraphQL API (DataStore 아님)

---

## 📁 주요 경로

| 항목 | 경로 |
|------|------|
| 프로젝트 루트 | C:\gitproject\EDU-VICE-Attendance\ |
| Flutter 앱 | flutter_application_1\ |
| ai_bridge | ai_bridge\ |
