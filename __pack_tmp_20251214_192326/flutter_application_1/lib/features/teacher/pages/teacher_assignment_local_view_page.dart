import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/Assignment.dart';
import '../../student_assignments/student_assignment_local_snapshot.dart';

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
  bool _loading = true;

  late StudentAssignmentLocalSnapshot _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = const StudentAssignmentLocalSnapshot(
      submitted: false,
      submittedAtEpochMillis: null,
      note: '',
      photoPaths: <String>[],
    );
    unawaited(_loadLocal());
  }

  String get _studentUsername => widget.assignment.studentUsername;
  String get _assignmentId => widget.assignment.id;

  Future<void> _loadLocal() async {
    setState(() => _loading = true);

    try {
      final snap = await StudentAssignmentLocalSnapshotLoader.load(
        studentUsername: _studentUsername,
        assignmentId: _assignmentId,
      );

      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _snapshot = const StudentAssignmentLocalSnapshot(
          submitted: false,
          submittedAtEpochMillis: null,
          note: '',
          photoPaths: <String>[],
        );
        _loading = false;
      });
    }
  }

  Future<void> _copyId() async {
    await Clipboard.setData(ClipboardData(text: _assignmentId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID copied')));
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
            onPressed: _loadLocal,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _buildHeaderCard(a),
                const SizedBox(height: 10),
                _buildLocalSummaryCard(),
                const SizedBox(height: 10),
                _buildMemoCard(),
                const SizedBox(height: 10),
                _buildPhotosCard(),
                const SizedBox(height: 10),
                _buildDebugCard(),
              ],
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

  Widget _buildLocalSummaryCard() {
    final submittedText = _snapshot.submitted ? 'YES' : 'NO';
    final noteYesNo = _snapshot.note.trim().isEmpty ? 'NO' : 'YES';
    final submittedAtText = _snapshot.submittedAtEpochMillis == null
        ? '-'
        : _fmtEpochMillis(_snapshot.submittedAtEpochMillis!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _chip(Icons.cloud_off, '로컬 데이터(같은 디바이스)'),
            _chip(Icons.assignment_turned_in, '제출: $submittedText'),
            _chip(Icons.schedule, '제출시각: $submittedAtText'),
            _chip(Icons.notes, '메모: $noteYesNo'),
            _chip(Icons.photo, '사진: ${_snapshot.photoPaths.length}장'),
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

  Widget _buildMemoCard() {
    final memo = _snapshot.note.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('학생 메모(로컬)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (memo.isEmpty)
              const Text('저장된 메모가 없습니다.')
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Text(memo),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('증빙 사진(로컬)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_snapshot.photoPaths.isEmpty)
              const Text('아직 첨부된 사진이 없습니다.')
            else
              Column(
                children: _snapshot.photoPaths.map(_photoTile).toList(),
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
    final kSubmitted = StudentAssignmentLocalSnapshotLoader.debugKeySubmitted(_studentUsername, _assignmentId);
    final kSubmittedAt = StudentAssignmentLocalSnapshotLoader.debugKeySubmittedAt(_studentUsername, _assignmentId);
    final kNote = StudentAssignmentLocalSnapshotLoader.debugKeyNote(_studentUsername, _assignmentId);
    final kAttach = StudentAssignmentLocalSnapshotLoader.debugKeyAttachment(_studentUsername, _assignmentId);

    final keys = <String>[kSubmitted, kSubmittedAt, kNote, kAttach];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('디버그(로컬 키 + 타입)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            FutureBuilder<Map<String, String>>(
              future: StudentAssignmentLocalSnapshotLoader.debugKeyTypes(keys),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  );
                }

                final typeMap = snap.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: keys.map((k) {
                    final typeInfo = typeMap[k] ?? 'unknown';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $k  ->  $typeInfo'),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 6),
            const Text(
              '※ 지금 단계(디바이스 공유)는 “같은 폰에서만” 교사가 볼 수 있게 하는 용도입니다.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
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
}
