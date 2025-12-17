// lib/features/home/no_academy_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
                '학원 관리자에게 아래 QR코드를 보여주시거나\n학원 코드를 입력하여 가입 요청하세요.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // QR 코드
              if (user != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: user.id,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '유저 ID: ${user.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
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

              // 학원 코드 입력 버튼 (향후 구현)
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: 학원 코드 입력 다이얼로그
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('학원 코드 입력 기능은 향후 구현 예정입니다'),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('학원 코드로 가입 요청'),
                style: OutlinedButton.styleFrom(
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
                        '1. 학원 관리자에게 위의 QR코드를 보여주세요.\n'
                        '2. 또는 학원 관리자로부터 학원 코드를 받아 "학원 코드로 가입 요청" 버튼을 눌러 입력하세요.\n\n'
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
