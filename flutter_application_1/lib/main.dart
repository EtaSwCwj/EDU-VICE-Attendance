import 'package:flutter/material.dart';
import 'app/app_router.dart';              // ← 추가

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'EDU-VICE',
      routerConfig: appRouter,             // ← go_router 사용
    );
  }
}
