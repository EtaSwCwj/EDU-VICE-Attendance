import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// Amplify
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:amplify_datastore/amplify_datastore.dart';

// Amplify Models (GraphQL API용)
import 'models/ModelProvider.dart';

// amplify pull 산출물
import 'amplifyconfiguration.dart';

// DI & Config
import 'config/app_config.dart';
import 'core/di/injection_container.dart';

// Lesson Provider
import 'features/lessons/presentation/providers/lesson_provider.dart';
import 'features/lessons/domain/repositories/lesson_repository.dart';

// Router & Auth
import 'app/app_router.dart';
import 'shared/services/auth_state.dart';

// Theme
import 'app/theme/app_theme.dart';

Future<void> main() async {
  safePrint('[main] 진입');
  WidgetsFlutterBinding.ensureInitialized();

  // Amplify 초기화
  safePrint('[main] Amplify 초기화 시작');
  await _initAmplifyOnce();
  safePrint('[main] Amplify 초기화 완료');

  // DI 초기화 (선택적)
  try {
    safePrint('[main] DI 초기화 시작');
    final config = AppConfig.development(); // 개발 환경
    await setupDependencies(config: config);
    safePrint('[main] DI 초기화 완료');
  } catch (e) {
    // DI 초기화 실패해도 앱은 실행되도록
    safePrint('[DI] Failed to initialize: $e');
  }

  safePrint('[main] EVAttendanceApp 실행');
  runApp(const EVAttendanceApp());
}

Future<void> _initAmplifyOnce() async {
  if (Amplify.isConfigured) return;

  try {
    await Amplify.addPlugins([
      AmplifyAPI(options: APIPluginOptions(modelProvider: ModelProvider.instance)),
      AmplifyAuthCognito(),
      AmplifyStorageS3(),
      AmplifyDataStore(modelProvider: ModelProvider.instance),
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

class EVAttendanceApp extends StatelessWidget {
  const EVAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => LessonProvider(getIt<LessonRepository>())),
      ],
      child: Builder(
        builder: (context) {
          final authState = Provider.of<AuthState>(context, listen: false);

          return MaterialApp.router(
            title: 'EDU-VICE Attendance',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ko', 'KR'),
              Locale('en', 'US'),
            ],
            locale: const Locale('ko', 'KR'),
            theme: AppTheme.light,
            routerConfig: AppRouter.create(authState),
          );
        },
      ),
    );
  }
}
