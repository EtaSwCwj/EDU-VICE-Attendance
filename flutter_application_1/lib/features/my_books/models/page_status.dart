/// 페이지 등록 상태
enum PageStatus {
  /// 미등록 - 아무것도 없음
  notRegistered,
  
  /// 정답만 등록됨 - 정답지 PDF에서 추출
  answerOnly,
  
  /// 문제 등록됨 - 촬영 + 분할 완료
  problemRegistered,
  
  /// 개념/설명 등록됨 (향후 확장)
  conceptRegistered,
  
  /// 완전 등록 - 문제 + 정답 모두
  complete,
}

/// 페이지 상태에 따른 색상
extension PageStatusColor on PageStatus {
  /// 페이지 맵에서 사용할 색상 코드
  int get colorValue {
    switch (this) {
      case PageStatus.notRegistered:
        return 0xFFBDBDBD; // 회색
      case PageStatus.answerOnly:
        return 0xFF2196F3; // 파란색
      case PageStatus.problemRegistered:
        return 0xFF4CAF50; // 녹색
      case PageStatus.conceptRegistered:
        return 0xFFFFC107; // 노란색 (향후)
      case PageStatus.complete:
        return 0xFF8BC34A; // 연두색 (문제+정답)
    }
  }
  
  String get label {
    switch (this) {
      case PageStatus.notRegistered:
        return '미등록';
      case PageStatus.answerOnly:
        return '정답만';
      case PageStatus.problemRegistered:
        return '문제등록';
      case PageStatus.conceptRegistered:
        return '개념등록';
      case PageStatus.complete:
        return '완료';
    }
  }
}
