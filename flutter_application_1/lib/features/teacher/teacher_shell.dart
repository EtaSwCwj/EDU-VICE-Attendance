import 'package:flutter/material.dart';
import 'pages/teacher_home_page_new.dart';
import 'pages/teacher_classes_page.dart';
import 'pages/teacher_students_page.dart';
import 'pages/teacher_assignments_page.dart';

/// 교사용 앱 쉘: 하단 탭 네비게이션(홈/수업/학생/숙제)
/// - IndexedStack으로 탭 상태 유지
class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _index = 0;

  static const _pages = <Widget>[
    TeacherHomePage(), // ✅ 새로운 수업 관리 페이지
    TeacherClassesPage(),
    TeacherStudentsPage(),
    TeacherAssignmentsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        ],
      ),
    );
  }
}
