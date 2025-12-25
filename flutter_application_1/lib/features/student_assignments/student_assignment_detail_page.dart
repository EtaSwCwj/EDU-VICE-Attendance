import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/Assignment.dart';
import 'student_assignment_local_snapshot.dart';

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
  bool _loading = true;

  late StudentAssignmentLocalSnapshot _snapshot;
  late final TextEditingController _memoController;

  final ImagePicker _picker = ImagePicker();
  bool _photoWorking = false;

  @override
  void initState() {
    super.initState();

    _snapshot = const StudentAssignmentLocalSnapshot(
      submitted: false,
      submittedAtEpochMillis: null,
      note: '',
      photoPaths: <String>[],
    );

    _memoController = TextEditingController();
    unawaited(_loadLocal());
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  String get _studentUsername => widget.assignment.studentUsername;
  String get _assignmentId => widget.assignment.id;

  String? get _photoPath {
    if (_snapshot.photoPaths.isEmpty) return null;
    final p = _snapshot.photoPaths.first.trim();
    return p.isEmpty ? null : p;
  }

  bool get _photoExists {
    final p = _photoPath;
    if (p == null) return false;
    return File(p).existsSync();
  }

  void _snack(String msg) {
    if (!mounted) return;
    final m = ScaffoldMessenger.of(context);
    m.clearSnackBars();
    m.showSnackBar(SnackBar(content: Text(msg)));
  }

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
        _memoController.text = snap.note;
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
        _memoController.text = '';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    await StudentAssignmentLocalSnapshotLoader.repo.submit(
      studentUsername: _studentUsername,
      assignmentId: _assignmentId,
    );
    await _loadLocal();
  }

  Future<void> _unsubmit() async {
    await StudentAssignmentLocalSnapshotLoader.repo.unsubmit(
      studentUsername: _studentUsername,
      assignmentId: _assignmentId,
    );
    await _loadLocal();
  }

  Future<void> _saveMemo() async {
    final note = _memoController.text;
    await StudentAssignmentLocalSnapshotLoader.repo.saveNote(
      studentUsername: _studentUsername,
      assignmentId: _assignmentId,
      note: note,
    );
    await _loadLocal();
    _snack('메모 저장 완료(로컬)');
  }

  Future<void> _clearMemo() async {
    await StudentAssignmentLocalSnapshotLoader.repo.clearNote(
      studentUsername: _studentUsername,
      assignmentId: _assignmentId,
    );
    await _loadLocal();
    _snack('메모 삭제 완료(로컬)');
  }

  Future<void> _pickPhoto() async {
    if (_photoWorking) return;
    setState(() => _photoWorking = true);

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) {
        if (mounted) setState(() => _photoWorking = false);
        return;
      }

      final path = picked.path.trim();
      if (path.isEmpty) {
        if (mounted) setState(() => _photoWorking = false);
        return;
      }

      // 정책: 지금 단계는 "1장"만 관리 (리스트지만 len=1로 유지)
      await StudentAssignmentLocalSnapshotLoader.repo.saveAttachmentPaths(
        studentUsername: _studentUsername,
        assignmentId: _assignmentId,
        paths: <String>[path],
      );

      await _loadLocal();
      _snack('사진 첨부 완료(로컬)');
    } catch (e) {
      _snack('사진 선택 실패: $e');
    } finally {
      if (mounted) setState(() => _photoWorking = false);
    }
  }

  Future<void> _removePhoto() async {
    if (_photoWorking) return;
    setState(() => _photoWorking = true);

    try {
      await StudentAssignmentLocalSnapshotLoader.repo.clearAttachments(
        studentUsername: _studentUsername,
        assignmentId: _assignmentId,
      );
      await _loadLocal();
      _snack('사진 삭제 완료(로컬)');
    } catch (e) {
      _snack('사진 삭제 실패: $e');
    } finally {
      if (mounted) setState(() => _photoWorking = false);
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
        title: const Text('과제 상세'),
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
                _buildSubmitCard(),
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

  Widget _buildSubmitCard() {
    final submittedText = _snapshot.submitted ? 'YES' : 'NO';
    final submittedAtText = _snapshot.submittedAtEpochMillis == null
        ? '-'
        : _fmtEpochMillis(_snapshot.submittedAtEpochMillis!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('제출 (로컬)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _pill('submitted: $submittedText'),
                _pill('submittedAt: $submittedAtText'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _snapshot.submitted ? null : _submit,
                    icon: const Icon(Icons.upload),
                    label: const Text('제출'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _snapshot.submitted ? _unsubmit : null,
                    icon: const Icon(Icons.reply),
                    label: const Text('제출 취소'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '※ 현재는 로컬 저장만 합니다. (AWS 업로드/교사 공유 X)',
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

  Widget _buildMemoCard() {
    final canSave = _memoController.text != _snapshot.note;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('내 메모 (로컬)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextField(
              controller: _memoController,
              maxLines: 6,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: canSave ? _saveMemo : null,
                    child: const Text('메모 저장'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _memoController.text.trim().isEmpty ? null : _clearMemo,
                    child: const Text('메모 삭제'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosCard() {
    final path = _photoPath;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('증빙 사진 (로컬)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),

            if (_photoWorking)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(minHeight: 3),
              ),

            if (path == null) ...[
              const Text('아직 첨부된 사진이 없습니다.'),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _photoWorking ? null : _pickPhoto,
                icon: const Icon(Icons.photo_library),
                label: const Text('사진 선택'),
              ),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _photoExists
                    ? Image.file(File(path), fit: BoxFit.cover)
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('파일이 없습니다:\n$path'),
                      ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _photoWorking ? null : _pickPhoto,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('다른 사진 선택'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _photoWorking ? null : _removePhoto,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('삭제'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '경로: $path',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDebugCard() {
    final kSubmitted = StudentAssignmentLocalSnapshotLoader.debugKeySubmitted(
      studentUsername: _studentUsername,
      assignmentId: _assignmentId,
    );
    final kSubmittedAt = StudentAssignmentLocalSnapshotLoader.debugKeySubmittedAt(
      studentUsername: _studentUsername,
      assignmentId: _assignmentId,
    );
    final kNote = StudentAssignmentLocalSnapshotLoader.debugKeyNote(
      studentUsername: _studentUsername,
      assignmentId: _assignmentId,
    );
    final kAttach = StudentAssignmentLocalSnapshotLoader.debugKeyAttachment(
      studentUsername: _studentUsername,
      assignmentId: _assignmentId,
    );

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
