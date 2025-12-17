// lib/features/home/academy_selector_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../shared/services/auth_state.dart';

/// 여러 학원에 소속된 유저가 학원을 선택하는 화면
class AcademySelectorPage extends StatelessWidget {
  const AcademySelectorPage({super.key});

  String _getRoleText(String role) {
    switch (role) {
      case 'owner':
        return '원장';
      case 'teacher':
        return '선생님';
      case 'student':
        return '학생';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;
    final academies = auth.academies;
    final memberships = user?.memberships ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('학원 선택'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 아이콘
              const Icon(
                Icons.school,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),

              // 제목
              Text(
                '학원을 선택하세요',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 설명
              Text(
                '${user?.name ?? '사용자'}님은 ${memberships.length}개 학원에 소속되어 있습니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 학원 목록
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: memberships.length,
                  itemBuilder: (context, index) {
                    final membership = memberships[index];
                    final academy = academies.firstWhere(
                      (a) => a.id == membership.academyId,
                      orElse: () => academies.first,
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            academy.name[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          academy.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          '역할: ${_getRoleText(membership.role)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // 학원 선택
                          auth.selectMembership(membership);
                          // 홈으로 이동 (라우터가 자동으로 올바른 Shell로 보내줌)
                          context.go('/home');
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
