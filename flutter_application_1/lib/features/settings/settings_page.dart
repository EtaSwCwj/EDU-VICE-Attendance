import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/services/auth_state.dart';
import '../../shared/services/mock_storage.dart';

class SettingsPage extends StatelessWidget {
  final String role;
  const SettingsPage({required this.role, super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return ListView(
      children: [
        // 사용자 정보
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(auth.user?.name ?? ''),
          subtitle: Text(_getRoleText(role)),
        ),
        const Divider(),

        // 일반 설정
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '⚙️ 설정',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('데이터 새로고침'),
          onTap: () async {
            await context.read<AuthState>().reloadFromStorage();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('데이터를 다시 불러왔습니다')),
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.folder_open),
          title: const Text('accounts.json 경로 보기'),
          onTap: () async {
            final path = await MockStorage.filePath();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('경로: $path')));
            }
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          onTap: () => context.read<AuthState>().signOut(),
        ),
      ],
    );
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return '관리자';
      case 'owner':
        return '원장';
      case 'teacher':
        return '선생';
      case 'student':
        return '학생';
      default:
        return role;
    }
  }
}
