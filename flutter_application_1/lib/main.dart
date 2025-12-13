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

  final _pages = const [
    AwsSmokeTestPage(),
    _AssignmentsRoleGate(),
  ];

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

          return Scaffold(
            body: _pages[_index],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.cloud_done), label: 'AWS Test'),
                NavigationDestination(icon: Icon(Icons.assignment), label: 'Assignments'),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Assignments 탭: Cognito 그룹으로 Teacher/Student 화면 분기
class _AssignmentsRoleGate extends StatefulWidget {
  const _AssignmentsRoleGate();

  @override
  State<_AssignmentsRoleGate> createState() => _AssignmentsRoleGateState();
}

class _AssignmentsRoleGateState extends State<_AssignmentsRoleGate> {
  late final Future<_Role> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = _resolveRole();
  }

  Future<_Role> _resolveRole() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) return _Role.student;

      final cognito = session as CognitoAuthSession;
      final tokens = cognito.userPoolTokensResult.value;

      // ✅ claims가 JsonWebClaims라 [] 접근이 안 됨 → JWT payload 직접 decode
      final idToken = tokens.idToken.raw;
      final payload = _decodeJwtPayload(idToken);

      final groupsDyn = payload['cognito:groups'];
      final groups = _asStringList(groupsDyn);

      if (groups.contains('owners') || groups.contains('teachers')) {
        return _Role.teacher;
      }
      return _Role.student;
    } catch (e, st) {
      safePrint('Role resolve failed: $e\n$st');
      return _Role.student;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Role>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final role = snapshot.data ?? _Role.student;

        if (role == _Role.teacher) {
          return const TeacherAssignmentsPage();
        }
        return const StudentAssignmentsPage();
      },
    );
  }

  /// JWT payload(base64url) decode → Map
  Map<String, dynamic> _decodeJwtPayload(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return <String, dynamic>{};

    final payloadPart = parts[1];
    final normalized = base64Url.normalize(payloadPart);
    final bytes = base64Url.decode(normalized);
    final jsonStr = utf8.decode(bytes);

    final obj = jsonDecode(jsonStr);
    if (obj is Map<String, dynamic>) return obj;
    return <String, dynamic>{};
  }

  List<String> _asStringList(dynamic v) {
    if (v == null) return const <String>[];
    if (v is List) {
      return v.whereType<String>().toList();
    }
    if (v is String) {
      // sometimes a single group might come as string
      return <String>[v];
    }
    return const <String>[];
  }
}

enum _Role { teacher, student }
