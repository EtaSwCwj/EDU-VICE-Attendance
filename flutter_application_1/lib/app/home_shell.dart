import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/services/auth_state.dart';
import '../shared/models/account.dart';

import '../shared/theme/app_theme.dart';
import '../features/home/dashboard_pages.dart';
import '../features/homework/homework_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/settings/settings_page.dart';
import '../features/attendance/attendance_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

// ignore: unused_element
class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final Membership? m = auth.currentMembership;
    final role = m?.role ?? 'guest';

    final tabs = _tabsForRole(role);
    final items = tabs
        .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
        .toList();

    final memberships = auth.user?.memberships ?? const <Membership>[];
    final current = auth.currentMembership;

    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Home — ${auth.user?.name ?? ""}'),
          actions: [
            // 새로고침/경로 버튼은 Settings로 이동했으나 남기고 싶으면 여기에 복귀 가능
            IconButton(
              onPressed: () => context.read<AuthState>().signOut(),
              icon: const Icon(Icons.logout),
              tooltip: '로그아웃',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (memberships.isNotEmpty)
                Row(
                  children: [
                    const Text('소속:'),
                    const SizedBox(width: 12),
                    DropdownButton<Membership>(
                      value: (() {
                        // 현재 선택이 목록에 없으면 첫 항목으로 보정
                        if (current != null && memberships.contains(current)) {
                          return current;
                        }
                        return memberships.isNotEmpty
                            ? memberships.first
                            : null;
                      })(),
                      items: memberships
                          .map<DropdownMenuItem<Membership>>((Membership m) {
                        final name = auth.academyName(m.academyId);
                        final label = '$name / ${m.role}';
                        return DropdownMenuItem<Membership>(
                          value: m,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (m) {
                        if (m != null)
                        {
                          context.read<AuthState>().selectMembership(m);
                        }
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Expanded(child: tabs[_index].body),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: items,
        ),
      ),
    );
  }

  List<_TabDef> _tabsForRole(String role) {
    switch (role) {
      case 'owner':
        return [
          _TabDef('대시보드', Icons.dashboard_outlined, const OwnerDashboardPage()),
          _TabDef('출석', Icons.how_to_reg_outlined,
              const AttendancePage()),
          _TabDef('숙제', Icons.assignment_outlined,
              const HomeworkPage(role: 'owner')),
          _TabDef('알림', Icons.notifications_none,
              const NotificationsPage(role: 'owner')),
          _TabDef('설정', Icons.settings_outlined, SettingsPage(role: role)),
        ];
      case 'teacher':
        return [
          _TabDef('대시보드', Icons.dashboard_customize_outlined,
              const TeacherDashboardPage()),
          _TabDef('출석', Icons.fact_check_outlined,
              const AttendancePage()),
          _TabDef('숙제', Icons.edit_note_outlined,
              const HomeworkPage(role: 'teacher')),
          _TabDef('알림', Icons.notifications_none,
              const NotificationsPage(role: 'teacher')),
          _TabDef('설정', Icons.settings_outlined, SettingsPage(role: role)),
        ];
      case 'student':
        return [
          _TabDef('홈', Icons.home_outlined, const StudentHomePage()),
          _TabDef('출석', Icons.emoji_people_outlined,
              const AttendancePage()),
          _TabDef('숙제', Icons.checklist_outlined,
              const HomeworkPage(role: 'student')),
          _TabDef('알림', Icons.notifications_none,
              const NotificationsPage(role: 'student')),
          _TabDef('설정', Icons.settings_outlined, SettingsPage(role: role)),
        ];
      default:
        return [
          _TabDef('홈', Icons.home_outlined, const Center(child: Text('게스트')))
        ];
    }
  }
}

class _TabDef {
  final String label;
  final IconData icon;
  final Widget body;
  _TabDef(this.label, this.icon, this.body);
}
