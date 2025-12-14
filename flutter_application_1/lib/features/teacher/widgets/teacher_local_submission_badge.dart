import 'package:flutter/material.dart';

import '../../student_assignments/student_assignment_local_submission.dart';

class TeacherLocalSubmissionBadge extends StatelessWidget {
  final String studentUsername;
  final String assignmentId;

  const TeacherLocalSubmissionBadge({
    super.key,
    required this.studentUsername,
    required this.assignmentId,
  });

  String _ymdhm(DateTime? local) {
    if (local == null) return '-';
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LocalSubmitState>(
      future: _LocalSubmitState.load(
        studentUsername: studentUsername,
        assignmentId: assignmentId,
      ),
      builder: (context, snap) {
        if (!snap.hasData) {
          // 목록 성능/UX 위해 과한 로딩 UI는 피하고, 작은 placeholder만
          return const _MiniChip(text: '제출 …', icon: Icons.hourglass_empty);
        }

        final s = snap.data!;
        final submittedAtLocal = (s.submittedAtEpochMillis == null)
            ? null
            : DateTime.fromMillisecondsSinceEpoch(s.submittedAtEpochMillis!, isUtc: true).toLocal();

        if (!s.isSubmitted) {
          return const _MiniChip(text: '제출 NO', icon: Icons.radio_button_unchecked);
        }

        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            const _MiniChip(text: '제출 YES', icon: Icons.check_circle),
            _MiniChip(text: _ymdhm(submittedAtLocal), icon: Icons.schedule),
          ],
        );
      },
    );
  }
}

class _LocalSubmitState {
  final bool isSubmitted;
  final int? submittedAtEpochMillis;

  const _LocalSubmitState({
    required this.isSubmitted,
    required this.submittedAtEpochMillis,
  });

  static Future<_LocalSubmitState> load({
    required String studentUsername,
    required String assignmentId,
  }) async {
    final submitted = await StudentAssignmentLocalSubmission.isSubmitted(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
    );

    final submittedAt = await StudentAssignmentLocalSubmission.submittedAtEpochMillis(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
    );

    return _LocalSubmitState(
      isSubmitted: submitted,
      submittedAtEpochMillis: submittedAt,
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _MiniChip({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
