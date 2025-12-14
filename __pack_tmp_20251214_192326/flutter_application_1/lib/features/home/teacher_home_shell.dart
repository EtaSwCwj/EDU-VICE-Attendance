// lib/features/home/teacher_home_shell.dart
import 'package:flutter/material.dart';

import '../home/dashboard_pages.dart';
import '../teacher_homework/teacher_homework_page.dart';

/// 교사용 홈 쉘:
/// - 하단 탭: [대시보드, 과제]
/// - 과제 탭: TeacherHomeworkPage 내에서 학생 선택 → 검사/확정
class TeacherHomeShell extends StatefulWidget {
  const TeacherHomeShell({super.key});

  @override
  State<TeacherHomeShell> createState() => _TeacherHomeShellState();
}

class _TeacherHomeShellState extends State<TeacherHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const TeacherDashboardPage(),
      const TeacherHomeworkPage(),
    ];

    final titles = <String>["교사 대시보드", "과제"];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: '대시보드'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: '과제'),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
