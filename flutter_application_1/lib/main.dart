import 'dart:convert';

import 'package:flutter/material.dart';

// Amplify
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

// amplify pull 산출물
import 'amplifyconfiguration.dart';

// Pages / Shells
import 'features/dev/aws_smoketest_page.dart';
import 'features/teacher/teacher_shell.dart';
import 'features/home/student_home_shell.dart';

// 새로 추가: DI & Config
import 'config/app_config.dart';
import 'core/di/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // DI 초기화 (선택적)
  try {
    final config = AppConfig.development(); // 개발 환경
    await setupDependencies(config: config);
  } catch (e) {
    // DI 초기화 실패해도 앱은 실행되도록
    safePrint('[DI] Failed to initialize: $e');
  }
  
  runApp(const EVAttendanceApp());
}

class EVAttendanceApp extends StatefulWidget {
  const EVAttendanceApp({super.key});

  @override
  State<EVAttendanceApp> createState() => _EVAttendanceAppState();
}

class _EVAttendanceAppState extends State<EVAttendanceApp> {
  late final Future<void> _amplifyInitFuture;

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _amplifyInitFuture = _initAmplifyOnce();
  }

  Future<void> _initAmplifyOnce() async {
    if (Amplify.isConfigured) return;

    try {
      await Amplify.addPlugins([
        AmplifyAPI(),
        AmplifyAuthCognito(),
      ]);

      await Amplify.configure(amplifyconfig);
      safePrint('[Amplify] configure: SUCCESS');
    } on AmplifyAlreadyConfiguredException {
      safePrint('[Amplify] already configured. Skip.');
    } catch (e, st) {
      safePrint('[Amplify] configure: ERROR -> $e');
      safePrint(st.toString());
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EDU-VICE Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: FutureBuilder<void>(
        future: _amplifyInitFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Startup Error')),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  'Amplify init failed:\n\n${snapshot.error}',
                ),
              ),
            );
          }

          final pages = <Widget>[
            const _RoleHomeRouter(), // ✅ TeacherShell / StudentHomeShell 자동 분기
            const AwsSmokeTestPage(), // ✅ 테스트 보조 탭 유지
          ];

          return Scaffold(
            body: pages[_index],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.cloud_done_outlined),
                  selectedIcon: Icon(Icons.cloud_done),
                  label: 'AWS Test',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Home 탭은 "로그인된 Cognito 그룹" 기준으로 Teacher/Student 셸을 자동 분기한다.
/// - teachers/owners => TeacherShell
/// - students/그 외 => StudentHomeShell
class _RoleHomeRouter extends StatefulWidget {
  const _RoleHomeRouter();

  @override
  State<_RoleHomeRouter> createState() => _RoleHomeRouterState();
}

class _RoleHomeRouterState extends State<_RoleHomeRouter> {
  late final Future<_Role> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = _detectRole();
  }

  Future<_Role> _detectRole() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      final cognitoSession = session as CognitoAuthSession;

      // 토큰을 얻지 못하면(로그인 안 됐거나 실패) -> student로 안전 기본값
      CognitoUserPoolTokens tokens;
      try {
        tokens = cognitoSession.userPoolTokensResult.value;
      } catch (_) {
        return _Role.student;
      }

      final payload = _decodeJwtPayload(tokens.idToken.raw);
      final groups = _extractGroups(payload);

      if (groups.contains('owners') || groups.contains('teachers')) {
        return _Role.teacher;
      }
      return _Role.student;
    } catch (e) {
      safePrint('[RoleDetect] failed -> $e');
      return _Role.student;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Role>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data ?? _Role.student;
        if (role == _Role.teacher) {
          return const TeacherShell();
        }
        return const StudentHomeShell();
      },
    );
  }
}

enum _Role { teacher, student }

Map<String, dynamic> _decodeJwtPayload(String jwt) {
  final parts = jwt.split('.');
  if (parts.length != 3) return <String, dynamic>{};

  final payloadBase64 = parts[1];
  final normalized = base64Url.normalize(payloadBase64);
  final payloadBytes = base64Url.decode(normalized);
  final payloadString = utf8.decode(payloadBytes);

  final obj = jsonDecode(payloadString);
  if (obj is Map<String, dynamic>) return obj;
  return <String, dynamic>{};
}

Set<String> _extractGroups(Map<String, dynamic> payload) {
  final v = payload['cognito:groups'];
  if (v is List) {
    return v.whereType<String>().toSet();
  }
  return <String>{};
}
