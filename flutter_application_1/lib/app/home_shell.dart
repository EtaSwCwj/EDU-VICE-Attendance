import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/services/auth_state.dart';
import '../shared/models/account.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final Membership? m = auth.currentMembership;
    final role = m?.role ?? 'guest';

    // 역할별 탭 정의
    final tabs = _tabsForRole(role);
    final items = tabs.map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Home — ${auth.user?.name ?? ""}'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthState>().signOut(),
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: tabs[_index].body,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: items,
      ),
    );
  }

  List<_TabDef> _tabsForRole(String role) {
    switch (role) {
      case 'owner':
        return const [
          _TabDef('대시보드', Icons.dashboard_outlined, _Stub('원장 대시보드')),
          _TabDef('출석', Icons.how_to_reg_outlined, _Stub('출석(원장)')),
          _TabDef('숙제', Icons.assignment_outlined, _Stub('숙제(원장)')),
          _TabDef('알림', Icons.notifications_none, _Stub('알림(원장)')),
          _TabDef('설정', Icons.settings_outlined, _Stub('설정(원장)')),
        ];
      case 'teacher':
        return const [
          _TabDef('대시보드', Icons.dashboard_customize_outlined, _Stub('선생 대시보드')),
          _TabDef('출석', Icons.fact_check_outlined, _Stub('출석(선생)')),
          _TabDef('숙제', Icons.edit_note_outlined, _Stub('숙제(선생)')),
          _TabDef('알림', Icons.notifications_none, _Stub('알림(선생)')),
          _TabDef('설정', Icons.settings_outlined, _Stub('설정(선생)')),
        ];
      case 'student':
        return const [
          _TabDef('홈', Icons.home_outlined, _Stub('학생 홈')),
          _TabDef('출석', Icons.emoji_people_outlined, _Stub('출석(학생)')),
          _TabDef('숙제', Icons.checklist_outlined, _Stub('숙제(학생)')),
          _TabDef('알림', Icons.notifications_none, _Stub('알림(학생)')),
          _TabDef('설정', Icons.settings_outlined, _Stub('설정(학생)')),
        ];
      default:
        return const [_TabDef('홈', Icons.home_outlined, _Stub('게스트'))];
    }
  }
}

class _TabDef {
  final String label;
  final IconData icon;
  final Widget body;
  const _TabDef(this.label, this.icon, this.body);
}

class _Stub extends StatelessWidget {
  final String text;
  const _Stub(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, style: const TextStyle(fontSize: 18)));
  }
}
