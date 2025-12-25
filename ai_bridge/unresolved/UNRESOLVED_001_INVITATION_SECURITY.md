# UNRESOLVED_001: Invitation 테이블 권한 보안 강화

> 생성일: 2025-12-25
> 우선순위: Phase 2 (서비스 확장 시)
> 상태: 미해결

---

## 현재 상황

### 임시 해결 (Phase 1)
```graphql
type Invitation
  @auth(rules: [
    { allow: groups, groups: ["owners"], operations: [create, read, update, delete] },
    { allow: private, operations: [read, update] }  # ← update 추가됨
  ])
```

### 보안 우려
- 일반 유저(private)가 Invitation update 권한 가짐
- 이론적으로 다른 사람 초대 상태 변경 가능
- 실제로는:
  - 다른 사람 초대 ID 알기 어려움
  - 앱에서 자기 이메일로 온 초대만 조회
  - MVP 단계에서 리스크 낮음

---

## Phase 2 해결 방안

### 방법: Lambda가 Invitation 업데이트도 처리

**현재 플로우:**
```
앱 → Invitation update (GraphQL) → DynamoDB Stream → Lambda → AcademyMember 생성
```

**개선 플로우:**
```
앱 → Lambda 직접 호출 (API Gateway) → Invitation update + AcademyMember 생성
```

### 필요 작업
1. API Gateway 엔드포인트 생성
2. Lambda 함수 수정 (Invitation update 로직 추가)
3. 앱 코드 수정 (GraphQL → API Gateway 호출)
4. schema.graphql에서 private update 권한 제거

### 장점
- 서버 측에서 권한 검증 가능 (inviteeEmail == 현재 유저 email)
- 클라이언트가 직접 DB 수정 불가
- 보안 강화

---

## 참고

- 관련 BIG: BIG_087_2
- 관련 파일: `amplify/backend/api/evattendance/schema.graphql`
- Lambda 함수: `invitationAcceptTrigger-dev`
