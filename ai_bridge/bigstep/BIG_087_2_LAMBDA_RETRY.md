# BIG_087_2: Lambda 함수 재생성 (의존성 없이)

> 생성일: 2025-12-25
> 목표: invitationAcceptTrigger Lambda 함수 재생성 (API 의존성 제거)

---

## 이전 시도 실패 원인

```
에러: Output 'AcademyMemberTableName' not found in stack
```

`amplify add function`에서 API 리소스 접근 권한을 줬더니 CloudFormation에서 테이블 출력을 찾지 못함.

---

## 해결 방안

1. API 의존성 없이 Lambda 함수 생성
2. 테이블 이름은 환경변수로 직접 설정
3. DynamoDB 권한은 CloudFormation 템플릿에서 수동 추가

---

## ⚠️ Opus가 직접 실행

amplify 명령어는 대화형이라 Opus가 직접 해야 함.

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1

---

## 스몰스텝

### 1. 이전 실패한 함수 정리 (필요시)

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
amplify status
```

만약 `invitationAcceptTrigger`가 보이면:
```bash
amplify remove function
# invitationAcceptTrigger 선택
```

### 2. Lambda 함수 재생성 (Opus 직접)

```bash
amplify add function
```

**질문에 답변:**
1. Select which capability: `Lambda function`
2. Function name: `invitationAcceptTrigger`
3. Runtime: `NodeJS`
4. Template: `Hello World`
5. **Advanced settings: `No`** ← 이번엔 No!
6. Edit local lambda: `No`

### 3. Lambda 코드 작성 (Sonnet)

- [ ] 파일: `amplify/backend/function/invitationAcceptTrigger/src/index.js`
- [ ] 전체 교체:

```javascript
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { v4: uuidv4 } = require('uuid');

const client = new DynamoDBClient({ region: 'ap-northeast-2' });
const docClient = DynamoDBDocumentClient.from(client);

// 테이블 이름 하드코딩
const ACADEMY_MEMBER_TABLE = 'AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev';

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

### 4. package.json 수정 (Sonnet)

- [ ] 파일: `amplify/backend/function/invitationAcceptTrigger/src/package.json`

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

### 5. CloudFormation 템플릿에 DynamoDB 권한 추가 (Sonnet)

- [ ] 파일: `amplify/backend/function/invitationAcceptTrigger/invitationAcceptTrigger-cloudformation-template.json`
- [ ] `lambdaexecutionpolicy`의 `PolicyDocument.Statement` 배열에 추가:

```json
{
  "Effect": "Allow",
  "Action": [
    "dynamodb:PutItem",
    "dynamodb:GetItem",
    "dynamodb:UpdateItem"
  ],
  "Resource": "arn:aws:dynamodb:ap-northeast-2:*:table/AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev"
}
```

### 6. amplify push (Opus 직접)

```bash
amplify push --yes
```

- [ ] 배포 성공 확인 (5~15분 소요)

### 7. DynamoDB Stream 트리거 연결 (AWS Console)

1. AWS Console → Lambda → `invitationAcceptTrigger-dev`
2. Configuration → Triggers → Add trigger
3. Select source: `DynamoDB`
4. DynamoDB table: `Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev`
5. Starting position: `Latest`
6. Enable trigger: 체크
7. Add 클릭

### 8. 앱 코드 수정 - AcademyMember 생성 제거 (Sonnet)

- [ ] 파일: `lib/features/home/no_academy_shell.dart`
- [ ] `_acceptInvitation` 함수에서 88~107줄 근처 AcademyMember 생성 코드 삭제

**삭제할 코드:**
```dart
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

**추가할 코드 (같은 위치):**
```dart
      // Lambda가 DynamoDB Stream으로 AcademyMember 자동 생성
      safePrint('[NoAcademyShell] Invitation 업데이트 완료 - Lambda가 AcademyMember 생성');
```

### 9. flutter analyze (Sonnet)

```bash
flutter analyze
```

- [ ] 에러 0개 확인

---

## 로그 저장 (필수!)

- [ ] ai_bridge/logs/big_087_2_step_02.log (amplify add function)
- [ ] ai_bridge/logs/big_087_2_step_06.log (amplify push)
- [ ] ai_bridge/logs/big_087_2_step_09.log (flutter analyze)

---

## 완료 조건

1. Lambda 함수 배포 완료
2. DynamoDB Stream 트리거 연결 완료 (AWS Console)
3. 앱 코드 수정 완료
4. flutter analyze 에러 0개
5. 보고서 작성 완료 (ai_bridge/report/big_087_2_report.md)
