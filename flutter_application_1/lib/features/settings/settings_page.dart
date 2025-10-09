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
        ListTile(
          title: const Text('현재 사용자'),
          subtitle: Text('${auth.user?.name ?? ''} (${role})'),
        ),
        const Divider(),
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
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('로그아웃'),
          onTap: () => context.read<AuthState>().signOut(),
        ),
      ],
    );
  }
}
