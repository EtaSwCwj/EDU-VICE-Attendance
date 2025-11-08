import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';

class AwsSmokeTestPage extends StatefulWidget {
  const AwsSmokeTestPage({super.key});

  @override
  State<AwsSmokeTestPage> createState() => _AwsSmokeTestPageState();
}

enum TodoSchemaPreset {
  // Amplify 템플릿 스키마(가장 흔함)
  nameDescription,
  // 일부 템플릿/변형
  titleIsComplete,
}

class _AwsSmokeTestPageState extends State<AwsSmokeTestPage> {
  final List<Map<String, dynamic>> _items = [];
  bool _busy = false;
  String _log = '';
  bool _useApiKey = true; // 콘솔에서 API Key 인증 켠 상태라 가정. 필요 시 끄고 시도.
  TodoSchemaPreset _preset = TodoSchemaPreset.nameDescription;

  void _appendLog(String msg) {
    setState(() => _log = '${DateTime.now().toIso8601String()}  $msg\n$_log');
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
      final mutation = r'''
        mutation CreateTodo($name: String!, $description: String) {
          createTodo(input: { name: $name, description: $description }) {
            id
            name
            description
          }
        }
      ''';
      final vars = {
        'name': 'smoke-${DateTime.now().millisecondsSinceEpoch}',
        'description': 'created by smoke test'
      };
      return GraphQLRequest<String>(
        document: mutation,
        variables: vars,
        authorizationMode:
            _useApiKey ? APIAuthorizationType.apiKey : APIAuthorizationType.userPools,
      );
    } else {
      final mutation = r'''
        mutation CreateTodo($title: String!, $isComplete: Boolean!) {
          createTodo(input: { title: $title, isComplete: $isComplete }) {
            id
            title
            isComplete
          }
        }
      ''';
      final vars = {
        'title': 'smoke-${DateTime.now().millisecondsSinceEpoch}',
        'isComplete': false
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

      _appendLog('[List] raw: ${resp.data?.substring(0, (resp.data?.length ?? 0).clamp(0, 400))}');

      final data = jsonDecode(resp.data ?? '{}') as Map<String, dynamic>;
      final items = (data['listTodos']?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

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

      _appendLog('[Create] raw: ${resp.data}');

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
            // 상단 컨트롤 바
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
                          DropdownMenuItem(
                            value: true,
                            child: Text('API Key'),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text('Cognito'),
                          ),
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

            // 결과 리스트
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, idx) {
                  final m = _items[idx];
                  final id = m['id'];
                  final lineA = m['name'] ?? m['title'] ?? '(no title)';
                  final lineB = m.containsKey('description')
                      ? (m['description'] ?? '')
                      : (m.containsKey('isComplete') ? 'isComplete: ${m['isComplete']}' : '');
                  return ListTile(
                    leading: const Icon(Icons.note),
                    title: Text('$lineA'),
                    subtitle: Text(lineB.toString()),
                    trailing: Text(
                      (id as String?)?.substring(0, (id as String?)?.length.clamp(0, 6) ?? 0) ?? '',
                      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // 로그 뷰(최근 로그 상단)
            SizedBox(
              height: 140,
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
