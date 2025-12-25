import 'package:flutter/material.dart';

import '../student_assignments/student_assignment_local_submission.dart';

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
          return const SizedBox(
            height: 26,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final s = snap.data!;
        final submittedAtLocal = (s.submittedAtEpochMillis == null)
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                s.submittedAtEpochMillis!,
                isUtc: true,
              ).toLocal();

        return Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              avatar: Icon(
                s.isSubmitted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
              ),
              label: Text(s.isSubmitted ? '제출 YES(로컬)' : '제출 NO(로컬)'),
            ),
            if (s.isSubmitted)
              Chip(
                avatar: const Icon(Icons.schedule, size: 18),
                label: Text(_ymdhm(submittedAtLocal)),
              ),
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
