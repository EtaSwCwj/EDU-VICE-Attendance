import 'package:flutter/material.dart';

import '../../features/student_assignments/student_assignment_local_snapshot.dart';

class LocalDebugCard extends StatelessWidget {
  final List<String> keys;

  const LocalDebugCard({
    super.key,
    required this.keys,
  });

  @override
  Widget build(BuildContext context) {
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
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(minHeight: 2),
                  );
                }

                final map = snap.data ?? <String, String>{};
                final items = keys.map((k) => '• $k  ->  ${map[k] ?? 'null'}').join('\n\n');

                return SelectableText(items, style: const TextStyle(fontFamily: 'monospace'));
              },
            ),
            const SizedBox(height: 10),
            const Text(
              '※ 지금 단계(디바이스 공유)는 “같은 폰에서만” 교사가 볼 수 있게 하는 용도입니다.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
