import 'package:flutter/material.dart';

// Amplify
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';

// amplify pull 산출물
import 'amplifyconfiguration.dart';

// 페이지들
import 'features/dev/aws_smoketest_page.dart';
import 'features/teacher/pages/teacher_assignments_page.dart';


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
    TeacherAssignmentsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _amplifyInitFuture = _initAmplifyOnce();
  }

  Future<void> _initAmplifyOnce() async {
    // ✅ 이미 구성되어 있으면 즉시 통과 (핫리로드/재진입 방지)
    if (Amplify.isConfigured) return;

    try {
      // ✅ addPlugins는 반드시 await
      await Amplify.addPlugins([
        AmplifyAPI(), // amplify_flutter에서 제공됨
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
          // ✅ 앱이 “멈춘 것처럼” 보이지 않게 로딩 화면을 먼저 그림
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // ✅ 초기화 실패 시 원인 표시
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
