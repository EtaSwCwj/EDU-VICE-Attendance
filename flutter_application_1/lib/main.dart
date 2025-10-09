import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app_router.dart';
import 'shared/services/auth_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
