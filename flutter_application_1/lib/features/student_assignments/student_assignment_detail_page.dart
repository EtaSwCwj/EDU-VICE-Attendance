import 'dart:async';
import 'dart:io';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/Assignment.dart';
import '../../models/AssignmentStatus.dart';
import 'student_assignment_local_attachments.dart';
import 'student_assignment_local_notes.dart';
import 'student_assignment_repository.dart';

class StudentAssignmentDetailPage extends StatefulWidget {
  final Assignment assignment;

  const StudentAssignmentDetailPage({
    super.key,
    required this.assignment,
  });

  @override
  State<StudentAssignmentDetailPage> createState() => _StudentAssignmentDetailPageState();
}

class _StudentAssignmentDetailPageState extends State<StudentAssignmentDetailPage> {
  final StudentAssignmentRepository _repo = StudentAssignmentRepository();
  final ImagePicker _picker = ImagePicker();

  bool _working = false;

  String? _studentUsername;

  final TextEditingController _noteController = TextEditingController();
  bool _noteDirty = false;
  bool _noteLoading = true;

  bool _attachLoading = true;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
    _noteController.addListener(() {
      if (!_noteDirty) {
        setState(() => _noteDirty = true);
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final username = user.username;

      final savedNote = await StudentAssignmentLocalNotes.load(
        studentUsername: username,
        assignmentId: widget.assignment.id,
      );

      final savedPath = await StudentAssignmentLocalAttachments.loadPath(
        studentUsername: username,
        assignmentId: widget.assignment.id,
      );

      if (!mounted) return;
      setState(() {
        _studentUsername = username;

        _noteController.text = savedNote;
        _noteDirty = false;
        _noteLoading = false;

        _photoPath = savedPath;
        _attachLoading = false;
      });
    } catch (e, st) {
      safePrint('StudentAssignmentDetail boot failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _noteLoading = false;
        _attachLoading = false;
      });
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    final m = ScaffoldMessenger.of(context);
    m.clearSnackBars();
    m.showSnackBar(SnackBar(content: Text(msg)));
  }

  DateTime? _temporalToLocalDateTime(Object? v) {
    if (v == null) return null;

    if (v is TemporalDateTime) {
      return v.getDateTimeInUtc().toLocal();
    }

    if (v is TemporalDate) {
      final s = v.format(); // yyyy-MM-dd
      final parts = s.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return DateTime(y, m, d);
        }
      }
      return null;
    }

    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _ymd(DateTime? local) {
    if (local == null) return '-';
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _copyId() async {
    await Clipboard.setData(ClipboardData(text: widget.assignment.id));
    _snack('ID 복사 완료');
  }

  Future<void> _setStatus(AssignmentStatus next) async {
    if (_working) return;
    setState(() => _working = true);

    try {
      await _repo.updateAssignmentStatus(
        id: widget.assignment.id,
        status: next,
      );

      if (!mounted) return;
      _snack('상태 변경 완료: ${next.name}');
      Navigator.of(context).pop(true);
    } catch (e, st) {
      safePrint('StudentAssignmentDetail setStatus failed: $e\n$st');
      if (!mounted) return;
      _snack('상태 변경 실패: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _saveLocalNote() async {
    final username = _studentUsername;
    if (username == null || username.isEmpty) {
      _snack('세션 확인 필요(로그인)');
      return;
    }

    await StudentAssignmentLocalNotes.save(
      studentUsername: username,
      assignmentId: widget.assignment.id,
      note: _noteController.text,
    );

    if (!mounted) return;
    setState(() => _noteDirty = false);
    _snack('내 메모 저장 완료(로컬)');
  }

  Future<void> _clearLocalNote() async {
    final username = _studentUsername;
    if (username == null || username.isEmpty) {
      _snack('세션 확인 필요(로그인)');
      return;
    }

    await StudentAssignmentLocalNotes.clear(
      studentUsername: username,
      assignmentId: widget.assignment.id,
    );

    if (!mounted) return;
    setState(() {
      _noteController.text = '';
      _noteDirty = false;
    });

    _snack('내 메모 삭제 완료(로컬)');
  }

  Future<void> _pickPhoto() async {
    final username = _studentUsername;
    if (username == null || username.isEmpty) {
      _snack('세션 확인 필요(로그인)');
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;

      final path = picked.path;
      await StudentAssignmentLocalAttachments.savePath(
        studentUsername: username,
        assignmentId: widget.assignment.id,
        path: path,
      );

      if (!mounted) return;
      setState(() => _photoPath = path);
      _snack('사진 첨부 완료(로컬)');
    } catch (e, st) {
      safePrint('pickPhoto failed: $e\n$st');
      _snack('사진 선택 실패: $e');
    }
  }

  Future<void> _removePhoto() async {
    final username = _studentUsername;
    if (username == null || username.isEmpty) {
      _snack('세션 확인 필요(로그인)');
      return;
    }

    await StudentAssignmentLocalAttachments.clear(
      studentUsername: username,
      assignmentId: widget.assignment.id,
    );

    if (!mounted) return;
    setState(() => _photoPath = null);
    _snack('사진 삭제 완료(로컬)');
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;

    final isDone = a.status == AssignmentStatus.DONE;

    final dueLocal = _temporalToLocalDateTime((a as dynamic).dueDate);
    final createdLocal = _temporalToLocalDateTime((a as dynamic).createdAt);

    final title = a.title;
    final teacher = a.teacherUsername;
    final student = a.studentUsername;
    final desc = (a.description ?? '').trim();

    final String? book = (a.book ?? '').trim().isEmpty ? null : a.book;
    final String? range = (a.range ?? '').trim().isEmpty ? null : a.range;

    final bool photoExists =
        _photoPath != null && _photoPath!.trim().isNotEmpty && File(_photoPath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('과제 상세'),
        actions: [
          IconButton(
            tooltip: 'Copy ID',
            onPressed: _copyId,
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _metaChip(Icons.person, 'teacher: $teacher'),
                      _metaChip(Icons.school, 'student: $student'),
                      _metaChip(Icons.flag, 'status: ${a.status.name}'),
                      _metaChip(Icons.event, 'due: ${_ymd(dueLocal)}'),
                      _metaChip(Icons.schedule, 'created: ${_ymd(createdLocal)}'),
                      if (book != null) _metaChip(Icons.menu_book, 'book: $book'),
                      if (range != null) _metaChip(Icons.format_list_numbered, 'range: $range'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'id: ${a.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _copyId,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy ID'),
                      ),
                    ],
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(desc, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ 내 메모(로컬/재실행 유지)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '내 메모 (로컬)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  if (_noteLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  TextField(
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: '여기에 메모를 적어두면, 앱 재실행 후에도 유지됩니다.\n(AWS 반영 X)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: (_noteLoading || !_noteDirty) ? null : _saveLocalNote,
                          child: const Text('메모 저장'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (_noteLoading || _noteController.text.trim().isEmpty) ? null : _clearLocalNote,
                          child: const Text('메모 삭제'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ 25-11: 증빙 사진(로컬)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '증빙 사진 (로컬)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  if (_attachLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  if (photoExists) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_photoPath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickPhoto,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('다른 사진 선택'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _removePhoto,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('삭제'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '경로: $_photoPath',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    Text(
                      '아직 첨부된 사진이 없습니다.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('사진 선택'),
                    ),
                    if (_photoPath != null && _photoPath!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '※ 이전에 저장된 경로가 있지만 파일이 없습니다.\n(갤러리 정리/권한/경로 변경일 수 있음)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _removePhoto,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('저장된 경로 삭제'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: (_working || isDone) ? null : () => _setStatus(AssignmentStatus.DONE),
                  child: _working ? const Text('처리 중…') : const Text('DONE'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: (_working || !isDone) ? null : () => _setStatus(AssignmentStatus.ASSIGNED),
                  child: _working ? const Text('처리 중…') : const Text('UNDO'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(text),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }
}
