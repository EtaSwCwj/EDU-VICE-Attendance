// lib/app/app_env.dart
//
// [20-4 fix] --dart-define 기반 환경(AppFlavor) 지정 (final 기반, const 강제 제거)
// 원인: 이전 버전은 파싱 흐름을 const로 억지로 만들다 분석기 에러가 발생.
// 해결: 컴파일 타임 상수로 유지할 필요가 없는 부분을 final로 전환.
//
// 사용 예:
//  - 기본(dev 폴백): flutter run
//  - 명시적 dev:    flutter run --dart-define=APP_FLAVOR=dev
//  - prod 스위치:   flutter run --dart-define=APP_FLAVOR=prod
//
// 연결 지점:
//  - app_providers.dart 의 _buildAttendanceRepository() 가 currentFlavor를 읽어 구현 분기

/// 앱 실행 환경(플레이버) 정의
enum AppFlavor { dev, prod }

/// --dart-define 로부터 읽어온 원시 값(없으면 빈 문자열)
const String _envFlavorRaw =
    String.fromEnvironment('APP_FLAVOR', defaultValue: '');

/// 문자열을 AppFlavor로 파싱(대소문자 무시). 실패 시 dev 반환.
AppFlavor _parseFlavor(String raw) {
  final v = raw.trim().toLowerCase();
  switch (v) {
    case 'prod':
    case 'production':
    case 'release':
      return AppFlavor.prod;
    case 'dev':
    case 'development':
    case '':
      return AppFlavor.dev;
    default:
      // 예기치 않은 값이면 안전하게 dev로 폴백
      return AppFlavor.dev;
  }
}

/// 현재 실행 환경.
/// - 기본은 dev, --dart-define=APP_FLAVOR=prod 로 운영 전환 가능.
/// - (20-3 기준) prod도 임시로 LocalRepo 사용. 이후 단계에서 AWS로 교체.
final AppFlavor currentFlavor = _parseFlavor(_envFlavorRaw);

/// 간단 헬퍼: 디버깅/로깅 조건 분기에 사용 가능
extension AppFlavorX on AppFlavor {
  bool get isDev => this == AppFlavor.dev;
  bool get isProd => this == AppFlavor.prod;

  String get name {
    switch (this) {
      case AppFlavor.dev:
        return 'dev';
      case AppFlavor.prod:
        return 'prod';
    }
  }
}
