# BIG_145: Korean OCR 모델 적용 후 인식 오류 분석

> 생성일: 2026-01-04
> 목표: Korean 모델 추가 후 발생한 OCR 인식 오류 원인 파악

---

## ⚠️ Opus 필수: 템플릿 먼저 읽어!

```
ai_bridge/templates/BIGSTEP_TEMPLATE.md
```

**템플릿의 체크리스트 확인 후 작업 진행할 것!**

---

## 🎯 현재 상황

### 이전 (Latin 모델)
- ✅ Page 9 정상 인식
- ✅ A/B/C/D 섹션 모두 인식
- ✅ 영어 정답 정상 (wrote, My teacher, great, dinner)
- ❌ 한글만 깨짐 (목적어 → 0, 동사 → D)

### 현재 (Korean 모델 추가 후)
- ❌ Page 0으로 잘못 인식
- ❌ D) 섹션만 나옴 (A/B/C 없음)
- ❌ 내용도 완전히 다름 (too heavy for her to pick up...)

### 변경한 것
1. `android/app/build.gradle`에 Korean 모델 추가:
```groovy
implementation 'com.google.mlkit:text-recognition-korean:16.0.0'
```

2. `mlkit_ocr_service.dart`에서 Korean 스크립트 사용:
```dart
final _textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
```

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 수정 파일: 
  - android/app/build.gradle
  - lib/shared/services/mlkit_ocr_service.dart
- 테스트 기기: RFCY40MNBLL (Galaxy A35)

---

## 🎯 분석 포인트

### 의심되는 원인들
1. **Korean 모델이 영어를 못 읽음?** - Korean 전용이라 영어 인식률 떨어짐
2. **열 분리 순서 문제?** - 재귀 분리 후 파일 순서가 바뀜
3. **OCR 텍스트 자체가 다름** - Korean 모델이 다른 방식으로 읽음
4. **AI 파싱 문제** - OCR은 정상인데 AI가 잘못 해석

---

## 스몰스텝

### 1. OCR 로그 수집

- [ ] 전체 로그 저장:
```powershell
adb logcat -d > C:\temp\korean_ocr_full.txt
```

- [ ] OCR 관련 필터링:
```powershell
findstr "OCR\|AnswerParser\|Claude\|PdfToImage\|Split" C:\temp\korean_ocr_full.txt > C:\temp\korean_ocr_filtered.txt
```

- [ ] 핵심 로그 확인 (OCR 텍스트 원본):
```powershell
findstr "OCR 앞\|OCR 전체\|OCR 총" C:\temp\korean_ocr_full.txt
```

### 2. OCR 텍스트 분석

- [ ] OCR 텍스트 원본 확인 (AI 파싱 전)
  - 페이지 번호 패턴 있나? (p. 9, p. 27 등)
  - 섹션 패턴 있나? (A), B), C), D))
  - 한글이 제대로 읽히나?

- [ ] Latin 모델 때와 비교
  - 어떤 부분이 달라졌나?

### 3. 열 분리 이미지 확인

- [ ] DCIM/flutter_1 폴더의 이미지 목록 확인:
```powershell
adb shell ls -la /storage/emulated/0/DCIM/flutter_1/
```

- [ ] 이미지 순서 확인
  - 파일명과 실제 내용이 맞는지
  - col1이 왼쪽 열인지

### 4. 원인 파악 후 해결책 제시

- [ ] 로그 분석 결과 정리
- [ ] 원인 명확히 기술
- [ ] 해결 방안 제시:
  - Korean 모델 문제면 → 설정 변경 또는 하이브리드 방식
  - 열 분리 순서 문제면 → 파일명/순서 로직 수정
  - AI 파싱 문제면 → 프롬프트 수정

---

## ⚠️ 핵심: 비교 분석!

**Latin 모델 때 vs Korean 모델 후**

| 항목 | Latin (이전) | Korean (현재) |
|------|-------------|---------------|
| 페이지 번호 | Page 9 ✅ | Page 0 ❌ |
| 섹션 | A/B/C/D ✅ | D만 ❌ |
| 영어 정답 | 정상 ✅ | ? |
| 한글 정답 | 깨짐 ❌ | ? |

이 차이가 어디서 발생하는지 찾아야 함.

---

## 로그 저장

- ai_bridge/logs/big_145_ocr_comparison.log (Latin vs Korean 비교)
- ai_bridge/logs/big_145_analysis.log (분석 결과)

---

## 완료 조건

1. OCR 로그 수집 완료
2. Latin vs Korean 차이점 명확히 파악
3. 문제 원인 특정
4. 해결 방안 제시
5. 보고서 작성 완료 (ai_bridge/report/big_145_report.md)
