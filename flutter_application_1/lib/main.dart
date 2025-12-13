import 'dart:convert';

import 'package:flutter/material.dart';

// Amplify
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

// amplify pull 산출물
import 'amplifyconfiguration.dart';

// 페이지들
import 'features/dev/aws_smoketest_page.dart';
import 'features/teacher/pages/teacher_assignments_page.dart';
import 'features/student_assignments/student_assignments_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
            const AwsSmokeTestPage(),
            const _AssignmentsRoleRouter(),
          ];

          return Scaffold(
            body: pages[_index],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.cloud_done),
                  label: 'AWS Test',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment),
                  label: 'Assignments',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Assignments 탭은 "로그인된 Cognito 그룹" 기준으로 Teacher/Student 페이지를 자동 분기한다.
/// - teachers/owners => TeacherAssignmentsPage
/// - students/그 외 => StudentAssignmentsPage
class _AssignmentsRoleRouter extends StatefulWidget {
  const _AssignmentsRoleRouter();

  @override
  State<_AssignmentsRoleRouter> createState() => _AssignmentsRoleRouterState();
}

class _AssignmentsRoleRouterState extends State<_AssignmentsRoleRouter> {
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

      // ✅ 너 프로젝트의 SDK에선 AuthResult에 isSuccess 같은 플래그가 없고,
      //    value 접근이 실패 시 throw 되는 형태로 보임.
      //    그래서 try/catch로 토큰 획득 성공 여부를 판단한다.
      CognitoUserPoolTokens tokens;
      try {
        tokens = cognitoSession.userPoolTokensResult.value;
      } catch (_) {
        // 로그인 안 됐거나 토큰 획득 실패: 안전하게 student
        return _Role.student;
      }

      final idTokenRaw = tokens.idToken.raw;
      final payload = _decodeJwtPayload(idTokenRaw);
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
          return const TeacherAssignmentsPage();
        }
        return const StudentAssignmentsPage();
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
