// lib/config/app_config.dart

enum Environment { development, staging, production }

/// 앱 환경 설정
class AppConfig {
  final Environment environment;
  final String appName;
  final String apiBaseUrl;
  final String cognitoUserPoolId;
  final String cognitoAppClientId;
  final bool enableLogging;
  final bool enableMockData;

  const AppConfig({
    required this.environment,
    required this.appName,
    required this.apiBaseUrl,
    required this.cognitoUserPoolId,
    required this.cognitoAppClientId,
    this.enableLogging = false,
    this.enableMockData = false,
  });

  /// Development 환경 설정
  factory AppConfig.development() {
    return const AppConfig(
      environment: Environment.development,
      appName: 'EDU-VICE Attendance (Dev)',
      apiBaseUrl: 'https://dev-api.eduvice.com',
      cognitoUserPoolId: 'dev-user-pool-id',
      cognitoAppClientId: 'dev-app-client-id',
      enableLogging: true,
      enableMockData: true,
    );
  }

  /// Staging 환경 설정
  factory AppConfig.staging() {
    return const AppConfig(
      environment: Environment.staging,
      appName: 'EDU-VICE Attendance (Staging)',
      apiBaseUrl: 'https://staging-api.eduvice.com',
      cognitoUserPoolId: 'staging-user-pool-id',
      cognitoAppClientId: 'staging-app-client-id',
      enableLogging: true,
      enableMockData: false,
    );
  }

  /// Production 환경 설정
  factory AppConfig.production() {
    return const AppConfig(
      environment: Environment.production,
      appName: 'EDU-VICE Attendance',
      apiBaseUrl: 'https://api.eduvice.com',
      cognitoUserPoolId: 'prod-user-pool-id',
      cognitoAppClientId: 'prod-app-client-id',
      enableLogging: false,
      enableMockData: false,
    );
  }

  /// 환경 변수에서 설정 가성
  factory AppConfig.fromEnvironment() {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');

    switch (env) {
      case 'staging':
        return AppConfig.staging();
      case 'production':
        return AppConfig.production();
      default:
        return AppConfig.development();
    }
  }

  bool get isDevelopment => environment == Environment.development;
  bool get isStaging => environment == Environment.staging;
  bool get isProduction => environment == Environment.production;
}
