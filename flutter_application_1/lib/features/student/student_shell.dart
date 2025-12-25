// lib/features/student/student_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import 'pages/student_home_page.dart';
import 'pages/student_lessons_page.dart';
import 'pages/student_homework_page.dart';
import '../../shared/services/auth_state.dart';
import '../../shared/widgets/profile_avatar.dart';

/// 학생용 앱 쉘: 하단 탭 네비게이션(홈/수업/숙제)
/// - IndexedStack으로 탭 상태 유지
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  static const _pages = <Widget>[
    StudentHomePage(),     // 홈 (오늘 수업/숙제 요약)
    StudentLessonsPage(),  // 내 수업
    StudentHomeworkPage(), // 내 숙제
  ];

  static const _pageTitles = <String>[
    '홈',
    '수업',
    '숙제',
  ];

  @override
  void initState() {
    super.initState();
    safePrint('[StudentShell] 진입');
  }

  Future<void> _handleLogout() async {
    safePrint('[StudentShell] 버튼 클릭: 로그아웃');
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
          const ProfileAvatar(),
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
        onDestinationSelected: (i) {
          safePrint('[StudentShell] 탭 변경: ${_pageTitles[i]}');
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: '수업',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: '숙제',
          ),
        ],
      ),
    );
  }
}
