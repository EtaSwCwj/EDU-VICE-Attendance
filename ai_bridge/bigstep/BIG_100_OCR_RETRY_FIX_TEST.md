# BIG_100: OCR 재검사 조건 수정 + 테스트

> 작업자: Claude Code (Sonnet)

---

## 1. 코드 수정

파일: `lib/features/textbook/ocr_test_page.dart`

### 수정 1: 재검사 스킵 조건 완화

찾기:
```dart
if (foundPositions.length < 2 || missingNumbers.isEmpty) {
```

변경:
```dart
if (foundPositions.isEmpty || missingNumbers.isEmpty) {
```

### 수정 2: 1개만 찾았을 때 간격 추정

찾기:
```dart
// 1. 평균 간격 계산
final yPositions = foundPositions.map((p) => p['y']!).toList()..sort();
double totalGap = 0;
for (int i = 1; i < yPositions.length; i++) {
  totalGap += yPositions[i] - yPositions[i - 1];
}
final avgGap = totalGap / (yPositions.length - 1);
safePrint('[Retry] $sectionName 평균 간격: ${avgGap.round()}px');
```

변경:
```dart
// 1. 평균 간격 계산
final yPositions = foundPositions.map((p) => p['y']!).toList()..sort();
double avgGap;
if (yPositions.length >= 2) {
  double totalGap = 0;
  for (int i = 1; i < yPositions.length; i++) {
    totalGap += yPositions[i] - yPositions[i - 1];
  }
  avgGap = totalGap / (yPositions.length - 1);
} else {
  avgGap = image.height / expectedCount;
  safePrint('[Retry] 1개만 찾음 → 추정 간격: ${avgGap.round()}px');
}
safePrint('[Retry] $sectionName 평균 간격: ${avgGap.round()}px');
```

---

## 2. flutter analyze

```bash
flutter analyze lib/features/textbook/ocr_test_page.dart
```

---

## 3. 앱 실행 + 테스트

```bash
flutter run -d RFCY40MNBLL
```

폰에서:
1. 교재 탭 → 자동 문제 추출
2. 카메라로 촬영
3. "Step 5: 문제 추출하기" 클릭

---

## 4. 로그 저장

터미널에 찍힌 로그 중 `[OCR]`, `[Extract]`, `[Retry]` 포함된 줄만 추출해서 저장:

```
ai_bridge/logs/big_100_test.log
```

---

## 5. 보고서

```
ai_bridge/report/big_100_report.md
```

로그 기반으로:
- 1차 OCR 감지율
- 재검사 시도 여부
- 재검사 성공 여부
- 최종 감지율
