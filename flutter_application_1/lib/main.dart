import 'dart:async';
import 'package:flutter/material.dart';

// Amplify
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

// amplify pull 산출물
import 'amplifyconfiguration.dart';

// 기존 테스트 페이지
import 'features/dev/aws_smoketest_page.dart';

// ✅ 실제 교사용 Assignments 페이지(우리가 작업한 화면)
import 'features/teacher/pages/teacher_assignments_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initAmplifyOnce();
  runApp(const EVAttendanceApp());
}

bool _amplifyConfigured = false;
Future<void> _initAmplifyOnce() async {
  if (_amplifyConfigured) return;
  try {
    Amplify.addPlugins([
      AmplifyAPI(),
      AmplifyAuthCognito(),
    ]);
    await Amplify.configure(amplifyconfig);
    _amplifyConfigured = true;
    safePrint('[Amplify] configure: SUCCESS');
  } on AmplifyAlreadyConfiguredException {
    _amplifyConfigured = true;
    safePrint('[Amplify] already configured. Skip.');
  } catch (e, st) {
    safePrint('[Amplify] configure: ERROR -> $e');
    safePrint(st.toString());
    rethrow;
  }
}

class EVAttendanceApp extends StatefulWidget {
  const EVAttendanceApp({super.key});
  @override
  State<EVAttendanceApp> createState() => _EVAttendanceAppState();
}

class _EVAttendanceAppState extends State<EVAttendanceApp> {
  int _index = 0;

  final _pages = const [
    AwsSmokeTestPage(),
    TeacherAssignmentsPage(), // ✅ 여기로 교체
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EDU-VICE Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: _pages[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.cloud_done), label: 'AWS Test'),
            NavigationDestination(icon: Icon(Icons.assignment), label: 'Assignments'),
          ],
        ),
      ),
    );
  }
}
