import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../models/ModelProvider.dart';
import '../data/assignment_repository.dart';

class TeacherAssignmentsPage extends StatefulWidget {
  const TeacherAssignmentsPage({super.key});

  @override
  State<TeacherAssignmentsPage> createState() => _TeacherAssignmentsPageState();
}

class _TeacherAssignmentsPageState extends State<TeacherAssignmentsPage> {
  final _repo = AssignmentRepository();
  final _studentCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _username;
  bool _loading = false;
  List<Assignment> _mine = <Assignment>[];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final user = await Amplify.Auth.getCurrentUser();
    setState(() => _username = user.username);
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_username == null) return;
    setState(() => _loading = true);
    try {
      final items = await _repo.listByTeacher(teacherUsername: _username!);
      setState(() => _mine = items);
    } catch (e) {
      _toast('조회 실패: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (_username == null) return;
    if (_studentCtrl.text.trim().isEmpty || _titleCtrl.text.trim().isEmpty) {
      _toast('studentUsername / title 입력');
      return;
    }
    setState(() => _loading = true);
    try {
      await _repo.create(
        teacherUsername: _username!,
        studentUsername: _studentCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      _studentCtrl.clear();
      _titleCtrl.clear();
      _descCtrl.clear();
      await _refresh();
      _toast('생성 완료');
    } catch (e) {
      _toast('생성 실패: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _changeStatus(Assignment a) async {
    final picked = await showModalBottomSheet<AssignmentStatus>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text('상태 변경', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...AssignmentStatus.values.map(
                (s) => ListTile(
                  title: Text(s.name),
                  trailing: a.status == s ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(ctx, s),
                ),
              ),
              const Divider(),
              ListTile(
                textColor: Colors.red,
                iconColor: Colors.red,
                leading: const Icon(Icons.delete),
                title: const Text('삭제'),
                onTap: () => Navigator.pop(ctx, null),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    setState(() => _loading = true);
    try {
      if (picked == null) {
        await _repo.delete(assignment: a);
        _toast('삭제 완료');
      } else {
        await _repo.updateStatus(assignment: a, status: picked);
        _toast('상태 변경: ${picked.name}');
      }
      await _refresh();
    } catch (e) {
      _toast('작업 실패: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Assignments — Teacher')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _creatorCard(theme),
            const SizedBox(height: 16),
            _sectionHeader('내가 배정한 과제 (${_mine.length}개)'),
            if (_loading) const LinearProgressIndicator(),
            if (_mine.isEmpty && !_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('항목 없음', style: theme.textTheme.bodyMedium),
                ),
              )
            else
              ..._mine.map(_tile).toList(),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _creatorCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _input('studentUsername', _studentCtrl),
            const SizedBox(height: 8),
            _input('title', _titleCtrl),
            const SizedBox(height: 8),
            _input('description (선택)', _descCtrl),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _create,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Assignment'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _loading ? null : _refresh,
                  tooltip: '새로고침',
                  icon: const Icon(Icons.refresh),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(Assignment a) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.assignment_outlined),
        title: Text(a.title),
        subtitle: Text(
          'by ${a.teacherUsername} → ${a.studentUsername}\n'
          '${a.status.name} · ${a.description ?? ''}',
        ),
        isThreeLine: true,
        onTap: () => _changeStatus(a),
      ),
    );
  }

  Widget _input(String hint, TextEditingController c) {
    return TextField(
      controller: c,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
      ).copyWith(hintText: hint),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
