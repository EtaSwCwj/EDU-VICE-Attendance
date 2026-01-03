# BIG_146: ML Kit Korean 모델 로딩 확인 및 수정

> 생성일: 2026-01-04
> 목표: Korean 모델이 실제로 로드되는지 확인하고 한글 인식 정상화

---

## ⚠️ Opus 필수: 템플릿 먼저 읽어!

```
ai_bridge/templates/BIGSTEP_TEMPLATE.md
```

**템플릿의 체크리스트 확인 후 작업 진행할 것!**

---

## 🎯 현재 상황

### 적용한 것
1. `android/app/build.gradle`:
```groovy
implementation 'com.google.mlkit:text-recognition-korean:16.0.0'
```

2. `lib/shared/services/mlkit_ocr_service.dart`:
```dart
final _textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
```

### 문제
- 한글이 여전히 깨짐: `7 484 R'gve+ZI0+E 384|`
- Korean 모델이 실제로 로드 안 되는 것으로 추정

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 파일들:
  - android/app/build.gradle
  - lib/shared/services/mlkit_ocr_service.dart
- 테스트 기기: RFCY40MNBLL (Galaxy A35)
- 패키지 버전: google_mlkit_text_recognition: ^0.13.1

---

## 스몰스텝

### 1. Flutter ML Kit 패키지 문서 확인

- [ ] google_mlkit_text_recognition 패키지의 Korean 지원 방식 확인
- [ ] 웹 검색 또는 pub.dev 문서 확인:
  - TextRecognitionScript.korean 사용법
  - Android 추가 설정 필요 여부
  - 모델 다운로드 방식 (on-device vs bundled)

### 2. Android 설정 확인

- [ ] `android/app/build.gradle` 확인
  - 현재 추가한 dependency가 맞는지
  - minSdk 버전 호환되는지 (현재 24)

- [ ] `android/app/src/main/AndroidManifest.xml` 확인
  - ML Kit 관련 meta-data 필요한지
  - 예시:
```xml
<meta-data
    android:name="com.google.mlkit.vision.DEPENDENCIES"
    android:value="ocr_korean" />
```

### 3. 로그로 모델 로딩 확인

- [ ] mlkit_ocr_service.dart에 로그 추가:
```dart
safePrint('[MlKitOcr] TextRecognizer 스크립트: korean');
safePrint('[MlKitOcr] 인식된 텍스트 샘플 (앞 100자): ${recognizedText.text.substring(0, min(100, recognizedText.text.length))}');
```

- [ ] 앱 실행 후 로그 확인:
```powershell
adb logcat -d | findstr "MlKitOcr"
```

### 4. 테스트 이미지로 한글 인식 확인

- [ ] 갤러리에서 한글 포함 이미지 선택
- [ ] OCR 결과 확인:
  - 한글이 제대로 읽히면 → Korean 모델 정상
  - 여전히 깨지면 → 설정 문제

### 5. 문제 발견 시 수정

#### 케이스 A: AndroidManifest 설정 누락
- [ ] meta-data 추가 후 재빌드

#### 케이스 B: 패키지 버전 문제
- [ ] google_mlkit_text_recognition 버전 업그레이드 검토

#### 케이스 C: build.gradle dependency 방식 변경 필요
- [ ] bundled 모델 대신 dynamic download 방식 확인

---

## 참고: ML Kit 한글 모델 설정 예시

### AndroidManifest.xml (필요할 수 있음)
```xml
<application>
    <!-- ML Kit 모델 자동 다운로드 -->
    <meta-data
        android:name="com.google.mlkit.vision.DEPENDENCIES"
        android:value="ocr_korean" />
</application>
```

### build.gradle (현재 설정)
```groovy
dependencies {
    implementation 'com.google.mlkit:text-recognition-korean:16.0.0'
}
```

---

## 로그 저장

- ai_bridge/logs/big_146_model_check.log

---

## 완료 조건

1. Korean 모델 로딩 여부 확인
2. 문제 원인 파악
3. 한글 인식 정상화 (목적어, 동사, 수식어 등)
4. flutter analyze 에러 0개
5. 보고서 작성 완료 (ai_bridge/report/big_146_report.md)
