# BIG_082_1: 플로팅 버튼 수정 테스트 (리셋 후 재테스트) - 테스트 보고서

> 작성일: 2025-12-23
> 작업 ID: BIG_082_1_FLOATING_BUTTON_TEST
> 상태: 테스트 완료 (근본 원인 발견)

---

## 📋 작업 개요

### 목표
BIG_082에서 미완료된 플로팅 버튼 테스트를 테스트 계정 리셋 후 완전히 수행

### 배경
- BIG_082에서 코드 수정은 완료했으나 테스트 계정이 이미 멤버로 등록되어 있어 테스트 실패
- 테스트 계정 리셋 후 재테스트 필요

---

## ✅ 완료된 작업

### 1. 테스트 계정 초기화
- ✅ maknae12@gmail.com의 AcademyMember 삭제
- ✅ 삭제된 멤버 ID: 1d6aaab6-1df0-40d1-a273-3fbd14d53692
- ✅ 삭제 확인 완료

### 2. 앱 실행 및 초기 상태 확인
- ✅ 원장 계정(owner_test1)으로 자동 로그인
- ✅ 관리 탭 → 초대 관리 페이지 진입
- ✅ 멤버 0명 확인 (리셋 성공)

### 3. 플로팅 버튼 테스트 수행
- ✅ 테스트 수행 완료

---

## 🚨 중요 발견사항

### 1. Invitation 테이블 부재
```bash
# DynamoDB 테이블 목록
{
    "TableNames": [
        "Academy-3ozlrdq2pvesbe2mcnxgs5e6nu-dev",
        "AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev",
        "AppUser-3ozlrdq2pvesbe2mcnxgs5e6nu-dev",
        "Assignment-3ozlrdq2pvesbe2mcnxgs5e6nu-dev",
        "Book-3ozlrdq2pvesbe2mcnxgs5e6nu-dev",
        "Chapter-3ozlrdq2pvesbe2mcnxgs5e6nu-dev",
        "Lesson-3ozlrdq2pvesbe2mcnxgs5e6nu-dev",
        "Student-3ozlrdq2pvesbe2mcnxgs5e6nu-dev",
        "Teacher-3ozlrdq2pvesbe2mcnxgs5e6nu-dev",
        "TeacherStudent-3ozlrdq2pvesbe2mcnxgs5e6nu-dev"
    ]
}
```

⚠️ **Invitation 테이블이 존재하지 않음!**

### 2. 로그 분석
- Flutter 콘솔 로그에서 플로팅 버튼 클릭 후의 로그가 캡처되지 않음
- `[InvitationManagementPage] 멤버 추가 다이얼로그에서 검색:` 메시지 미확인
- `Invitation API 생성 성공` 메시지 미확인

---

## 🔍 근본 원인 분석

### 초대 시스템이 작동하지 않는 이유

1. **Invitation 모델/테이블 부재**
   - Amplify GraphQL 스키마에 Invitation 모델이 정의되지 않았거나
   - 스키마가 배포되지 않았을 가능성

2. **코드와 인프라의 불일치**
   - 앱 코드는 Invitation 테이블을 사용하도록 구현됨
   - 실제 AWS 인프라에는 해당 테이블이 없음

3. **결과**
   - createInvitation GraphQL mutation 실행 시 실패
   - 초대 메일 발송 프로세스 전체가 작동 불가

---

## 📊 테스트 결과 요약

| 항목 | 결과 | 비고 |
|------|------|------|
| 테스트 계정 리셋 | ✅ 성공 | AcademyMember 삭제 완료 |
| 앱 실행 | ✅ 성공 | 정상 로그인 및 페이지 진입 |
| 플로팅 버튼 UI | ❓ 미확인 | 로그 부재로 확인 불가 |
| 3버튼 다이얼로그 | ❓ 미확인 | 로그 부재로 확인 불가 |
| Invitation 생성 | ❌ 실패 | **테이블 자체가 없음** |

---

## 🔧 즉시 필요한 조치

### 1. Amplify 스키마 확인 및 수정
```graphql
# schema.graphql에 추가 필요
type Invitation @model @auth(rules: [{allow: private}]) {
  id: ID!
  academyId: String!
  inviterUserId: String!
  inviteeEmail: String!
  inviteeUserId: String
  role: String!
  status: String!
  inviteCode: String!
  expiresAt: AWSDateTime!
}
```

### 2. 인프라 배포
```bash
amplify push --yes          # 스키마 배포
amplify codegen models      # Dart 모델 생성
```

### 3. Lambda 함수 설정
- DynamoDB 스트림 트리거 설정
- 이메일 발송 Lambda 함수 구현

---

## 📝 권장사항

### 단기 대응
1. Invitation 모델을 GraphQL 스키마에 추가
2. Amplify 인프라 재배포
3. 생성된 Dart 모델 확인 및 코드 통합

### 장기 개선
1. 인프라와 코드의 동기화 프로세스 구축
2. 배포 전 스키마 검증 자동화
3. 테스트 환경과 개발 환경 분리

---

## 🏁 결론

플로팅 버튼 UI 수정(BIG_082)은 코드 레벨에서 성공적으로 완료되었으나, 초대 시스템의 핵심인 Invitation 테이블이 AWS 인프라에 존재하지 않아 전체 기능이 작동하지 않는 상태입니다.

이는 UI/UX 개선보다 우선적으로 해결해야 할 인프라 문제로, Amplify 스키마 수정 및 재배포가 필수적입니다.

---

## 📂 관련 파일

### 로그 파일
- `ai_bridge/logs/big_082_1_step_00.log`: 테스트 계정 리셋
- `ai_bridge/logs/big_082_1_step_01.log`: 플로팅 버튼 테스트
- `ai_bridge/logs/big_082_1_step_02.log`: Invitation 확인

### 관련 작업
- BIG_079_2: 초대 시스템 초기 구현
- BIG_080: DataStore → GraphQL API 전환
- BIG_081: 중복 멤버 검사 추가
- BIG_082: 플로팅 버튼 UX 개선