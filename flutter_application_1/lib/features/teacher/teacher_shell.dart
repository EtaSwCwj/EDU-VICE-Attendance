import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'pages/teacher_home_page_new.dart';
import 'pages/teacher_classes_page.dart';
import 'pages/teacher_students_page.dart';
import '../teacher_homework/teacher_homework_page_aws.dart';
import '../books/presentation/pages/book_management_page.dart';
import '../../shared/services/auth_state.dart';

/// 교사용 앱 쉘: 하단 탭 네비게이션(홈/수업/학생/숙제/교재)
/// - IndexedStack으로 탭 상태 유지
class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _index = 0;

  static const _pages = <Widget>[
    TeacherHomePage(),        // 수업 관리 페이지
    TeacherClassesPage(),     // 반 관리
    TeacherStudentsPage(),    // 학생 관리
    TeacherHomeworkPageAws(), // 숙제 관리 (AWS)
    BookManagementPage(),     // 교재 관리 + 설정 접근
  ];

  static const _pageTitles = <String>[
    '홈',
    '수업',
    '학생',
    '숙제',
    '교재',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
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
        ],
      ),
    );
  }
}
