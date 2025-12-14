// 더미 로그인 UI: assets/mock/accounts.json 기반
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';                 // ← read/watch 확장자
import '../../shared/services/auth_state.dart';          // ← AuthState 타입

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _id = TextEditingController(text: 'teacher'); // 테스트 기본값
  final _pw = TextEditingController(text: 'teach123'); // 테스트 기본값
  bool _busy = false;

  Future<void> _doLogin() async {
    setState(() => _busy = true);
    final ok = await context
        .read<AuthState>()
        .signIn(_id.text.trim(), _pw.text.trim());
    setState(() => _busy = false);

    if (!mounted) return;
    if (ok) {
      context.go('/home'); // 가드가 있으니 사실 생략해도 되지만 명시적으로 이동
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 실패: 아이디/비밀번호를 확인하세요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom; // 키보드 높이

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottom),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0), // ← 좌우 여백
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420), // ← 최대 폭 제한
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),
                    const Text(
                      'EDU-VICE 로그인',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _id,
                      decoration: const InputDecoration(labelText: '아이디'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pw,
                      decoration: const InputDecoration(labelText: '비밀번호'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _doLogin,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('로그인'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
