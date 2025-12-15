// lib/app/home_shell.dart
//
// 역할별 하단 탭 셸 + 라우팅 골격

import 'package:flutter/material.dart';

import '../features/home/dashboard_pages.dart';
import '../features/attendance/attendance_page.dart';
import '../features/homework/homework_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/settings/settings_page.dart';
import '../features/student/student_shell.dart';

class HomeShell extends StatefulWidget {
  final String role; // 'owner' | 'teacher' | 'student'
  const HomeShell({super.key, required this.role});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // 학생인 경우 StudentShell 사용
    if (widget.role == 'student') {
      return const StudentShell();
    }

    final tabs = _tabsForRole(widget.role);

    return Scaffold(
      body: tabs[_index].page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }

  List<_Tab> _tabsForRole(String role) {
    switch (role) {
      case 'owner':
        return [
          const _Tab('대시보드', Icons.dashboard_outlined, OwnerDashboardPage()),
          const _Tab('출석', Icons.how_to_reg_outlined, AttendancePage()),
          const _Tab('숙제', Icons.assignment_outlined, HomeworkPage()),
          _Tab('알림', Icons.notifications_none, NotificationsPage(role: role)),
          _Tab('설정', Icons.settings_outlined, SettingsPage(role: role)),
        ];
      case 'teacher':
        return [
          const _Tab('대시보드', Icons.dashboard_customize_outlined, TeacherDashboardPage()),
          const _Tab('출석', Icons.how_to_reg_outlined, AttendancePage()),
          const _Tab('숙제', Icons.assignment_outlined, HomeworkPage()),
          _Tab('알림', Icons.notifications_none, NotificationsPage(role: role)),
          _Tab('설정', Icons.settings_outlined, SettingsPage(role: role)),
        ];
      default: // 기타 역할 (fallback)
        return [
          const _Tab('대시보드', Icons.dashboard_outlined, OwnerDashboardPage()),
          _Tab('설정', Icons.settings_outlined, SettingsPage(role: role)),
        ];
    }
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final Widget page;
  const _Tab(this.label, this.icon, this.page);
}
