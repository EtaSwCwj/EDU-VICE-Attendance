# BIG_099: OCR 미감지 문제 재검사 로직 추가

> 생성일: 2025-12-27
> 작업자: Claude Code (Sonnet)
> 목표: 미감지 문제를 기존 좌표 기반으로 예측하고 재검사

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 대상 파일: lib/features/textbook/ocr_test_page.dart
- 플랫폼: Android (flutter run -d <device>)

---

## 🎯 문제 상황

### 현재 동작
```
Section A: 문제 1, 2, 3, 4 예상
OCR 결과: 1번(y=100), 2번(y=200), 4번(y=400) 감지
         3번 미감지 → ocrFound: false로 끝 ❌
```

### 원하는 동작
```
감지된 좌표: 1번(y=100), 2번(y=200), 4번(y=400)
평균 간격 계산: (200-100 + 400-200) / 2 = 150px
3번 예상 위치: 2번(y=200) + 150 = y=350 근처
→ y=300~400 영역 crop → OCR 재시도
→ 여전히 못 찾으면 균등 분할로 fallback
```

---

## 스몰스텝

### 1. 현재 코드 확인

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
cat lib/features/textbook/ocr_test_page.dart | head -600 | tail -150
```

`_findProblemNumbersWithOCR` 함수와 `_runExtraction` 함수 확인

---

### 2. 새 함수 추가: `_retryMissingProblems`

`_findProblemNumbersWithOCR` 함수 아래에 추가:

```dart
/// 미감지 문제 재검사 (기존 좌표 기반 예측)
Future<List<Map<String, int>>> _retryMissingProblems({
  required File sectionImage,
  required List<Map<String, int>> foundPositions,
  required List<int> missingNumbers,
  required int expectedCount,
  required String sectionName,
}) async {
  if (foundPositions.length < 2 || missingNumbers.isEmpty) {
    safePrint('[Retry] 재검사 스킵: found=${foundPositions.length}, missing=${missingNumbers.length}');
    return [];
  }

  final bytes = await sectionImage.readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) return [];

  // 1. 평균 간격 계산
  final yPositions = foundPositions.map((p) => p['y']!).toList()..sort();
  double totalGap = 0;
  for (int i = 1; i < yPositions.length; i++) {
    totalGap += yPositions[i] - yPositions[i - 1];
  }
  final avgGap = totalGap / (yPositions.length - 1);
  safePrint('[Retry] $sectionName 평균 간격: ${avgGap.round()}px');

  final retryFound = <Map<String, int>>[];
  final tempDir = await getTemporaryDirectory();

  // 2. 각 미감지 문제에 대해 예상 위치 계산 후 재검사
  for (final missingNum in missingNumbers) {
    // 예상 위치 계산
    int? predictedY;
    
    // 방법 1: 앞뒤 문제 사이 보간
    final prevFound = foundPositions.where((p) => p['number']! < missingNum).toList();
    final nextFound = foundPositions.where((p) => p['number']! > missingNum).toList();
    
    if (prevFound.isNotEmpty && nextFound.isNotEmpty) {
      // 앞뒤 문제가 모두 있으면 선형 보간
      final prev = prevFound.reduce((a, b) => a['number']! > b['number']! ? a : b);
      final next = nextFound.reduce((a, b) => a['number']! < b['number']! ? a : b);
      final gap = next['y']! - prev['y']!;
      final numGap = next['number']! - prev['number']!;
      predictedY = prev['y']! + (gap * (missingNum - prev['number']!) ~/ numGap);
      safePrint('[Retry] $sectionName.$missingNum: 보간 예측 y=$predictedY');
    } else if (prevFound.isNotEmpty) {
      // 앞 문제만 있으면 평균 간격으로 예측
      final prev = prevFound.reduce((a, b) => a['number']! > b['number']! ? a : b);
      predictedY = prev['y']! + (avgGap * (missingNum - prev['number']!)).round();
      safePrint('[Retry] $sectionName.$missingNum: 앞 기준 예측 y=$predictedY');
    } else if (nextFound.isNotEmpty) {
      // 뒤 문제만 있으면 역산
      final next = nextFound.reduce((a, b) => a['number']! < b['number']! ? a : b);
      predictedY = next['y']! - (avgGap * (next['number']! - missingNum)).round();
      safePrint('[Retry] $sectionName.$missingNum: 뒤 기준 예측 y=$predictedY');
    }

    if (predictedY == null) continue;

    // 3. 예상 위치 주변 영역 crop (±평균간격의 50%)
    final margin = (avgGap * 0.5).round();
    final cropY = (predictedY - margin).clamp(0, image.height - 1);
    final cropHeight = (avgGap * 1.2).round().clamp(1, image.height - cropY);

    final cropImg = img.copyCrop(
      image,
      x: 0,
      y: cropY,
      width: image.width,
      height: cropHeight,
    );

    final cropFile = File('${tempDir.path}/retry_${sectionName}_$missingNum.png');
    await cropFile.writeAsBytes(img.encodePng(cropImg));

    safePrint('[Retry] $sectionName.$missingNum: crop y=$cropY~${cropY + cropHeight}');

    // 4. OCR 재시도
    try {
      final inputImage = InputImage.fromFile(cropFile);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          
          final isMatch = text == '$missingNum' ||
              text == '$missingNum.' ||
              text.startsWith('$missingNum ') ||
              text.startsWith('$missingNum. ') ||
              RegExp('^$missingNum\\s').hasMatch(text) ||
              RegExp('^$missingNum\\.\\s').hasMatch(text);

          if (isMatch) {
            final boundingBox = line.boundingBox;
            if (boundingBox != null) {
              // crop 영역 내 좌표 → 원본 좌표로 변환
              final originalY = cropY + boundingBox.top.round();
              retryFound.add({
                'number': missingNum,
                'y': originalY,
              });
              safePrint('[Retry] ✅ $sectionName.$missingNum 발견! y=$originalY');
              break;
            }
          }
        }
        if (retryFound.any((p) => p['number'] == missingNum)) break;
      }
    } catch (e) {
      safePrint('[Retry] OCR 오류: $e');
    }
  }

  return retryFound;
}
```

---

### 3. `_runExtraction` 함수 수정

기존 코드에서 "못 찾은 문제 표시" 부분 찾기:

```dart
// 5. 못 찾은 문제 표시
for (int num = 1; num <= expectedCount; num++) {
  final found = ocrPositions.any((p) => p['number'] == num);
  if (!found) {
    problems.add(ExtractedProblem(
```

이 부분을 다음으로 교체:

```dart
// 5. 못 찾은 문제 재검사
final missingNumbers = <int>[];
for (int num = 1; num <= expectedCount; num++) {
  if (!ocrPositions.any((p) => p['number'] == num)) {
    missingNumbers.add(num);
  }
}

if (missingNumbers.isNotEmpty) {
  safePrint('[Extract] $sectionName 미감지: $missingNumbers → 재검사');
  
  final retryResults = await _retryMissingProblems(
    sectionImage: sectionFile,
    foundPositions: ocrPositions,
    missingNumbers: missingNumbers,
    expectedCount: expectedCount,
    sectionName: sectionName,
  );
  
  // 재검사 성공한 것들 추가
  ocrPositions.addAll(retryResults);
  ocrPositions.sort((a, b) => a['y']!.compareTo(b['y']!));
  
  safePrint('[Extract] $sectionName 재검사 후: ${ocrPositions.length}/$expectedCount');
}

// 6. 각 문제별로 crop (재검사 결과 포함)
for (int i = 0; i < ocrPositions.length; i++) {
```

그리고 기존 "각 문제별로 crop" 주석 번호를 4→6으로 변경

---

### 4. 최종 미감지 처리 (균등 분할 fallback)

기존 "못 찾은 문제 표시" 부분을 수정:

```dart
// 7. 여전히 못 찾은 문제 → 균등 분할 fallback
for (int num = 1; num <= expectedCount; num++) {
  final found = ocrPositions.any((p) => p['number'] == num);
  if (!found) {
    // 균등 분할로 예측
    final estimatedYStart = (num - 1) / expectedCount * 100;
    final estimatedYEnd = num / expectedCount * 100;
    
    safePrint('[Extract] $sectionName.$num: 균등분할 fallback ${estimatedYStart.toInt()}%~${estimatedYEnd.toInt()}%');
    
    problems.add(ExtractedProblem(
      section: sectionName,
      number: num,
      yStart: estimatedYStart,
      yEnd: estimatedYEnd,
      answer: pageDB.getAnswer(sectionName, num),
      imageFile: null,  // TODO: 균등 분할로 crop 추가 가능
      ocrFound: false,
    ));
  }
}
```

---

### 5. import 확인

파일 상단에 이미 있어야 함:
```dart
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
```

---

### 6. flutter analyze

```bash
flutter analyze lib/features/textbook/ocr_test_page.dart
```

에러 0개 확인

---

### 7. 테스트

```bash
flutter run -d <device>
```

**테스트 시나리오:**
1. 카메라로 Grammar Effect 2 p.9 또는 p.11 촬영
2. "Step 5: 문제 추출하기" 클릭
3. 로그 확인:
   - `[OCR] A: 1 발견` 등 초기 감지
   - `[Extract] A 미감지: [3]` 등 미감지 목록
   - `[Retry] A 평균 간격: 150px` 등 간격 계산
   - `[Retry] A.3: 보간 예측 y=350` 등 예측
   - `[Retry] ✅ A.3 발견! y=352` 등 재검사 성공
4. UI에서 감지율 확인 (예: "4/4 감지")

---

## 완료 조건

1. ✅ `_retryMissingProblems` 함수 추가
2. ✅ `_runExtraction`에서 재검사 로직 호출
3. ✅ 균등 분할 fallback 구현
4. ✅ flutter analyze 에러 0개
5. ✅ 로그에서 재검사 과정 확인
6. ✅ 감지율 개선 확인 (테스트)

---

## 로그 확인 포인트

```
[Retry] A 평균 간격: XXXpx          ← 간격 계산 OK?
[Retry] A.3: 보간 예측 y=XXX        ← 예측 위치 합리적?
[Retry] A.3: crop y=XXX~XXX        ← crop 범위 적절?
[Retry] ✅ A.3 발견! y=XXX          ← 재검사 성공?
[Extract] A 재검사 후: X/Y          ← 최종 감지율?
```

---

## 보고서

ai_bridge/report/big_099_report.md

```markdown
# BIG_099 보고서

## 작업 결과
- [ ] _retryMissingProblems 함수 추가
- [ ] _runExtraction 수정
- [ ] flutter analyze 통과
- [ ] 테스트 결과

## 로그 샘플
(실제 로그 붙여넣기)

## 감지율 변화
- Before: X/Y
- After: X/Y

## 이슈
(있으면 기록)
```
