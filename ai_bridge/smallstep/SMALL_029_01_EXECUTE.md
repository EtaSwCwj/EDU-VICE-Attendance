# SMALL_029_01_EXECUTE.md

> **빅스텝**: BIG_029_WEB_DATASTORE.md
> **작업 유형**: code

---

## 📋 작업 내용

# BIG_029: 웹 플랫폼 DataStore 이슈 해결

> **작성자**: Desktop Opus
> **작성일**: 2025-12-21

---

## 📋 문제

웹에서 Amplify DataStore 초기화 시 MissingPluginException 발생.

## 📋 작업

1. main.dart 또는 amplify 초기화 부분 찾기
2. 웹 플랫폼일 때 DataStore 초기화 건너뛰도록 수정

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

// 웹이 아닐 때만 DataStore 설정
if (!kIsWeb) {
  // DataStore 초기화
}
```

3. flutter analyze 에러 0개 확인


---

## 실행 지침

1. 위 빅스텝 내용을 정확히 수행하세요
2. 중간에 확인 묻지 말고 끝까지 진행하세요
3. 작업 완료 후 결과 파일 생성 필수

**결과는 `C:\gitproject\EDU-VICE-Attendance\ai_bridge\result\small_029_01_result.md`에 저장할 것.**
