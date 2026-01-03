/// 페이지 등록 상태 (문제 촬영 기준)
enum PageStatus {
  /// 미등록 - 촬영 안됨
  notRegistered,
  
  /// 촬영됨 - 문제 촬영 완료
  captured,
}

/// 페이지 상태에 따른 색상
extension PageStatusColor on PageStatus {
  /// 페이지 맵에서 사용할 색상 코드
  int get colorValue {
    switch (this) {
      case PageStatus.notRegistered:
        return 0xFFBDBDBD; // 회색
      case PageStatus.captured:
        return 0xFF4CAF50; // 녹색
    }
  }
  
  String get label {
    switch (this) {
      case PageStatus.notRegistered:
        return '미촬영';
      case PageStatus.captured:
        return '촬영완료';
    }
  }
}
