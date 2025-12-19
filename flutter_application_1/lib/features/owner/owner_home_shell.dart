// lib/features/owner/owner_home_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../teacher/pages/teacher_home_page_new.dart';
import '../teacher/pages/teacher_classes_page.dart';
import '../teacher/pages/teacher_students_page.dart';
import '../teacher_homework/teacher_homework_page_aws.dart';
import '../books/presentation/pages/book_management_page.dart';
import 'pages/owner_management_page.dart';
import '../../shared/services/auth_state.dart';
import '../../shared/widgets/profile_avatar.dart';

/// 원장용 앱 쉘: 하단 탭 네비게이션 (홈/수업/학생/숙제/교재/관리)
/// - TeacherShell 5개 탭 + 관리 탭 추가
/// - IndexedStack으로 탭 상태 유지
class OwnerHomeShell extends StatefulWidget {
  const OwnerHomeShell({super.key});

  @override
  State<OwnerHomeShell> createState() => _OwnerHomeShellState();
}

class _OwnerHomeShellState extends State<OwnerHomeShell> {
  int _index = 0;

  static const _pages = <Widget>[
    TeacherHomePage(),        // 수업 관리 페이지
    TeacherClassesPage(),     // 반 관리
    TeacherStudentsPage(),    // 학생 관리
    TeacherHomeworkPageAws(), // 숙제 관리 (AWS)
    BookManagementPage(),     // 교재 관리 + 설정 접근
    OwnerManagementPage(),    // 관리 (선생/학생/배정)
  ];

  static const _pageTitles = <String>[
    '홈',
    '수업',
    '학생',
    '숙제',
    '교재',
    '관리',
  ];

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthState>().signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final academy = authState.currentAcademy;

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_index]),
        actions: [
          const ProfileAvatar(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // 학원 정보 카드
          if (academy != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          academy.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      if (academy.code != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            academy.code!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (academy.address != null || academy.phone != null) ...[
                    const SizedBox(height: 8),
                    if (academy.address != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            academy.address!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    if (academy.phone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            academy.phone!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          // 페이지 콘텐츠
          Expanded(
            child: IndexedStack(index: _index, children: _pages),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_),
            label: '수업',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: '학생',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: '숙제',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '교재',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: '관리',
          ),
        ],
      ),
    );
  }
}
