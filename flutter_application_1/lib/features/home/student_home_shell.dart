// lib/features/home/student_home_shell.dart
import 'package:flutter/material.dart';
import '../homework/homework_page.dart';

/// 학생 전용 홈 셸
/// - 탭: [대시보드, 학습(숙제)]
class StudentHomeShell extends StatefulWidget {
  const StudentHomeShell({super.key});

  @override
  State<StudentHomeShell> createState() => _StudentHomeShellState();
}

class _StudentHomeShellState extends State<StudentHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _StudentDashboardStub(),
      const HomeworkPage(), // 기존 학생용 숙제/학습 탭
    ];
    final titles = <String>["학생 대시보드", "학습"];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '대시보드',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '학습',
          ),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// 최소 대시보드 스텁(추후 실제 위젯으로 교체)
class _StudentDashboardStub extends StatelessWidget {
  const _StudentDashboardStub();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        '학생 대시보드(스텁)',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}
