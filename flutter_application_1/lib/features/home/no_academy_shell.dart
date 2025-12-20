// lib/features/home/no_academy_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../shared/services/auth_state.dart';

/// 소속 학원이 없는 유저용 화면
class NoAcademyShell extends StatelessWidget {
  const NoAcademyShell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EDU-VICE'),
        actions: [
          // 새로고침 버튼 (멤버 등록 후 확인용)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              safePrint('[NoAcademyShell] 새로고침 버튼 클릭');
              auth.refreshAuth();
            },
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 아이콘
                const Icon(
                  Icons.school_outlined,
                  size: 100,
                  color: Colors.grey,
                ),
                const SizedBox(height: 32),

                // 안내 문구
                Text(
                  '학원에 등록되지 않았습니다',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '학원 관리자에게 아래 정보를 알려주세요.\n등록 후 새로고침 버튼을 눌러주세요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // 이메일 표시 (핵심!)
                if (user != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '내 이메일',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email ?? '이메일 없음',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                // QR 코드 (나중에 QR 스캔 기능용)
                if (user != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: user.email ?? user.id,
                          version: QrVersions.auto,
                          size: 150.0,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 48),

                // 새로고침 버튼 (크게)
                FilledButton.icon(
                  onPressed: () {
                    safePrint('[NoAcademyShell] 새로고침 버튼 클릭');
                    auth.refreshAuth();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('등록 확인'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 도움말
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('도움말'),
                        content: const Text(
                          '학원에 등록하려면:\n\n'
                          '1. 학원 관리자에게 위의 이메일을 알려주세요.\n'
                          '2. 관리자가 등록하면 완료됩니다.\n'
                          '3. "등록 확인" 버튼을 눌러 확인하세요.\n\n'
                          '등록이 완료되면 자동으로 학원 화면으로 이동합니다.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('도움말'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
