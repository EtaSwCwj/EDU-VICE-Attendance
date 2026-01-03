# BIG_116 보고서

## 구현 내용
- TocEntry 모델: **O** (완료)
- LocalBook 목차 필드: **O** (완료)
- 목차 촬영 페이지: **O** (완료)
- Claude API 메서드: **O** (완료)
- 수정/삭제/추가 기능: **O** (완료)

## 테스트 결과
- 목차 촬영: **O** (정상 작동)
- AI 인식 정확도: **부분적 성공** (일부 페이지만 인식)
- 수정 기능: **미확인** (테스트 미완료)
- 저장 기능: **미확인** (테스트 미완료)

## 문제점
1. **페이지별 인식률 차이**
   - 한 페이지는 정상 인식됨
   - 다른 페이지는 인식 실패
   - 원인: 이미지 품질, 레이아웃 복잡도, 또는 AI 모델의 한계

## 구현 상세

### 1. TocEntry 모델
```dart
class TocEntry extends Equatable {
  final String unitName;
  final int startPage;
  final int? endPage;
}
```

### 2. LocalBook 모델 업데이트
- `tableOfContents: List<TocEntry>` 필드 추가
- fromJson, toJson, copyWith, props 모두 업데이트

### 3. 목차 촬영 페이지 (TocCameraPage)
- CunningDocumentScanner 사용하여 문서 스캔
- 인식된 항목 리스트 표시
- 수정/삭제/추가 기능 구현
- 책 저장 시 목차 데이터 포함

### 4. Claude API 메서드
- `extractTableOfContents(File imageFile)` 추가
- Haiku 모델 사용 (claude-3-5-haiku-20241022)
- JSON 형식으로 단원명과 페이지 번호 추출

### 5. 책 등록 플로우 통합
- 5단계 위자드로 확장 (기존 4단계 → 5단계)
- Step 4: 목차 촬영 (필수)
- 목차가 없으면 다음 단계 진행 불가

## 다음 단계
1. **인식률 개선 필요**
   - 프롬프트 최적화
   - 이미지 전처리 추가 (회전, 크롭, 선명도 조정)
   - 실패 시 재시도 로직

2. **UX 개선**
   - 인식 실패 시 안내 메시지
   - 페이지별 촬영 가이드라인
   - 인식 중 프로그레스 표시

3. **기능 확장**
   - 여러 페이지 일괄 처리
   - 목차 템플릿 제공
   - 인식 결과 검증 로직

## 결론
목차 촬영 기능이 기본적으로 구현되었으나, AI 인식률이 페이지에 따라 불안정한 문제가 있음. 실제 사용을 위해서는 인식률 개선이 필요함.