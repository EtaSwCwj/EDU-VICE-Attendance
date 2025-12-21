# SMALL_011_01_EXECUTE.md

> **빅스텝**: BIG_011_REAL_FAIL.md

---

## 📋 작업 내용

# BIG_011: 실제 실패 테스트

> **작성자**: Desktop Opus
> **작성일**: 2025-12-21

---

## 📋 작업

1. flutter_application_1/lib/test_error.dart 파일 생성
2. 일부러 문법 에러 있는 코드 작성:
```dart
class TestError {
  void broken( {
    print("missing parenthesis"
  }
}
```
3. flutter analyze 실행해서 결과 확인

---

**주의: 에러가 있어야 정상임**


---

**결과는 `C:\gitproject\EDU-VICE-Attendance\ai_bridge\result\small_011_01_result.md`에 저장할 것.**
