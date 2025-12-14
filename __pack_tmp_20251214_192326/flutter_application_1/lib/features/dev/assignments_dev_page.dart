import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class AssignmentsDevPage extends StatefulWidget {
  const AssignmentsDevPage({super.key});
  @override
  State<AssignmentsDevPage> createState() => _AssignmentsDevPageState();
}

class _AssignmentsDevPageState extends State<AssignmentsDevPage> {
  bool _busy = false;
  String _log = '';
  String _username = '';

  // 테스트용 역할 토글 (토큰 파싱 대신 수동 선택)
  bool _asTeacher = true;
  bool _asStudent = true;

  // teacher 패널 입력값
  final _studentCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // 조회 결과
  List<Map<String, dynamic>> _teacherItems = [];
  List<Map<String, dynamic>> _studentItems = [];
  List<Map<String, dynamic>> _ownerItems = []; // 서버 owner 필터만 적용한 결과

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _studentCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _appendLog(String m) {
    setState(() => _log = '${DateTime.now().toIso8601String()}  $m\n$_log');
  }

  Future<void> _bootstrap() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      setState(() => _username = user.username);
      _appendLog('[Auth] current user: $_username');
    } catch (e) {
      _appendLog('[Auth] getCurrentUser error: $e');
    }
  }

  // -------- GraphQL Helpers --------

  GraphQLRequest<String> _listAssignmentsByTeacherReq(String teacherUsername) {
    const doc = r'''
      query ListAssignments($filter: ModelAssignmentFilterInput) {
        listAssignments(filter: $filter, limit: 50) {
          items { id title description status studentUsername teacherUsername dueDate createdAt }
        }
      }
    ''';
    final vars = {
      'filter': {
        'teacherUsername': {'eq': teacherUsername}
      }
    };
    return GraphQLRequest<String>(
      document: doc,
      variables: vars,
      authorizationMode: APIAuthorizationType.userPools,
    );
  }

  GraphQLRequest<String> _listAssignmentsByStudentReq(String studentUsername) {
    const doc = r'''
      query ListAssignments($filter: ModelAssignmentFilterInput) {
        listAssignments(filter: $filter, limit: 50) {
          items { id title description status studentUsername teacherUsername dueDate createdAt }
        }
      }
    ''';
    final vars = {
      'filter': {
        'studentUsername': {'eq': studentUsername}
      }
    };
    return GraphQLRequest<String>(
      document: doc,
      variables: vars,
      authorizationMode: APIAuthorizationType.userPools,
    );
  }

  // ★ 필터 없이 서버의 owner @auth만으로 보기
  GraphQLRequest<String> _listAssignmentsOwnerOnlyReq() {
    const doc = r'''
      query ListAssignmentsOwner {
        listAssignments(limit: 50) {
          items { id title description status studentUsername teacherUsername dueDate createdAt }
        }
      }
    ''';
    return GraphQLRequest<String>(
      document: doc,
      authorizationMode: APIAuthorizationType.userPools,
    );
  }

  GraphQLRequest<String> _createAssignmentReq({
    required String title,
    String? description,
    required String studentUsername,
    required String teacherUsername,
  }) {
    const doc = r'''
      mutation CreateAssignment($input: CreateAssignmentInput!) {
        createAssignment(input: $input) {
          id title description status studentUsername teacherUsername createdAt
        }
      }
    ''';
    final input = {
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      'studentUsername': studentUsername,
      'teacherUsername': teacherUsername,
      'status': 'ASSIGNED',
    };
    return GraphQLRequest<String>(
      document: doc,
      variables: {'input': input},
      authorizationMode: APIAuthorizationType.userPools,
    );
  }

  GraphQLRequest<String> _updateAssignmentStatusReq({
    required String id,
    required String status,
  }) {
    const doc = r'''
      mutation UpdateAssignment($input: UpdateAssignmentInput!) {
        updateAssignment(input: $input) {
          id title status studentUsername teacherUsername updatedAt
        }
      }
    ''';
    final input = {'id': id, 'status': status};
    return GraphQLRequest<String>(
      document: doc,
      variables: {'input': input},
      authorizationMode: APIAuthorizationType.userPools,
    );
  }

  // --------- helpers ---------

  List<Map<String, dynamic>> _parseItems(String? dataStr) {
    if (dataStr == null) return [];
    final map = jsonDecode(dataStr) as Map<String, dynamic>;
    final items = (map.values.first?['items'] as List? ?? [])
        .cast<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
    return items.cast<Map<String, dynamic>>();
  }

  String _formatErrors(List<GraphQLResponseError> errors) {
    if (errors.isEmpty) return '';
    final arr = errors
        .map((e) => '{ message: ${e.message}, path: ${e.path}, locations: ${e.locations} }')
        .join(' | ');
    return arr;
  }

  // -------- Actions --------

  Future<void> _listMineAsTeacher() async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final resp = await Amplify.API.query(
        request: _listAssignmentsByTeacherReq(_username),
      ).response;

      _appendLog('[Teacher] list errors: ${_formatErrors(resp.errors)}');
      _appendLog('[Teacher] list raw: ${resp.data}');

      final items = _parseItems(resp.data);
      setState(() => _teacherItems = items);
      _appendLog('[Teacher] list ${_teacherItems.length} items');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teacher list 완료')));
    } on ApiException catch (e) {
      _appendLog('[Teacher] list ApiException: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Teacher list 실패: ${e.message}')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _listMineAsStudent() async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final resp = await Amplify.API.query(
        request: _listAssignmentsByStudentReq(_username),
      ).response;

      _appendLog('[Student] list errors: ${_formatErrors(resp.errors)}');
      _appendLog('[Student] list raw: ${resp.data}');

      final items = _parseItems(resp.data);
      setState(() => _studentItems = items);
      _appendLog('[Student] list ${_studentItems.length} items');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student list 완료')));
    } on ApiException catch (e) {
      _appendLog('[Student] list ApiException: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Student list 실패: ${e.message}')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _listOwnerOnly() async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final resp = await Amplify.API.query(
        request: _listAssignmentsOwnerOnlyReq(),
      ).response;

      _appendLog('[OwnerOnly] list errors: ${_formatErrors(resp.errors)}');
      _appendLog('[OwnerOnly] list raw: ${resp.data}');

      final items = _parseItems(resp.data);
      setState(() => _ownerItems = items);
      _appendLog('[OwnerOnly] list ${_ownerItems.length} items');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OwnerOnly list 완료')));
    } on ApiException catch (e) {
      _appendLog('[OwnerOnly] list ApiException: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OwnerOnly list 실패: ${e.message}')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createAsTeacher() async {
    if (!mounted) return;
    final sUser = _studentCtrl.text.trim();
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (sUser.isEmpty || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('studentUsername, title 필수')));
      return;
    }
    setState(() => _busy = true);
    try {
      final resp = await Amplify.API.mutate(
        request: _createAssignmentReq(
          title: title,
          description: desc.isEmpty ? null : desc,
          studentUsername: sUser,
          teacherUsername: _username,
        ),
      ).response;

      _appendLog('[Teacher] create errors: ${_formatErrors(resp.errors)}');
      _appendLog('[Teacher] create raw: ${resp.data}');

      // 바로 서버 재조회(필터 & owner-only 둘 다)
      await _listMineAsTeacher();
      await _listOwnerOnly();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create 호출 완료')));
    } on ApiException catch (e) {
      _appendLog('[Teacher] create ApiException: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Create 실패: ${e.message}')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markDone(String id) async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final resp = await Amplify.API.mutate(
        request: _updateAssignmentStatusReq(id: id, status: 'DONE'),
      ).response;

      _appendLog('[Student] update errors: ${_formatErrors(resp.errors)}');
      _appendLog('[Student] update raw: ${resp.data}');

      await _listMineAsStudent();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('상태 갱신 호출 완료')));
    } on ApiException catch (e) {
      _appendLog('[Student] update ApiException: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('상태 갱신 실패: ${e.message}')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // -------- UI --------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignments (Domain Smoke)')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(username: _username),
                const SizedBox(height: 12),

                // 테스트용 역할 토글
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Role toggle (client-only)'),
                    FilterChip(
                      label: const Text('Teacher'),
                      selected: _asTeacher,
                      onSelected: (v) => setState(() => _asTeacher = v),
                    ),
                    FilterChip(
                      label: const Text('Student'),
                      selected: _asStudent,
                      onSelected: (v) => setState(() => _asStudent = v),
                    ),
                    const SizedBox(width: 8),
                    const Text('※ 서버 권한은 AppSync @auth로 최종 판정'),
                  ],
                ),

                const SizedBox(height: 12),

                if (_asTeacher)
                  _TeacherPanel(
                    busy: _busy,
                    studentCtrl: _studentCtrl,
                    titleCtrl: _titleCtrl,
                    descCtrl: _descCtrl,
                    onCreate: _createAsTeacher,
                    onList: _listMineAsTeacher,
                    onListOwnerOnly: _listOwnerOnly,
                  ),

                if (_asTeacher) const SizedBox(height: 16),

                if (_asTeacher)
                  _ListBlock(
                    title: '내가 배정한 과제 (filter=teacherUsername)',
                    items: _teacherItems,
                    trailingBuilder: (_) => const SizedBox.shrink(),
                  ),

                if (_asTeacher) const SizedBox(height: 12),

                if (_asTeacher)
                  _ListBlock(
                    title: '내 과제 (owner-only server filter)',
                    items: _ownerItems,
                    trailingBuilder: (_) => const SizedBox.shrink(),
                  ),

                const Divider(height: 24, thickness: 1),

                if (_asStudent)
                  _StudentPanel(
                    busy: _busy,
                    onList: _listMineAsStudent,
                  ),

                if (_asStudent) const SizedBox(height: 12),

                if (_asStudent)
                  _ListBlock(
                    title: '내 과제',
                    items: _studentItems,
                    trailingBuilder: (item) {
                      final status = (item['status'] ?? '').toString();
                      if (status == 'DONE') return const Chip(label: Text('DONE'));
                      return OutlinedButton(
                        onPressed: _busy ? null : () => _markDone((item['id'] ?? '').toString()),
                        child: const Text('Mark DONE'),
                      );
                    },
                  ),

                const Divider(height: 24, thickness: 1),
                const Text('Logs', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 240,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(_log, style: const TextStyle(fontFamily: 'Consolas', fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- widgets ----------

class _Header extends StatelessWidget {
  const _Header({required this.username});
  final String username;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.person, size: 20),
        const SizedBox(width: 8),
        Text(
          username.isEmpty ? '(signed out)' : username,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _TeacherPanel extends StatelessWidget {
  const _TeacherPanel({
    required this.busy,
    required this.studentCtrl,
    required this.titleCtrl,
    required this.descCtrl,
    required this.onCreate,
    required this.onList,
    required this.onListOwnerOnly,
  });

  final bool busy;
  final TextEditingController studentCtrl;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final VoidCallback onCreate;
  final VoidCallback onList;
  final VoidCallback onListOwnerOnly;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('교사 패널', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: studentCtrl,
                    decoration: const InputDecoration(
                      labelText: 'studentUsername (예: student_test1)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'title'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'description (선택)'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Assignment'),
                ),
                FilledButton.icon(
                  onPressed: busy ? null : onList,
                  icon: const Icon(Icons.list),
                  label: const Text('내가 배정한 과제 조회'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onListOwnerOnly,
                  icon: const Icon(Icons.lock_person),
                  label: const Text('OwnerOnly 조회'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _StudentPanel extends StatelessWidget {
  const _StudentPanel({
    required this.busy,
    required this.onList,
  });

  final bool busy;
  final VoidCallback onList;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('학생 패널', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: busy ? null : onList,
              icon: const Icon(Icons.list_alt),
              label: const Text('내 과제 조회'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListBlock extends StatelessWidget {
  const _ListBlock({
    required this.title,
    required this.items,
    required this.trailingBuilder,
  });

  final String title;
  final List<Map<String, dynamic>> items;
  final Widget Function(Map<String, dynamic>) trailingBuilder;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text('${items.length}개'),
          ),
          const Divider(height: 1),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('항목 없음'),
            )
          else
            ...items.map((m) {
              final title = (m['title'] ?? '').toString();
              final desc = (m['description'] ?? '').toString();
              final status = (m['status'] ?? '').toString();
              final student = (m['studentUsername'] ?? '').toString();
              final teacher = (m['teacherUsername'] ?? '').toString();
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.assignment_outlined),
                    title: Text(title),
                    subtitle: Text('by $teacher → $student\n$status · $desc'),
                    isThreeLine: true,
                    trailing: trailingBuilder(m),
                  ),
                  const Divider(height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }
}
