# BIG_082_1: 플로팅 버튼 수정 테스트 (리셋 후 재테스트)

> 생성일: 2025-12-23
> 목표: 082에서 테스트 못한 부분 완료 (테스트 계정 리셋 후)

---

## ⚠️ 작성 전 체크리스트 (완료됨)

### 기본 확인
- [x] 로컬 코드 확인 → 082에서 수정 완료됨, 추가 수정 없음
- [x] 새 함수에 safePrint 로그 → 082 코드에 이미 있음 확인 필요

### 테스트 환경
- [x] 테스트 계정 리셋 필요 → **YES! 0번 스텝에 추가**
- [x] **테스트 계정 현재 상태** → 이미 AcademyMember로 등록됨 (082에서 오염)
- [x] 빌드 필요 → YES (테스트)
- [x] 듀얼 필요 → NO (1개 계정)

### 작업 연결
- [x] 이전 BIG 미완료 → 082 테스트 미완료

---

## ⚠️ 필수: Opus는 직접 작업 금지!

### Sonnet 호출 방법
```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

### 예외 (Opus가 직접 해도 되는 것)
- AWS CLI (인증 필요)

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- 테스트 계정: maknae12@gmail.com (AppUser ID: a498ad1c-6011-70c6-2f00-92a2fad64b02)

---

## 스몰스텝 (진행 시 체크박스 업데이트!)

### 0. 테스트 계정 초기화 (Opus가 AWS CLI로 직접)

- [ ] AcademyMember 조회:
```bash
aws dynamodb scan --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "userId = :uid" --expression-attribute-values '{":uid":{"S":"a498ad1c-6011-70c6-2f00-92a2fad64b02"}}' --region ap-northeast-2
```

- [ ] 조회된 id로 삭제:
```bash
aws dynamodb delete-item --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --key '{"id":{"S":"조회된ID"}}' --region ap-northeast-2
```

- [ ] 삭제 확인 (다시 scan해서 빈 결과)

### 1. 테스트 (폰 단독)

- [ ] flutter run -d RFCY40MNBLL
- [ ] 원장 계정 로그인
- [ ] 멤버 관리 페이지 (초대 관리 탭)
- [ ] **플로팅 버튼 "멤버 추가" 클릭**
- [ ] 이메일 입력 다이얼로그 표시 확인
- [ ] **"검색" 버튼** 있는지 확인 (이전엔 "추가" 버튼이었음)
- [ ] maknae12@gmail.com 입력 → "검색" 클릭
- [ ] **3버튼 다이얼로그 표시 확인:**
  - "취소"
  - "초대 메일 발송"  
  - "바로 추가"
- [ ] **"초대 메일 발송" 클릭**
- [ ] 성공 스낵바 표시 확인

### 2. Invitation 생성 확인

- [ ] 앱 로그에서 확인:
  - `[InvitationManagementPage] 초대 메일 발송: user=최우준, role=student`
  - `[InvitationManagementPage] Invitation API 생성 성공: code=XXX, id=XXX`

- [ ] AWS DynamoDB에서 Invitation 확인:
```bash
aws dynamodb scan --table-name Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "inviteeEmail = :email" --expression-attribute-values '{":email":{"S":"maknae12@gmail.com"}}' --region ap-northeast-2
```

---

## ⚠️ Opus 필수: 로그 직접 확인!

**보고서만 읽지 말고, Flutter 콘솔 로그 직접 확인!**

**로그에서 확인할 것:**
1. `[InvitationManagementPage] 멤버 추가 다이얼로그에서 검색:` 메시지 있나?
2. `Invitation API 생성 성공` 메시지 있나?
3. 에러 메시지 있으면 어떤 에러인지?

**추측하지 말고 로그 보고 판단!**

---

## 로그 저장 (필수!)

- [ ] ai_bridge/logs/big_082_1_step_00.log (테스트 계정 리셋)
- [ ] ai_bridge/logs/big_082_1_step_01.log (테스트 결과 + Flutter 로그)
- [ ] ai_bridge/logs/big_082_1_step_02.log (Invitation 확인)

---

## 완료 조건

1. 테스트 계정 리셋 완료
2. 플로팅 버튼 → 검색 → **3버튼 다이얼로그 표시 확인**
3. "초대 메일 발송" → **Invitation 생성 확인** (로그 + DynamoDB)
4. **모든 스텝 로그 파일 저장됨**
5. CP가 "테스트 종료" 입력
6. 보고서 작성 완료 (ai_bridge/report/big_082_1_report.md)
