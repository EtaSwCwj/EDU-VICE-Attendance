import 'package:flutter/material.dart';

class HomeworkPage extends StatelessWidget {
  final String role;
  const HomeworkPage({required this.role, super.key});

  @override
  Widget build(BuildContext context) {
    final title = switch (role) {
      'owner' => '숙제(원장)',
      'teacher' => '숙제(선생)',
      _ => '숙제(학생)',
    };

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Text('Stub: 역할별 숙제 화면 골격'),
        ],
      ),
    );
  }
}
