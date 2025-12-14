// lib/features/home/owner_home_shell.dart
import 'package:flutter/material.dart';

/// 원장 전용 홈 셸
/// - 탭: [대시보드, 소속/배정] (읽기 우선 골격)
class OwnerHomeShell extends StatefulWidget {
  const OwnerHomeShell({super.key});

  @override
  State<OwnerHomeShell> createState() => _OwnerHomeShellState();
}

class _OwnerHomeShellState extends State<OwnerHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _OwnerDashboardStub(),
      const _OwnerMembersStub(),
    ];
    final titles = <String>["원장 대시보드", "소속·배정"];

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
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: '소속·배정',
          ),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _OwnerDashboardStub extends StatelessWidget {
  const _OwnerDashboardStub();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        '원장 대시보드(스텁)',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _OwnerMembersStub extends StatelessWidget {
  const _OwnerMembersStub();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        '소속/배정 관리(읽기 우선, 스텁)',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}
