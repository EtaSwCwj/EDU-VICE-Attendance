# BIG_087: Lambda 함수로 초대 수락 시 AcademyMember 자동 생성

> 생성일: 2025-12-25
> 목표: Invitation status='accepted' 시 Lambda가 AcademyMember 자동 생성

---

## 배경

### 문제 상황
```
현재 플로우:
1. 원장이 초대 발송 → Invitation 생성 ✅
2. 학생이 수락 클릭 → AcademyMember 생성 시도 ❌ (권한 없음!)

에러: "Not Authorized to access createAcademyMember on type Mutation"
```

### 해결 방안
```
새로운 플로우:
1. 원장이 초대 발송 → Invitation 생성 ✅
2. 학생이 수락 클릭 → Invitation status='accepted'로 업데이트 ✅
3. DynamoDB Stream → Lambda 트리거 ✅
4. Lambda가 AcademyMember 생성 ✅ (서버 측이라 권한 OK)
```

---

## ⚠️ 필수: Opus는 직접 작업 금지!

### Sonnet 호출 방법
```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

### 예외 (Opus가 직접 해도 되는 것)
- amplify 명령어 (대화형 입력 필요)
- AWS CLI

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 테스트 계정: maknae12@gmail.com

---

## 스몰스텝

### 1. Lambda 함수 생성 (Opus가 대화형으로 직접)

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
amplify add function
```

**질문에 답변:**
1. Select which capability: `Lambda function`
2. Function name: `invitationAcceptTrigger`
3. Runtime: `NodeJS`
4. Template: `Hello World`
5. Advanced settings: `Yes`
6. Access other resources: `Yes`
   - Select category: `api`
   - Select operations: `create`, `read`, `update`
7. Edit local lambda: `No`

### 2. Lambda 코드 작성 (Sonnet)

- [ ] 파일: `amplify/backend/function/invitationAcceptTrigger/src/index.js`
- [ ] 기존 코드 전체 삭제하고 아래 코드로 교체:

```javascript
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { v4: uuidv4 } = require('uuid');

const client = new DynamoDBClient({ region: process.env.REGION });
const docClient = DynamoDBDocumentClient.from(client);

const ACADEMY_MEMBER_TABLE = process.env.API_EVATTENDANCE_ACADEMYMEMBERTABLE_NAME || 'AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev';

exports.handler = async (event) => {
  console.log('[invitationAcceptTrigger] Event:', JSON.stringify(event, null, 2));
  
  for (const record of event.Records) {
    if (record.eventName !== 'MODIFY') {
      console.log('[invitationAcceptTrigger] Skip:', record.eventName);
      continue;
    }
    
    const newImage = record.dynamodb.NewImage;
    const oldImage = record.dynamodb.OldImage;
    
    const newStatus = newImage?.status?.S;
    const oldStatus = oldImage?.status?.S;
    
    console.log('[invitationAcceptTrigger] Status:', oldStatus, '->', newStatus);
    
    if (newStatus === 'accepted' && oldStatus !== 'accepted') {
      const userId = newImage.usedBy?.S;
      const academyId = newImage.academyId?.S;
      const role = newImage.role?.S;
      
      console.log('[invitationAcceptTrigger] Creating:', { userId, academyId, role });
      
      if (!userId || !academyId || !role) {
        console.error('[invitationAcceptTrigger] Missing fields');
        continue;
      }
      
      try {
        const now = new Date().toISOString();
        const item = {
          id: uuidv4(),
          __typename: 'AcademyMember',
          userId,
          academyId,
          role,
          createdAt: now,
          updatedAt: now,
          _version: 1,
          _lastChangedAt: Date.now()
        };
        
        await docClient.send(new PutCommand({
          TableName: ACADEMY_MEMBER_TABLE,
          Item: item
        }));
        
        console.log('[invitationAcceptTrigger] Created:', item.id);
      } catch (error) {
        console.error('[invitationAcceptTrigger] Error:', error);
        throw error;
      }
    }
  }
  
  return { statusCode: 200, body: 'OK' };
};
```

### 3. package.json 수정 (Sonnet)

- [ ] 파일: `amplify/backend/function/invitationAcceptTrigger/src/package.json`
- [ ] 내용:

```json
{
  "name": "invitationAcceptTrigger",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "@aws-sdk/client-dynamodb": "^3.0.0",
    "@aws-sdk/lib-dynamodb": "^3.0.0",
    "uuid": "^9.0.0"
  }
}
```

### 4. amplify push (Opus가 직접)

```bash
amplify push --yes
```

- [ ] Lambda 함수 배포 확인

### 5. DynamoDB Stream 트리거 연결 (AWS Console에서 수동)

1. AWS Console → Lambda → invitationAcceptTrigger-dev
2. Add trigger → DynamoDB
3. Table: `Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev`
4. Starting position: `Latest`
5. Enable trigger: `Yes`

### 6. 앱 코드 수정 (Sonnet)

- [ ] 파일: `lib/features/home/no_academy_shell.dart`
- [ ] `_acceptInvitation` 함수에서 AcademyMember 생성 코드 **제거**
- [ ] 94~110줄 근처의 아래 코드 삭제:

```dart
// 삭제할 코드 (94~110줄 근처)
      // 1. AcademyMember 생성
      final academyMember = AcademyMember(
        userId: user.id,
        academyId: invitation.academyId,
        role: invitation.role,
      );

      final createMemberRequest = ModelMutations.create(academyMember);
      final createMemberResponse = await Amplify.API.mutate(request: createMemberRequest).response;

      if (createMemberResponse.data == null) {
        throw Exception('AcademyMember 생성 실패: ${createMemberResponse.errors}');
      }

      safePrint('[NoAcademyShell] AcademyMember 생성 성공: ${createMemberResponse.data!.id}');
```

- [ ] 대신 이 한 줄 추가:
```dart
      // Lambda가 AcademyMember 생성 (DynamoDB Stream 트리거)
      safePrint('[NoAcademyShell] Invitation 업데이트 완료 - Lambda가 AcademyMember 생성 예정');
```

### 7. flutter analyze (Sonnet)

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze
```

- [ ] 에러 0개 확인

---

## 로그 저장 (필수!)

- [ ] ai_bridge/logs/big_087_step_01.log (amplify add function)
- [ ] ai_bridge/logs/big_087_step_04.log (amplify push)
- [ ] ai_bridge/logs/big_087_step_07.log (flutter analyze)

---

## 완료 조건

1. Lambda 함수 배포 완료
2. DynamoDB Stream 트리거 연결 완료
3. 앱 코드 수정 완료
4. flutter analyze 에러 0개
5. 보고서 작성 완료 (ai_bridge/report/big_087_report.md)

---

## ⚠️ 참고: 테스트는 다음 BIG에서

Lambda + 앱 수정 완료 후, 다음 BIG에서 테스트:
- owner_test1 → maknae12@gmail.com 초대
- maknae12@gmail.com 수락
- CloudWatch 로그 확인
