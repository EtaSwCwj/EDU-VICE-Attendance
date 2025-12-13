import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import '../../models/Assignment.dart';
import '../../models/AssignmentStatus.dart';
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
  final _repo = StudentAssignmentRepository();
  bool _working = false;

  void _snack(String msg) {
    if (!mounted) return;
    final m = ScaffoldMessenger.of(context);
    m.clearSnackBars();
    m.showSnackBar(SnackBar(content: Text(msg)));
  }

  // ✅ StudentHomeShell에서 이미 검증된 Temporal 처리 방식
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

    // fallback: parse string
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _ymd(DateTime? d) {
    if (d == null) return '-';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _setStatus(AssignmentStatus next) async {
    setState(() => _working = true);
    try {
      await _repo.updateAssignmentStatus(id: widget.assignment.id, status: next);
      if (!mounted) return;
      _snack('상태 변경 완료: ${next.name}');
      Navigator.of(context).pop(true); // ✅ 목록에서 refresh
    } catch (e) {
      if (!mounted) return;
      _snack('상태 변경 실패: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('과제 상세'),
        actions: [
          IconButton(
            tooltip: 'ID 보기',
            onPressed: () => _snack('id: ${a.id}'),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

          const SizedBox(height: 10),
          Text(
            '※ 상세에서 상태 변경하면 목록 화면을 새로고침하도록 설계됨(테스트 편의용).',
            style: Theme.of(context).textTheme.bodySmall,
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
