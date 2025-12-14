// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import 'amplifyconfiguration.dart';
import 'config/app_config.dart';
import 'core/di/injection_container.dart';
import 'features/home/student_home_shell.dart';
import 'features/teacher/teacher_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 설정 초기화
  final config = AppConfig.fromEnvironment();

  // 의존성 주입 초기화
  await setupDependencies(config: config);

  // 앱 실행
  runApp(EVAttendanceApp(config: config));
}

class EVAttendanceApp extends StatefulWidget {
  final AppConfig config;

  const EVAttendanceApp({
    super.key,
    required this.config,
  });

  @override
  State<EVAttendanceApp> createState() => _EVAttendanceAppState();
}

class _EVAttendanceAppState extends State<EVAttendanceApp> {
  late final Future<void> _amplifyInitFuture;

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

      if (widget.config.enableLogging) {
        safePrint('[Amplify] Configure: SUCCESS');
      }
    } on AmplifyAlreadyConfiguredException {
      if (widget.config.enableLogging) {
        safePrint('[Amplify] Already configured. Skip.');
      }
    } catch (e, st) {
      safePrint('[Amplify] Configure: ERROR -> $e');
      safePrint(st.toString());
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.config.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 24),
                    Text(
                      'Amplify 초기화 실패',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          }

          return const _MainScaffold();
        },
      ),
    );
  }
}

class _MainScaffold extends StatefulWidget {
  const _MainScaffold();

  @override
  State<_MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<_MainScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final config = getIt<AppConfig>();
    final pages = <Widget>[
      const _RoleHomeRouter(),
      if (config.isDevelopment) const Center(child: Text('AWS Test Page')),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          if (config.isDevelopment)
            const NavigationDestination(
              icon: Icon(Icons.cloud_done_outlined),
              selectedIcon: Icon(Icons.cloud_done),
              label: 'Dev Tools',
            ),
        ],
      ),
    );
  }
}

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

      CognitoUserPoolTokens tokens;
      try {
        tokens = cognitoSession.userPoolTokensResult.value;
      } catch (_) {
        return _Role.student;
      }

      final groups = _extractGroups(tokens.idToken.raw);

      if (groups.contains('owners') || groups.contains('teachers')) {
        return _Role.teacher;
      }
      return _Role.student;
    } catch (e) {
      final config = getIt<AppConfig>();
      if (config.enableLogging) {
        safePrint('[RoleDetect] failed -> $e');
      }
      return _Role.student;
    }
  }

  Set<String> _extractGroups(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return {};

      final payloadBase64 = parts[1];
      final normalized = base64Url.normalize(payloadBase64);
      final payloadBytes = base64Url.decode(normalized);
      final payloadString = utf8.decode(payloadBytes);

      final obj = jsonDecode(payloadString);
      if (obj is! Map<String, dynamic>) return {};

      final groupsValue = obj['cognito:groups'];
      if (groupsValue is List) {
        return groupsValue.whereType<String>().toSet();
      }
      return {};
    } catch (e) {
      return {};
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
