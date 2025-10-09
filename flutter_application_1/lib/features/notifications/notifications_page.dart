import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  final String role;
  const NotificationsPage({required this.role, super.key});

  @override
  Widget build(BuildContext context) {
    final title = switch (role) {
      'owner' => '알림(원장)',
      'teacher' => '알림(선생)',
      _ => '알림(학생)',
    };

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Text('Stub: 역할별 알림 화면 골격'),
        ],
      ),
    );
  }
}
