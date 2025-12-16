// Amplify Auth 기반 로그인 UI
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../shared/services/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberUsername = false;
  bool _rememberPassword = false;
  bool _autoLogin = false;
  bool _busy = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 저장된 credential 불러오기
  Future<void> _loadSavedCredentials() async {
    final authState = context.read<AuthState>();
    final saved = await authState.loadSavedCredentials();

    if (saved['username'] != null) {
      _usernameController.text = saved['username']!;
      _rememberUsername = true;
    }

    if (saved['password'] != null) {
      _passwordController.text = saved['password']!;
      _rememberPassword = true;
    }

    if (saved['autoLogin'] == 'true') {
      _autoLogin = true;
    }

    setState(() {});
  }

  Future<void> _doLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력하세요')),
      );
      return;
    }

    setState(() => _busy = true);

    // saveCredentials는 username/password 기억하기 중 하나라도 체크되어 있으면 true
    final saveCredentials = _rememberUsername || _rememberPassword;

    final authState = context.read<AuthState>();
    final ok = await authState.signIn(
      username,
      password,
      saveCredentials: saveCredentials,
      autoLogin: _autoLogin,
    );

    setState(() => _busy = false);

    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      // 실제 에러 메시지 표시
      final errorMessage = authState.lastError ?? '알 수 없는 오류가 발생했습니다';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인 실패: $errorMessage'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '확인',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottom),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 80),

                    // 로고/타이틀
                    Icon(
                      Icons.school,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'EDU-VICE',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '출석 관리 시스템',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // 아이디 입력
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: '아이디',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 16),

                    // 비밀번호 입력
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      enabled: !_busy,
                      onSubmitted: (_) => _doLogin(),
                    ),
                    const SizedBox(height: 16),

                    // 아이디 기억하기
                    CheckboxListTile(
                      value: _rememberUsername,
                      onChanged: _busy
                          ? null
                          : (value) {
                              setState(() {
                                _rememberUsername = value ?? false;
                              });
                            },
                      title: const Text('아이디 기억하기'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    // 비밀번호 기억하기
                    CheckboxListTile(
                      value: _rememberPassword,
                      onChanged: _busy
                          ? null
                          : (value) {
                              setState(() {
                                _rememberPassword = value ?? false;
                              });
                            },
                      title: Row(
                        children: [
                          const Text('비밀번호 기억하기'),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: '비밀번호는 암호화되지 않고 저장됩니다.\n보안에 주의하세요.',
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    // 자동 로그인
                    CheckboxListTile(
                      value: _autoLogin,
                      onChanged: _busy
                          ? null
                          : (value) {
                              setState(() {
                                _autoLogin = value ?? false;
                                // 자동 로그인 체크 시 아이디/비밀번호도 자동으로 체크
                                if (_autoLogin) {
                                  _rememberUsername = true;
                                  _rememberPassword = true;
                                }
                              });
                            },
                      title: const Text('자동 로그인'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 24),

                    // 로그인 버튼
                    FilledButton(
                      onPressed: _busy ? null : _doLogin,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '로그인',
                              style: TextStyle(fontSize: 16),
                            ),
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
