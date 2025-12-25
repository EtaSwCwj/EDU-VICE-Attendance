# BIG_079_2: 유저 검색 + 초대 메일 발송 기능

> 생성일: 2025-12-23
> 목표: 원장 앱에서 유저 검색 + 초대 메일 발송 버튼 구현

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
- Flutter 앱: flutter_application_1/
- 테스트 계정: maknae12@gmail.com

---

## 배경

079_1에서 QR 스캔 UI 개선 완료됨:
- QR 크기 300으로 증가 ✅
- 스캔 가이드라인 추가 ✅
- MobileScanner 최적화 ✅
- 초대 메일 템플릿 ✅

**하지만 빠진 기능:**
1. 이메일로 유저 검색 기능
2. 초대 메일 발송 버튼

---

## 스몰스텝 (진행 시 체크박스 업데이트!)

### 1. 유저 검색 UI 추가 (멤버 관리 페이지)
- [ ] 이메일 입력 TextField 추가
- [ ] "검색" 버튼 추가
- [ ] 파일: lib/features/invitation/invitation_management_page.dart

### 2. 유저 검색 로직 구현
- [ ] 이메일로 AppUser 조회 (GraphQL API)
- [ ] 있으면 → 이름, 이메일 표시 + 확인 다이얼로그
- [ ] 없으면 → "가입되지 않은 사용자입니다" 스낵바
- [ ] 이미 멤버면 → "이미 등록된 멤버입니다" 스낵바

### 3. 초대 확인 다이얼로그 수정
- [ ] 현재: 바로 AcademyMember 생성
- [ ] 변경: "초대 메일 발송" vs "바로 추가" 선택 가능하게
- [ ] 역할 선택 (선생님/학생)

### 4. Invitation 생성 + 메일 발송 기능
- [ ] "초대 메일 발송" 선택 시:
  - Invitation 생성 (status: pending, expiresAt: 7일 후)
  - inviteCode 생성 (UUID 또는 랜덤 코드)
- [ ] Lambda 트리거 확인 (DynamoDB 스트림)
- [ ] 발송 완료 스낵바 표시

### 5. "바로 추가" 기능 유지
- [ ] "바로 추가" 선택 시:
  - 기존처럼 AcademyMember 바로 생성
  - 초대 메일 없이 즉시 등록

### 6. flutter analyze
- [ ] flutter analyze 에러/경고 0개 확인

### 7. 테스트 (폰 단독)
- [ ] 폰에서 빌드: flutter run -d RFCY40MNBLL
- [ ] 원장 계정 로그인
- [ ] 이메일 검색 테스트 (maknae12@gmail.com 검색)
- [ ] 초대 메일 발송 버튼 테스트 (Invitation 생성 확인)

### 8. QR 스캔 테스트 (듀얼 필요 시만)
> QR 스캔은 웹 QR + 폰 스캔 필요 시 듀얼 빌드
> 단, 이미 079_1에서 QR UI 개선 완료됨. 필요하면 테스트.

- [ ] (선택) Sonnet 추가 호출: flutter run -d chrome --web-port=8080
- [ ] (선택) 웹에서 maknae12@gmail.com 로그인 → QR 표시
- [ ] (선택) 폰에서 QR 스캔 테스트

---

## 유저 검색 UI 예시

```dart
// 멤버 관리 페이지에 추가
Column(
  children: [
    // 이메일 검색 영역
    Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: '이메일로 검색',
                hintText: 'user@example.com',
                prefixIcon: Icon(Icons.search),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: _searchUser,
            child: Text('검색'),
          ),
        ],
      ),
    ),
    // 기존 멤버 목록
    Expanded(child: _buildMemberList()),
  ],
)
```

---

## 초대 확인 다이얼로그 예시

```dart
AlertDialog(
  title: Text('사용자 초대'),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('${userName}님을 초대하시겠습니까?'),
      Text(userEmail, style: TextStyle(color: Colors.grey)),
      SizedBox(height: 16),
      // 역할 선택
      SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'teacher', label: Text('선생님')),
          ButtonSegment(value: 'student', label: Text('학생')),
        ],
        selected: {selectedRole},
        onSelectionChanged: (selection) => ...,
      ),
    ],
  ),
  actions: [
    TextButton(onPressed: () => Navigator.pop(context), child: Text('취소')),
    OutlinedButton(
      onPressed: () => _sendInvitationEmail(),  // Invitation 생성 + 메일
      child: Text('초대 메일 발송'),
    ),
    FilledButton(
      onPressed: () => _addMemberDirectly(),  // 바로 AcademyMember 생성
      child: Text('바로 추가'),
    ),
  ],
)
```

---

## 검증 규칙 (v7.3)

- 에러 메시지만 보고 실패 판정 금지
- 실제 화면/동작 확인 후 판정

---

## 로그 저장

각 스몰스텝 완료 시:
- ai_bridge/logs/big_079_2_step_XX.log

---

## 완료 조건

1. 이메일 검색 UI 추가됨
2. 유저 검색 로직 동작
3. 초대 확인 다이얼로그에 "초대 메일 발송" / "바로 추가" 버튼
4. Invitation 생성 + 메일 발송 동작
5. flutter analyze 에러 0개
6. 실제 테스트 성공
7. CP가 "테스트 종료" 입력
8. 보고서 작성 완료 (ai_bridge/report/big_079_2_report.md)
