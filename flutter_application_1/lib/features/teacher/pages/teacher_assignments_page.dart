import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../../../models/ModelProvider.dart';
import '../data/assignment_repository.dart';
import '../widgets/assignment_action_sheet.dart';

class TeacherAssignmentsPage extends StatefulWidget {
  const TeacherAssignmentsPage({super.key});

  @override
  State<TeacherAssignmentsPage> createState() => _TeacherAssignmentsPageState();
}

class _TeacherAssignmentsPageState extends State<TeacherAssignmentsPage> {
  final _repo = AssignmentRepository();
  String _username = '';
  bool _isLoading = false;

  final _teacherList = <Assignment>[];
  final _ownerOnlyList = <Assignment>[];

  final _studentController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _studentController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);
    try {
      final user = await Amplify.Auth.getCurrentUser();
      if (!mounted) return;
      _username = user.username; // non-null
      await _refreshLists();
    } catch (e) {
      safePrint(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('세션 확인 실패')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshLists() async {
    setState(() => _isLoading = true);
    try {
      final byTeacher = await _repo.listAssignmentsByTeacher(
        teacherUsername: _username,
      );
      final ownerOnly = await _repo.listAssignmentsOwnerOnly();
      if (!mounted) return;
      setState(() {
        _teacherList
          ..clear()
          ..addAll(byTeacher);
        _ownerOnlyList
          ..clear()
          ..addAll(ownerOnly);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _create() async {
    final student = _studentController.text.trim();
    final title = _titleController.text.trim();
    final descText = _descController.text.trim();
    final String? desc = descText.isEmpty ? null : descText;

    if (student.isEmpty || title.isEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('studentUsername, title은 필수입니다')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _repo.createAssignment(
        teacherUsername: _username,
        studentUsername: student,
        title: title,
        description: desc,
      );
      _studentController.clear();
      _titleController.clear();
      _descController.clear();
      await _refreshLists();
    } catch (e) {
      safePrint(e);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text('생성 실패: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(Assignment a) async {
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('과제 삭제'),
        content: Text('정말 삭제할까요?\n\n${a.title}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _isLoading = true);
    try {
      await _repo.deleteAssignment(a.id);
      await _refreshLists();
    } catch (e) {
      safePrint(e);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _section(String title, List<Assignment> items) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            ListTile(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: Text('${items.length}개'),
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('항목 없음'),
              )
            else
              ...items.map(_assignmentTile),
          ],
        ),
      ),
    );
  }

  Widget _assignmentTile(Assignment a) {
    // a.title: non-null, a.status: non-null enum, a.description: nullable
    final desc = a.description;
    final subtitleParts = <String>[
      'by ${a.teacherUsername} → ${a.studentUsername}',
      a.status.name,
      if (desc != null && desc.isNotEmpty) desc,
    ];
    final subtitle = subtitleParts.join(' · ');

    return ListTile(
      leading: const Icon(Icons.assignment_outlined),
      title: Text(a.title),
      subtitle: Text(subtitle),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.black87),
        onSelected: (v) async {
          switch (v) {
            case 'sheet':
              await showAssignmentActionSheet(
                context: context,
                assignment: a,
                onChanged: _refreshLists,
                onDeleted: _refreshLists,
              );
              break;
            case 'copyId':
              await Clipboard.setData(ClipboardData(text: a.id));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ID 복사됨')),
              );
              break;
            case 'delete':
              await _confirmDelete(a);
              break;
          }
        },
        itemBuilder: (ctx) => const [
          PopupMenuItem(value: 'sheet', child: Text('액션 시트')),
          PopupMenuItem(value: 'copyId', child: Text('ID 복사')),
          PopupMenuItem(
            value: 'delete',
            child: Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      onLongPress: () async {
        await showAssignmentActionSheet(
          context: context,
          assignment: a,
          onChanged: _refreshLists,
          onDeleted: _refreshLists,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _username.isEmpty ? '(알 수 없음)' : _username;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshLists,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(width: 12),
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 간단 생성 패널
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('교사 패널', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _studentController,
                              decoration: const InputDecoration(
                                labelText: 'studentUsername (필수)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'title (필수)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'description (선택)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _create,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Assignment'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _refreshLists,
                        icon: const Icon(Icons.list_alt),
                        label: const Text('내가 배정한 과제 조회'),
                      ),
                    ],
                  ),
                ),
              ),
              _section('내가 배정한 과제 (filter=teacherUsername)', _teacherList),
              _section('내 과제 (owner-only server filter)', _ownerOnlyList),
            ],
          ),
        ),
      ),
    );
  }
}
