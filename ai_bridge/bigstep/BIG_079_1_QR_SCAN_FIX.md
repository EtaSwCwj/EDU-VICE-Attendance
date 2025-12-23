# BIG_079_1: 초대 시스템 보완 (QR 스캔 + 메일 내용)

> 생성일: 2025-12-23
> 목표: QR 스캔 UI 개선 + 초대 메일 내용 구현 + 테스트 계정 초기화

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

## 발견된 문제점 (079에서)

1. **QR 스캔 인식 실패** - 카메라는 작동하지만 QR 인식 안 됨
2. **QR 가이드라인 없음** - 어디에 맞춰야 하는지 안 보임
3. **초대 메일 내용 없음** - Lambda 템플릿만 있고 실제 메일 내용 없음
4. **테스트 계정 초기화 필요** - 079에서 테스트하면서 다시 등록됐을 수 있음

---

## 스몰스텝 (진행 시 체크박스 업데이트!)

### 1. 테스트 계정 재초기화
- [ ] maknae12@gmail.com의 AcademyMember 레코드 삭제 (AWS CLI)
- [ ] 삭제 확인

### 2. QR 코드 크기 키우기
- [ ] QR 생성 다이얼로그에서 QR 크기 200 → 300으로 변경
- [ ] 파일: lib/features/settings/settings_page.dart

### 3. QR 스캔 가이드라인 추가
- [ ] 스캔 영역 표시 (사각형 프레임)
- [ ] 가이드 텍스트 추가 ("QR 코드를 프레임 안에 맞춰주세요")
- [ ] 파일: lib/features/invitation/invitation_management_page.dart
- [ ] 참고: Stack + CustomPaint 또는 Container border 활용

### 4. MobileScanner 설정 최적화
- [ ] detectionSpeed 조정 (DetectionSpeed.normal → noDuplicates)
- [ ] facing 설정 확인 (CameraFacing.back)
- [ ] formats 설정 (QR만 인식하도록)

### 5. 초대 메일 내용 구현
- [ ] Lambda 함수에서 실제 메일 내용 작성
- [ ] 메일 내용 포함:
  - 학원명
  - 초대한 사람 이름
  - 역할 (선생님/학생)
  - 수락 링크 (향후 웹페이지 연결용 placeholder)
  - 만료일 (7일)
- [ ] HTML 템플릿으로 작성
- [ ] 파일: amplify/backend/function/invitationEmailSender/src/index.js

### 6. 빌드 및 테스트
- [ ] flutter analyze 에러/경고 확인
- [ ] 폰에서 빌드 후 QR 스캔 테스트
- [ ] 가이드라인 표시 확인
- [ ] QR 인식 테스트

---

## QR 스캔 가이드라인 예시 코드

```dart
Stack(
  children: [
    MobileScanner(...),
    // 가이드라인 오버레이
    Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    // 가이드 텍스트
    Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Text(
        'QR 코드를 프레임 안에 맞춰주세요',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    ),
  ],
)
```

---

## 초대 메일 템플릿 예시

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>EDU-VICE 학원 초대</title>
</head>
<body style="font-family: Arial, sans-serif; padding: 20px;">
  <h2>🎓 EDU-VICE 학원 초대</h2>
  <p>안녕하세요!</p>
  <p><strong>{{inviterName}}</strong>님이 <strong>{{academyName}}</strong>에 
     <strong>{{role}}</strong>(으)로 초대했습니다.</p>
  
  <div style="margin: 30px 0;">
    <a href="{{acceptLink}}" 
       style="background-color: #26A69A; color: white; padding: 15px 30px; 
              text-decoration: none; border-radius: 8px;">
      초대 수락하기
    </a>
  </div>
  
  <p style="color: #666; font-size: 14px;">
    이 초대는 {{expiresAt}}까지 유효합니다.
  </p>
  
  <hr style="margin-top: 30px;">
  <p style="color: #999; font-size: 12px;">
    EDU-VICE - 교재 중심 학원 관리 시스템
  </p>
</body>
</html>
```

---

## 검증 규칙 (v7.3)

- 에러 메시지만 보고 실패 판정 금지
- 실제 화면/동작 확인 후 판정

---

## 로그 저장

각 스몰스텝 완료 시:
- ai_bridge/logs/big_079_1_step_XX.log

---

## 완료 조건

1. 테스트 계정 초기화 완료
2. QR 코드 크기 300으로 증가
3. QR 스캔 가이드라인 표시됨
4. MobileScanner 최적화 적용
5. 초대 메일 HTML 템플릿 완성
6. flutter analyze 에러 0개
7. 실제 QR 스캔 인식 테스트 성공
8. CP가 "테스트 종료" 입력
9. 보고서 작성 완료 (ai_bridge/report/big_079_1_report.md)
