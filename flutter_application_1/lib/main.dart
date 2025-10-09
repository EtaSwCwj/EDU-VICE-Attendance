import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app_router.dart';
import 'shared/services/auth_state.dart';

// 플랫폼별 MockStorage 구현을 상단에서 "조건부 임포트"
import 'shared/services/storage/mock_storage_io.dart'
  if (dart.library.html) 'shared/services/storage/mock_storage_web.dart' as storage;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 모바일/데스크톱: 문서폴더 시드 수행
  // 웹: no-op (web 구현은 내부에서 아무 것도 하지 않도록 작성됨)
  await storage.MockStorage.ensureSeeded();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthState(),
      builder: (ctx, _) {
        final auth = ctx.watch<AuthState>();
        final router = createRouter(auth);
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'EDU-VICE',
          routerConfig: router,
        );
      },
    );
  }
}
