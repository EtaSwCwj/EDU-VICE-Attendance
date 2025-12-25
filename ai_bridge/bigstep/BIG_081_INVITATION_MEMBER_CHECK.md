# BIG_081: 초대 메일 발송 전 멤버 검사 + 테스트

> 생성일: 2025-12-23
> 목표: 초대 메일 발송 전 이미 멤버인지 검사 추가 + 실제 테스트

---

## ⚠️ 필수: Opus는 직접 작업 금지!
가급적 코드/파일 작업은 Sonnet 호출해서 시킬 것.

### Sonnet 호출 방법
```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

### 예외 (Opus가 직접 해도 되는 것)
- AWS CLI (인증 필요)

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- 수정 파일: flutter_application_1/lib/features/invitation/invitation_management_page.dart
- 테스트 계정: maknae12@gmail.com (AppUser ID: a498ad1c-6011-70c6-2f00-92a2fad64b02)

---

## 스몰스텝 (진행 시 체크박스 업데이트!)

### 0. 테스트 계정 초기화 (AWS CLI로 Opus가 직접)

- [ ] maknae12@gmail.com의 AcademyMember 삭제
- [ ] 명령어:
```bash
# 먼저 해당 유저의 AcademyMember 조회
aws dynamodb scan --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "userId = :uid" --expression-attribute-values '{":uid":{"S":"a498ad1c-6011-70c6-2f00-92a2fad64b02"}}' --region ap-northeast-2

# 조회된 id로 삭제
aws dynamodb delete-item --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --key '{"id":{"S":"조회된ID"}}' --region ap-northeast-2
```
- [ ] 삭제 확인

### 1. `_sendInvitationEmail` 함수에 멤버 검사 추가

- [ ] 파일: `lib/features/invitation/invitation_management_page.dart`
- [ ] 위치: `_sendInvitationEmail` 함수 시작 부분 (현재 782줄 근처)
- [ ] 현재 코드 (수정 전):
```dart
Future<void> _sendInvitationEmail(AppUser user, String role) async {
  safePrint('[InvitationManagementPage] 초대 메일 발송: user=${user.name}, role=$role');

  try {
    // 현재 사용자 정보 가져오기
    final authState = context.read<AuthState>();
    final currentUser = authState.user;
```

- [ ] 수정 후 (멤버 검사 추가):
```dart
Future<void> _sendInvitationEmail(AppUser user, String role) async {
  safePrint('[InvitationManagementPage] 초대 메일 발송: user=${user.name}, role=$role');

  try {
    // 1. 이미 멤버인지 확인 (GraphQL API)
    const listMembersQuery = '''
      query ListAcademyMembers(\$filter: ModelAcademyMemberFilterInput) {
        listAcademyMembers(filter: \$filter) {
          items {
            id
          }
        }
      }
    ''';

    final membersResponse = await Amplify.API.query(
      request: GraphQLRequest<String>(
        document: listMembersQuery,
        variables: {
          'filter': {
            'academyId': {'eq': widget.academyId},
            'userId': {'eq': user.id}
          }
        },
      ),
    ).response;

    if (membersResponse.data != null) {
      final membersJson = json.decode(membersResponse.data!);
      final membersList = membersJson['listAcademyMembers']['items'] as List;

      if (membersList.isNotEmpty) {
        safePrint('[InvitationManagementPage] 이미 등록된 멤버: ${user.email}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name}님은 이미 등록된 멤버입니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    // 2. 현재 사용자 정보 가져오기
    final authState = context.read<AuthState>();
    final currentUser = authState.user;
```

### 2. flutter analyze
- [ ] flutter analyze 실행
- [ ] 에러/경고 0개 확인

### 3. 테스트 (폰 단독)
- [ ] flutter run -d RFCY40MNBLL
- [ ] 원장 계정 로그인
- [ ] 멤버 관리 페이지 진입
- [ ] 이메일 검색: maknae12@gmail.com
- [ ] "초대 메일 발송" 버튼 클릭
- [ ] 앱 로그 확인: `[InvitationManagementPage] Invitation API 생성 성공` 메시지 확인
- [ ] AWS DynamoDB 콘솔에서 Invitation 테이블에 레코드 생성 확인

### 4. 중복 멤버 검사 테스트
- [ ] maknae12@gmail.com을 "바로 추가"로 먼저 등록
- [ ] 다시 maknae12@gmail.com 검색
- [ ] "초대 메일 발송" 클릭
- [ ] "이미 등록된 멤버입니다" 스낵바 표시 확인

---

## 검증 규칙 (v7.3)

- 에러 메시지만 보고 실패 판정 금지
- 실제 화면/동작 확인 후 판정

---

## 로그 저장

각 스몰스텝 완료 시:
- ai_bridge/logs/big_081_step_XX.log

---

## 완료 조건

1. 테스트 계정 (maknae12@gmail.com) 리셋 완료
2. `_sendInvitationEmail`에 멤버 검사 로직 추가됨
3. flutter analyze 에러 0개
4. 초대 메일 발송 시 Invitation 생성 확인 (로그 + DynamoDB)
5. 중복 멤버에게 초대 시 "이미 등록된 멤버" 메시지 표시
6. CP가 "테스트 종료" 입력
7. 보고서 작성 완료 (ai_bridge/report/big_081_report.md)
