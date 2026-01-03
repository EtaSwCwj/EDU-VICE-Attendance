# BIG_144: ML Kit Korean 모델 크래시 원인 분석

> 생성일: 2026-01-04
> 목표: Korean 모델 크래시 원인 파악 후 해결

---

## ⚠️ Opus 필수: 템플릿 먼저 읽어!

```
ai_bridge/templates/BIGSTEP_TEMPLATE.md
```

**템플릿의 체크리스트 확인 후 작업 진행할 것!**

---

## 🎯 현재 상황

### 완료된 것
- ✅ PDF → 이미지 변환
- ✅ 비율 기반 재귀 열 분리 (가로/세로 > 0.7 이면 2등분)
- ✅ 페이지 번호 인식 (Page 9 정상)
- ✅ 영어 정답 인식 (wrote, My teacher 등)

### 문제
- ❌ 한글 인식 실패 (Latin 모델이라 목적어 → 0, 동사 → D)
- ❌ ML Kit Korean 모델로 변경 후 앱 크래시

### 변경한 코드
```dart
// 파일: lib/shared/services/mlkit_ocr_service.dart (9줄)
// 기존
final _textRecognizer = TextRecognizer();

// 변경
final _textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
```

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 수정 파일: lib/shared/services/mlkit_ocr_service.dart
- 테스트 기기: RFCY40MNBLL (Galaxy A35)

---

## 스몰스텝

### 1. 크래시 로그 수집

- [ ] 전체 로그 저장:
```powershell
adb logcat -d > C:\temp\crash_log_full.txt
```

- [ ] 크래시 관련 필터링:
```powershell
findstr /i "fatal crash exception error mlkit korean TextRecognizer" C:\temp\crash_log_full.txt > C:\temp\crash_filtered.txt
```

- [ ] Flutter 로그 필터링:
```powershell
findstr "flutter" C:\temp\crash_log_full.txt > C:\temp\crash_flutter.txt
```

### 2. 크래시 원인 분석

- [ ] crash_filtered.txt 열어서 핵심 에러 메시지 확인
- [ ] 에러 유형 파악:
  - `UnsatisfiedLinkError` → 네이티브 라이브러리 문제
  - `ModelDownloadException` → 모델 다운로드 실패
  - `IllegalArgumentException` → 잘못된 파라미터
  - `NullPointerException` → 초기화 문제
  - 기타

- [ ] 핵심 로그 정리해서 저장:
```
ai_bridge/logs/big_144_crash_analysis.log
```

### 3. 원인에 따른 해결책 제시

- [ ] 로그 분석 결과 기반으로 해결 방안 정리
- [ ] 보고서 작성 (ai_bridge/report/big_144_report.md)

---

## ⚠️ 핵심: 롤백 금지!

**크래시 원인 파악 없이 롤백하지 말 것.**
원인 알아야 제대로 된 해결책 나온다.

---

## 크래시 로그에서 찾을 키워드

```
FATAL EXCEPTION
AndroidRuntime
java.lang.
com.google.mlkit
TextRecognizer
korean
model
download
native
link
```

---

## 완료 조건

1. 크래시 로그 수집 완료
2. 크래시 원인 명확히 파악
3. 해결 방안 제시
4. 보고서 작성 완료 (ai_bridge/report/big_144_report.md)
