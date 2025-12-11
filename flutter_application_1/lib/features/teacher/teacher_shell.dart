import 'package:flutter/material.dart';
import 'pages/teacher_home_page.dart';
import 'pages/teacher_classes_page.dart';
import 'pages/teacher_students_page.dart';
import 'pages/teacher_assignments_page.dart';

/// ✅ 교사용 하단 탭 쉘 (홈/수업/학생/숙제)
class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _index = 0;

  final _pages = const [
    TeacherHomePage(),
    TeacherClassesPage(),
    TeacherStudentsPage(),
    TeacherAssignmentsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: '수업'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: '학생'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: '숙제'),
        ],
      ),
    );
  }
}
