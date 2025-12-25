import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/Assignment.dart';
import '../../student_assignments/student_assignment_local_snapshot.dart';
import '../../student_assignments/student_assignment_local_keys.dart';

import '../../../shared/widgets/local_debug_card.dart';

class TeacherAssignmentLocalViewPage extends StatefulWidget {
  final Assignment assignment;

  const TeacherAssignmentLocalViewPage({
    super.key,
    required this.assignment,
  });

  @override
  State<TeacherAssignmentLocalViewPage> createState() => _TeacherAssignmentLocalViewPageState();
}

class _TeacherAssignmentLocalViewPageState extends State<TeacherAssignmentLocalViewPage> {
  int _reloadToken = 0;

  String get _studentUsername => widget.assignment.studentUsername;
  String get _assignmentId => widget.assignment.id;

  Future<StudentAssignmentLocalSnapshot> _loadLocal() {
    return StudentAssignmentLocalSnapshotLoader.load(
      studentUsername: _studentUsername,
      assignmentId: _assignmentId,
    );
  }

  Future<void> _copyId() async {
    await Clipboard.setData(ClipboardData(text: _assignmentId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID copied')));
  }

  void _reload() {
    setState(() => _reloadToken++);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;

    return Scaffold(
      appBar: AppBar(
        title: const Text('과제 상세(로컬 조회)'),
        actions: [
          IconButton(
            tooltip: 'Copy ID',
            onPressed: _copyId,
            icon: const Icon(Icons.copy),
          ),
          IconButton(
            tooltip: 'Reload',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<StudentAssignmentLocalSnapshot>(
        key: ValueKey(_reloadToken),
        future: _loadLocal(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final local = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              _buildHeaderCard(a),
              const SizedBox(height: 10),
              _buildLocalSummaryCard(local),
              const SizedBox(height: 10),
              _buildStudentMemoCard(local),
              const SizedBox(height: 10),
              _buildPhotosCard(local),
              const SizedBox(height: 10),
              _buildDebugCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(Assignment a) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip(Icons.person, 'student: ${a.studentUsername}'),
                _chip(Icons.school, 'teacher: ${a.teacherUsername}'),
                _chip(Icons.flag, 'status: ${a.status.name}'),
                _chip(Icons.key, 'id: ${_shortId(a.id)}'),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            Text(
              (a.description ?? '').trim().isEmpty ? '(description 없음)' : (a.description ?? '').trim(),
            ),
          ],
        ),
      ),
    );
  }

  String _shortId(String id) {
    final n = id.length;
    if (n <= 10) return id;
    return '${id.substring(0, 10)}...';
  }

  Widget _buildLocalSummaryCard(StudentAssignmentLocalSnapshot local) {
    final submittedText = local.submitted ? 'YES' : 'NO';
    final submittedAtText =
        local.submittedAtEpochMillis == null ? '-' : _fmtEpochMillis(local.submittedAtEpochMillis!);
    final hasNoteText = local.note.trim().isEmpty ? 'NO' : 'YES';
    final photoCountText = '${local.photoPaths.length}장';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('로컬 데이터(같은 디바이스)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _pill('제출: $submittedText'),
                _pill('제출시간: $submittedAtText'),
                _pill('메모: $hasNoteText'),
                _pill('사진: $photoCountText'),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '※ 지금 단계(디바이스 공유)는 “같은 폰에서만” 교사가 볼 수 있게 하는 용도입니다.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtEpochMillis(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Widget _buildStudentMemoCard(StudentAssignmentLocalSnapshot local) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('학생 메모(로컬)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Text(
                local.note.trim().isEmpty ? '(메모 없음)' : local.note,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosCard(StudentAssignmentLocalSnapshot local) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('증빙 사진(로컬)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (local.photoPaths.isEmpty)
              const Text('아직 첨부된 사진이 없습니다.')
            else
              Column(
                children: local.photoPaths.map(_photoTile).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _photoTile(String path) {
    final f = File(path);
    final exists = f.existsSync();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!exists)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('파일이 없습니다:\n$path'),
                )
              else
                Image.file(
                  f,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('이미지 로드 실패:\n$path'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  path,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugCard() {
    final keys = StudentAssignmentLocalKeys.all(
      studentUsername: _studentUsername,
      assignmentId: _assignmentId,
    );

    return LocalDebugCard(keys: keys);
  }


  Widget _chip(IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }
}
