import 'dart:async';
import 'package:flutter/material.dart';

// Amplify
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

// 생성되어 있는 설정파일 (amplify pull 산출물)
import 'amplifyconfiguration.dart';

// 스모크 테스트 페이지
import 'features/dev/aws_smoketest_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initAmplifyOnce();
  runApp(const EVAttendanceApp());
}

bool _amplifyConfigured = false;
Future<void> _initAmplifyOnce() async {
  if (_amplifyConfigured) return;

  try {
    // 플러그인 등록
    final api = AmplifyAPI(); // AppSync(GraphQL)
    final auth = AmplifyAuthCognito(); // Cognito (로그인 붙일 때 사용)
    Amplify.addPlugins([api, auth]);

    // 설정 적용 (1회만)
    await Amplify.configure(amplifyconfig);
    _amplifyConfigured = true;
    safePrint('[Amplify] configure: SUCCESS');
  } on AmplifyAlreadyConfiguredException {
    _amplifyConfigured = true;
    safePrint('[Amplify] already configured. Skip.');
  } catch (e, st) {
    safePrint('[Amplify] configure: ERROR -> $e');
    safePrint(st.toString());
    rethrow; // 초기화 실패는 테스트 진행 불가하므로 상위로 전달
  }
}

class EVAttendanceApp extends StatelessWidget {
  const EVAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EDU-VICE Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AwsSmokeTestPage(),
    );
  }
}
