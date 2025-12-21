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
