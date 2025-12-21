# 자주 쓰는 패턴

> 이 문서는 반복되는 작업의 패턴을 정리합니다.
> "이거 어떻게 하더라?" 할 때 참고하세요.

---

## 📝 빅스텝 작성 패턴

### 기본 템플릿

```markdown
# BIG_XXX: 제목

> **작성자**: Desktop Opus
> **작성일**: YYYY-MM-DD

---

## 📋 작업

(구체적인 작업 내용)

1. 첫 번째 할 일
2. 두 번째 할 일

## 📋 주의사항 (선택)

- 특별히 주의할 점
```

### 코드 작업

```markdown
## 📋 작업

lib/features/xxx/xxx_page.dart 파일 수정:
1. OOO 기능 추가
2. flutter analyze 에러 0개 확인
```

### 분석 작업

```markdown
## 📋 작업

XXX 현재 구현 상태 분석:
1. 구현 완료된 것
2. 미구현된 것
3. 버그나 문제점
4. 결과 상세히 보고
```

### 커밋 작업

```markdown
## 📋 작업

```bash
git add -A
git commit -m "feat: 커밋 메시지"
git push origin dev
```
```

### 서버 실행

```markdown
## 📋 작업

```bash
call C:\gitproject\EDU-VICE-Attendance\scripts\start_web.bat
```
```

---

## 🔧 코드 패턴

### 웹 플랫폼 체크

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

if (!kIsWeb) {
  // 모바일/데스크톱 전용
}
```

### GraphQL API 호출

```dart
final request = ModelQueries.list(ModelType.classType);
final response = await Amplify.API.query(request: request).response;
```

### S3 업로드

```dart
final result = await Amplify.Storage.uploadFile(
  localFile: AWSFile.fromPath(filePath),
  path: StoragePath.fromString('public/profiles/$userId.jpg'),
).result;
```

### Cognito 사용자 정보

```dart
final user = await Amplify.Auth.getCurrentUser();
final userId = user.userId;  // Cognito sub
```

---

## 🐛 자주 발생하는 에러

### MissingPluginException (웹)

**원인**: 웹에서 지원 안 되는 플러그인

**해결**:
```dart
if (!kIsWeb) {
  plugins.add(AmplifyDataStore(...));
}
```

### flutter analyze 에러

**해결 순서**:
1. 에러 메시지 읽기
2. 해당 파일/라인 수정
3. 다시 flutter analyze
4. 에러 0개 될 때까지 반복

### git index.lock

**원인**: 다른 git 프로세스 실행 중

**해결**:
```bash
del .git\index.lock
```

---

## 📂 파일 위치 패턴

### 새 기능 추가 시

```
lib/features/{기능명}/
├── {기능명}_page.dart      # UI
├── {기능명}_state.dart     # 상태
└── widgets/                # 하위 위젯
```

### 서비스 추가 시

```
lib/shared/services/{서비스명}_service.dart
```

### 모델 추가 시

```
lib/models/{모델명}.dart  # Amplify 생성
```

---

## 🔄 재지시 처리 패턴

Manager가 FAIL 판단 시:

1. `SMALL_XXX_02_RETRY.md` 자동 생성
2. Worker 자동 재호출
3. 수정된 결과 제출
4. 다시 교차검증

**무한 루프 주의**: 현재 재시도 횟수 제한 없음 (향후 개선 예정)

---

## 📊 테스트 환경 패턴

### 웹 2계정 동시 테스트

```
창 1: localhost:8080 (일반)
창 2: localhost:8080 (시크릿 모드 Ctrl+Shift+N)
```

### 웹 + 모바일 동시

```
웹: localhost:8080
폰: scrcpy 또는 실제 기기
```

---

## 💡 생산성 팁

### 1. 복잡한 작업 분리

```
❌ BIG_001: "로그인 전체 구현해"

✅ 
BIG_001: "auth_service.dart 만들어"
BIG_002: "login_page.dart 만들어"
BIG_003: "연결해서 테스트해"
```

### 2. 구체적으로 지시

```
❌ "버그 고쳐"

✅ "login_page.dart 45번 라인에서 null 에러 나는데, 
    user가 null일 때 처리 추가해"
```

### 3. 확인 포인트 명시

```
✅ "수정 후 flutter analyze 에러 0개 확인"
✅ "로그인 버튼 누르면 홈으로 이동하는지 확인"
```

---

## 🎯 Phase 2 관련 패턴

### 초대 시스템

- 초대 코드: 6자리, 혼동 문자 제외
- 만료: 7일
- 서비스: `invitation_service.dart`

### 역할 계층

```
관리자 > 원장 > 선생 > 학생 > 서포터
```

### 컨텍스트 스위칭

- 한 사람이 여러 역할 가능
- Academy 선택 → Role 결정 → Shell 라우팅
