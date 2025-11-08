import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

/// AppSync(GraphQL) + Cognito(User Pools) 스모크 테스트 화면
/// - 상단: 로그인/로그아웃, 세션 상태, 인증 모드(API Key/Cognito), 필드 프리셋
/// - 버튼: List / Create (listTodos / createTodo)
class AwsSmokeTestPage extends StatefulWidget {
  const AwsSmokeTestPage({super.key});

  @override
  State<AwsSmokeTestPage> createState() => _AwsSmokeTestPageState();
}

enum TodoSchemaPreset {
  // Amplify 기본 템플릿: id, name, description
  nameDescription,
  // 변형 템플릿: id, title, isComplete
  titleIsComplete,
}

class _AwsSmokeTestPageState extends State<AwsSmokeTestPage> {
  final List<Map<String, dynamic>> _items = [];
  bool _busy = false;
  String _log = '';

  // 인증 관련
  bool _signedIn = false;
  String _username = '';
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // 요청 옵션
  bool _useApiKey = true; // 로그인 성공 시 자동으로 Cognito 모드로 전환
  TodoSchemaPreset _preset = TodoSchemaPreset.nameDescription;

  @override
  void initState() {
    super.initState();
    _refreshSession();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _appendLog(String msg) {
    setState(() => _log = '${DateTime.now().toIso8601String()}  $msg\n$_log');
  }

  Future<void> _refreshSession() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      setState(() {
        _signedIn = session.isSignedIn;
        _username = '';
      });
      if (_signedIn) {
        try {
          final user = await Amplify.Auth.getCurrentUser();
          setState(() => _username = user.username);
        } catch (_) {/* ignore */}
      }
      _appendLog('[Auth] session: isSignedIn=${session.isSignedIn}');
      if (_signedIn && _useApiKey) {
        setState(() => _useApiKey = false); // 로그인돼 있으면 Cognito 모드 권장
      }
    } on AuthException catch (e) {
      _appendLog('[Auth] fetch session error: ${e.message}');
      setState(() => _signedIn = false);
    }
  }

  Future<void> _signIn() async {
    if (_busy) return;
    final id = _usernameCtrl.text.trim();
    final pw = _passwordCtrl.text;
    if (id.isEmpty || pw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디/비밀번호를 입력하세요')),
      );
      return;
    }

    setState(() => _busy = true);
    _appendLog('[Auth] signIn start: $id');

    try {
      final res = await Amplify.Auth.signIn(username: id, password: pw);

      if (res.isSignedIn) {
        _appendLog('[Auth] signIn: SUCCESS');
      } else {
        await _handleNextStep(res);
      }
      await _refreshSession();
    } on AuthException catch (e) {
      _appendLog('[Auth] signIn error: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleNextStep(SignInResult res) async {
    final step = res.nextStep.signInStep;
    _appendLog('[Auth] nextStep: $step');

    if (step == AuthSignInStep.confirmSignInWithNewPassword) {
      if (!mounted) return;
      final newPw = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final c = TextEditingController();
          return AlertDialog(
            title: const Text('새 비밀번호 설정'),
            content: TextField(
              controller: c,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(c.text),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );

      if (newPw == null || newPw.isEmpty) {
        _appendLog('[Auth] new password canceled');
        return;
      }

      try {
        final confirmRes = await Amplify.Auth.confirmSignIn(confirmationValue: newPw);
        if (confirmRes.isSignedIn) {
          _appendLog('[Auth] confirm new password: SUCCESS');
        } else {
          _appendLog('[Auth] confirm new password: still pending (${confirmRes.nextStep.signInStep})');
        }
      } on AuthException catch (e) {
        _appendLog('[Auth] confirm new password error: ${e.message}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('새 비밀번호 설정 실패: ${e.message}')),
        );
      }
    } else if (step == AuthSignInStep.done) {
      _appendLog('[Auth] signIn step DONE (but isSignedIn=false?)');
    } else {
      _appendLog('[Auth] unsupported nextStep in smoke: $step');
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    _appendLog('[Auth] signOut start');

    try {
      await Amplify.Auth.signOut(options: const SignOutOptions(globalSignOut: true));
      _appendLog('[Auth] signOut: SUCCESS');
      await _refreshSession();
    } on AuthException catch (e) {
      _appendLog('[Auth] signOut error: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  GraphQLRequest<String> _buildListRequest() {
    final query = _preset == TodoSchemaPreset.nameDescription
        ? r'''
          query ListTodos {
            listTodos {
              items {
                id
                name
                description
              }
            }
          }
        '''
        : r'''
          query ListTodos {
            listTodos {
              items {
                id
                title
                isComplete
              }
            }
          }
        ''';

    return GraphQLRequest<String>(
      document: query,
      authorizationMode:
          _useApiKey ? APIAuthorizationType.apiKey : APIAuthorizationType.userPools,
    );
  }

  GraphQLRequest<String> _buildCreateRequest() {
    if (_preset == TodoSchemaPreset.nameDescription) {
      const mutation = r'''
        mutation CreateTodo($name: String!, $description: String) {
          createTodo(input: { name: $name, description: $description }) {
            id
            name
            description
          }
        }
      ''';
      final vars = <String, dynamic>{
        'name': 'smoke-${DateTime.now().millisecondsSinceEpoch}',
        'description': 'created by smoke test',
      };
      return GraphQLRequest<String>(
        document: mutation,
        variables: vars,
        authorizationMode:
            _useApiKey ? APIAuthorizationType.apiKey : APIAuthorizationType.userPools,
      );
    } else {
      const mutation = r'''
        mutation CreateTodo($title: String!, $isComplete: Boolean!) {
          createTodo(input: { title: $title, isComplete: $isComplete }) {
            id
            title
            isComplete
          }
        }
      ''';
      final vars = <String, dynamic>{
        'title': 'smoke-${DateTime.now().millisecondsSinceEpoch}',
        'isComplete': false,
      };
      return GraphQLRequest<String>(
        document: mutation,
        variables: vars,
        authorizationMode:
            _useApiKey ? APIAuthorizationType.apiKey : APIAuthorizationType.userPools,
      );
    }
  }

  Future<void> _listTodos() async {
    if (!mounted) return;
    setState(() => _busy = true);
    _appendLog('[List] start (mode=${_useApiKey ? 'API Key' : 'Cognito'})');

    try {
      final req = _buildListRequest();
      final resp = await Amplify.API.query(request: req).response;

      final preview = resp.data == null
          ? '(null)'
          : resp.data!.substring(0, resp.data!.length > 600 ? 600 : resp.data!.length);
      _appendLog('[List] raw: $preview');

      final data = jsonDecode(resp.data ?? '{}') as Map<String, dynamic>;
      final items = (data['listTodos']?['items'] as List<dynamic>? ?? [])
          .map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
          .cast<Map<String, dynamic>>()
          .toList();

      setState(() {
        _items
          ..clear()
          ..addAll(items);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('List 성공')),
      );
    } on ApiException catch (e) {
      _appendLog('[List] ApiException: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('List 실패: ${e.message}')),
      );
    } catch (e) {
      _appendLog('[List] ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('List 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createTodo() async {
    if (!mounted) return;
    setState(() => _busy = true);
    _appendLog('[Create] start (mode=${_useApiKey ? 'API Key' : 'Cognito'})');

    try {
      final req = _buildCreateRequest();
      final resp = await Amplify.API.mutate(request: req).response;

      _appendLog('[Create] raw: ${resp.data ?? '(null)'}');

      // 성공 후 목록 새로고침
      await _listTodos();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create 성공')),
      );
    } on ApiException catch (e) {
      _appendLog('[Create] ApiException: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create 실패: ${e.message}')),
      );
    } catch (e) {
      _appendLog('[Create] ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presetLabel = _preset == TodoSchemaPreset.nameDescription
        ? 'Todo(id, name, description)'
        : 'Todo(id, title, isComplete)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('AWS Smoke Test (AppSync/Cognito)'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // === 로그인 바 ===
            _AuthBar(
              busy: _busy,
              signedIn: _signedIn,
              username: _username,
              usernameCtrl: _usernameCtrl,
              passwordCtrl: _passwordCtrl,
              onSignIn: _signIn,
              onSignOut: _signOut,
              onRefreshSession: _refreshSession,
            ),

            const Divider(height: 1),

            // === 컨트롤 바 ===
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _listTodos,
                    icon: const Icon(Icons.list),
                    label: const Text('List Todos'),
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : _createTodo,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Todo'),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Auth:'),
                      const SizedBox(width: 6),
                      DropdownButton<bool>(
                        value: _useApiKey,
                        items: const [
                          DropdownMenuItem(value: true, child: Text('API Key')),
                          DropdownMenuItem(value: false, child: Text('Cognito')),
                        ],
                        onChanged: _busy
                            ? null
                            : (v) {
                                if (v == null) return;
                                setState(() => _useApiKey = v);
                              },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Fields:'),
                      const SizedBox(width: 6),
                      DropdownButton<TodoSchemaPreset>(
                        value: _preset,
                        items: const [
                          DropdownMenuItem(
                            value: TodoSchemaPreset.nameDescription,
                            child: Text('name/description'),
                          ),
                          DropdownMenuItem(
                            value: TodoSchemaPreset.titleIsComplete,
                            child: Text('title/isComplete'),
                          ),
                        ],
                        onChanged: _busy
                            ? null
                            : (v) {
                                if (v == null) return;
                                setState(() => _preset = v);
                              },
                      ),
                    ],
                  ),
                  Text('[Preset] $presetLabel'),
                ],
              ),
            ),

            const Divider(height: 1),

            // === 결과 리스트 ===
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, idx) {
                  final m = _items[idx];
                  final id = (m['id'] as String?) ?? '';
                  final title = m['name'] ?? m['title'] ?? '(no title)';
                  final sub = m.containsKey('description')
                      ? (m['description'] ?? '')
                      : (m.containsKey('isComplete') ? 'isComplete: ${m['isComplete']}' : '');

                  final tail = id.isEmpty
                      ? ''
                      : id.substring(0, id.length >= 6 ? 6 : id.length);

                  return ListTile(
                    leading: const Icon(Icons.note),
                    title: Text('$title'),
                    subtitle: Text('$sub'),
                    trailing: Text(
                      tail,
                      // FontFeature 제거(경고 정리 목적)
                      // style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // === 로그 뷰(최근 로그 상단) ===
            SizedBox(
              height: 160,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  reverse: false,
                  child: Text(
                    _log,
                    style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 로그인/세션 바 UI 분리
class _AuthBar extends StatelessWidget {
  const _AuthBar({
    required this.busy,
    required this.signedIn,
    required this.username,
    required this.usernameCtrl,
    required this.passwordCtrl,
    required this.onSignIn,
    required this.onSignOut,
    required this.onRefreshSession,
  });

  final bool busy;
  final bool signedIn;
  final String username;
  final TextEditingController usernameCtrl;
  final TextEditingController passwordCtrl;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final VoidCallback onRefreshSession;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              _StatusDot(color: signedIn ? Colors.green : Colors.grey),
              const SizedBox(width: 6),
              Text(
                signedIn ? 'Signed in${username.isNotEmpty ? ' ($username)' : ''}' : 'Signed out',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: busy ? null : onRefreshSession,
                icon: const Icon(Icons.refresh),
                label: const Text('세션 확인'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'teacher1 / student1',
                  ),
                  enabled: !busy && !signedIn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  enabled: !busy && !signedIn,
                ),
              ),
              const SizedBox(width: 12),
              if (!signedIn)
                FilledButton(
                  onPressed: busy ? null : onSignIn,
                  child: const Text('Sign in'),
                )
              else
                FilledButton.tonal(
                  onPressed: busy ? null : onSignOut,
                  child: const Text('Sign out'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
