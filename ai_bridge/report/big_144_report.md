# BIG_144: ML Kit Korean 모델 크래시 원인 분석 보고서

## 작업 일시
- 2026년 1월 4일

## 작업 목표
ML Kit Korean 모델 적용 시 발생하는 앱 크래시의 원인 파악 및 해결 방안 제시

## 크래시 원인 분석

### 1. 핵심 에러
```
java.lang.NoClassDefFoundError: Failed resolution of: Lcom/google/mlkit/vision/text/korean/KoreanTextRecognizerOptions$Builder;

Caused by: java.lang.ClassNotFoundException: Didn't find class "com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder"
```

### 2. 에러 발생 위치
- 파일: `lib/shared/services/mlkit_ocr_service.dart` (9번째 줄)
- 변경한 코드:
```dart
// 기존
final _textRecognizer = TextRecognizer();

// 변경 (크래시 발생)
final _textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
```

### 3. 원인
- **Korean 텍스트 인식 모듈 부재**: 현재 프로젝트에는 기본 Latin 텍스트 인식만 포함됨
- **의존성 문제**: `google_mlkit_text_recognition: ^0.13.1`은 Latin 모델만 포함
- **클래스 누락**: Korean 모델을 위한 `KoreanTextRecognizerOptions` 클래스가 앱에 포함되지 않음

## 해결 방안

### 방안 1: 다국어 지원 확인 (권장)
1. ML Kit의 최신 버전에서 Korean 지원 여부 확인
2. `google_mlkit_text_recognition` 패키지 문서에서 Korean 스크립트 설정 방법 확인
3. 필요시 추가 의존성이나 설정 적용

### 방안 2: 대체 OCR 솔루션
1. **Google Cloud Vision API**: Korean 지원 확실
2. **Tesseract OCR**: Korean 언어 팩 설치 가능
3. **Azure Computer Vision**: 한글 인식 지원

### 방안 3: 하이브리드 접근
1. 숫자/영문: ML Kit Latin 모델 사용 (현재 동작)
2. 한글 텍스트: Claude Vision API 활용 (이미 구현됨)
3. 필요시 별도의 한글 OCR 서비스 연동

## 즉시 적용 가능한 임시 해결책

```dart
// mlkit_ocr_service.dart
class MLKitOcrService {
  // Korean 모델이 준비될 때까지 Latin 모델 유지
  final _textRecognizer = TextRecognizer(); // Latin only

  // 한글 인식이 필요한 경우 Claude Vision API 사용
  // 또는 인식 결과 후처리로 한글 매핑 (예: "D" → "동사")
}
```

## 검증된 사실
- ✅ PDF → 이미지 변환 정상 작동
- ✅ 영문/숫자 인식 정상 (Latin 모델)
- ✅ Claude Vision API로 섹션 분석 가능
- ❌ ML Kit Korean 모델 직접 사용 불가 (클래스 없음)

## 권장 사항
1. **단기**: Latin 모델 유지 + Claude Vision으로 한글 처리
2. **중기**: ML Kit 최신 버전 확인 및 Korean 지원 방법 조사
3. **장기**: 필요시 전용 한글 OCR 솔루션 도입

## 결론
크래시는 ML Kit Korean 텍스트 인식 클래스가 프로젝트에 포함되지 않아 발생했습니다. 현재 버전의 `google_mlkit_text_recognition`은 Latin 모델만 기본 제공하며, Korean 모델을 사용하려면 추가 설정이나 다른 패키지가 필요합니다.