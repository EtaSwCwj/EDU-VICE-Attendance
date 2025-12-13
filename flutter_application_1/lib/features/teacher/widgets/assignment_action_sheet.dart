import 'package:flutter/material.dart';

import '../../../models/Assignment.dart';
import '../../../models/AssignmentStatus.dart';
import '../data/assignment_editor.dart';
import '../data/assignment_repository.dart';

Future<void> showAssignmentActionSheet({
  required BuildContext context,
  required Assignment assignment,
  required VoidCallback onChanged,
  required VoidCallback onDeleted,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => _AssignmentActionSheet(
      assignment: assignment,
      onChanged: onChanged,
      onDeleted: onDeleted,
    ),
  );
}

class _AssignmentActionSheet extends StatefulWidget {
  final Assignment assignment;
  final VoidCallback onChanged;
  final VoidCallback onDeleted;

  const _AssignmentActionSheet({
    required this.assignment,
    required this.onChanged,
    required this.onDeleted,
  });

  @override
  State<_AssignmentActionSheet> createState() => _AssignmentActionSheetState();
}

class _AssignmentActionSheetState extends State<_AssignmentActionSheet> {
  late final AssignmentRepository _repo;
  late final AssignmentEditor _editor;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _repo = AssignmentRepository();
    _editor = AssignmentEditor(_repo);
  }

  void _snack(String msg) {
    if (!mounted) return;
    final m = ScaffoldMessenger.of(context);
    m.clearSnackBars();
    m.showSnackBar(SnackBar(content: Text(msg)));
  }

  AssignmentStatus get _nextStatus {
    return widget.assignment.status == AssignmentStatus.ASSIGNED
        ? AssignmentStatus.DONE
        : AssignmentStatus.ASSIGNED;
  }

  Future<void> _toggleStatus() async {
    setState(() => _busy = true);
    try {
      await _editor.updateStatus(
        assignment: widget.assignment,
        nextStatus: _nextStatus,
      );
      if (!mounted) return;
      widget.onChanged();
      Navigator.pop(context);
      _snack('상태 변경 완료');
    } catch (e) {
      if (!mounted) return;
      _snack('상태 변경 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.assignment.id;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제'),
        content: Text('정말 삭제할까?\n\n$id'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );

    if (!mounted) return;
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await _editor.deleteById(id);
      if (!mounted) return;
      widget.onDeleted();
      Navigator.pop(context);
      _snack('삭제 완료');
    } catch (e) {
      if (!mounted) return;
      _snack('삭제 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('student: ${a.studentUsername} · status: ${a.status.name}'),
            ),
            const Divider(),
            ListTile(
              enabled: !_busy,
              leading: const Icon(Icons.swap_horiz),
              title: Text('상태 토글 (${a.status.name} → ${_nextStatus.name})'),
              onTap: _busy ? null : _toggleStatus,
            ),
            ListTile(
              enabled: !_busy,
              leading: const Icon(Icons.delete),
              title: const Text('삭제'),
              onTap: _busy ? null : _delete,
            ),
            if (_busy) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(minHeight: 3),
            ],
          ],
        ),
      ),
    );
  }
}
