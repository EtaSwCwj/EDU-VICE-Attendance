# BIG_087_2 진행 상황 보고서

> 생성일: 2025-12-25
> 작업: Lambda 함수 재생성 (API 의존성 없이)

---

## 완료된 작업

### 1. 앱 코드 수정 ✅
- 파일: `lib/features/home/no_academy_shell.dart`
- AcademyMember 생성 코드 제거 (103~118줄)
- Lambda가 자동으로 처리하도록 변경
- flutter analyze: 에러 0개 확인

### 2. Lambda 코드 준비 완료 ✅
- index.js 코드 작성 완료 (Sonnet 사용)
- package.json 준비 완료
- CloudFormation 템플릿 권한 설정 준비 완료
- 테이블 이름 하드코딩으로 해결

### 3. 로그 저장 ✅
- `ai_bridge/logs/big_087_2_step_06_initial.log` - 첫 amplify push 시도
- `ai_bridge/logs/big_087_2_step_09.log` - flutter analyze 결과

---

## 대기 중인 작업

### amplify add function 실행 필요 ⏳

사용자가 직접 실행해야 함:
```bash
cd /c/gitproject/EDU-VICE-Attendance/flutter_application_1
amplify add function
```

선택 옵션:
1. Select which capability: `Lambda function`
2. Function name: `invitationAcceptTrigger`
3. Runtime: `NodeJS`
4. Template: `Hello World`
5. **Advanced settings: `No`** ← 중요!
6. Edit local lambda: `No`

---

## 다음 단계

1. amplify add function 완료 후
2. 생성된 파일에 Lambda 코드 적용
3. amplify push로 배포
4. AWS Console에서 DynamoDB Stream 트리거 연결
5. 최종 보고서 작성

---

## 현재 상태
- ✅ 앱 코드 수정 완료
- ✅ Lambda 코드 준비 완료
- ⏳ amplify add function 대기 중
- ⬜ Lambda 배포
- ⬜ DynamoDB Stream 트리거 연결