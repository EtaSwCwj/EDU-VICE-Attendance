import 'package:flutter/material.dart';
import '../../teacher/data/assignment_editor.dart';
import '../../../models/ModelProvider.dart';

Future<void> showAssignmentActionSheet({
  required BuildContext context,
  required Assignment assignment,
  VoidCallback? onChanged,
  VoidCallback? onDeleted,
}) async {
  final theme = Theme.of(context);

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: false,
    builder: (bottomCtx) {
      final isDone = assignment.status == AssignmentStatus.DONE;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // assignment.title: non-null 가정(스키마 title: String!)
            Text(
              assignment.title,
              style: theme.textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'by ${assignment.teacherUsername} → ${assignment.studentUsername}', // 모두 non-null
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            const Divider(),

            // 상태 토글
            ListTile(
              leading: Icon(isDone ? Icons.undo : Icons.check_circle),
              title: Text(isDone ? '상태 되돌리기(ASSIGNED)' : '완료로 표시(DONE)'),
              onTap: () async {
                // await 이전에 레퍼런스 캡처
                final nav = Navigator.of(bottomCtx);
                final messenger = ScaffoldMessenger.of(bottomCtx);

                try {
                  final next =
                      isDone ? AssignmentStatus.ASSIGNED : AssignmentStatus.DONE;
                  await AssignmentEditor.updateStatus(id: assignment.id, status: next);
                  if (!bottomCtx.mounted) return;
                  nav.pop(); // 시트 닫기
                  messenger.showSnackBar(
                    SnackBar(content: Text('상태 변경: ${next.name}')),
                  );
                  onChanged?.call();
                } on Exception catch (e) {
                  if (!bottomCtx.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('상태 변경 실패: $e')),
                  );
                }
              },
            ),

            // 삭제
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('삭제'),
              textColor: theme.colorScheme.error,
              iconColor: theme.colorScheme.error,
              onTap: () async {
                final nav = Navigator.of(bottomCtx);
                final messenger = ScaffoldMessenger.of(bottomCtx);

                final ok = await showDialog<bool>(
                  context: bottomCtx,
                  builder: (dctx) => AlertDialog(
                    title: const Text('과제 삭제'),
                    content: const Text('정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dctx).pop(false),
                        child: const Text('취소'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dctx).pop(true),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;

                try {
                  final success = await AssignmentEditor.deleteById(assignment.id);
                  if (!success) throw Exception('삭제 실패');
                  if (!bottomCtx.mounted) return;
                  nav.pop(); // 시트 닫기
                  messenger.showSnackBar(const SnackBar(content: Text('삭제 완료')));
                  onDeleted?.call();
                } on Exception catch (e) {
                  if (!bottomCtx.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('삭제 실패: $e')),
                  );
                }
              },
            ),

            const SizedBox(height: 4),
            const Divider(),
            Text(
              'ID: ${assignment.id}',
              style: theme.textTheme.bodySmall!.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
