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
// 신규: 과제 도메인 스모크
import 'features/dev/assignments_dev_page.dart';

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
    AssignmentsDevPage(),
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
