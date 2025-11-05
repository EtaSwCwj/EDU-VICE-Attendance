// lib/app/home_shell.dart
//
// 역할별 하단 탭 재구성
// - owner/teacher: 5탭(대시보드/출석/숙제/알림/설정) 유지
// - student: 3탭(홈/학습/설정)로 단순화, 알림·출첵은 홈에 통합(추후 홈에서 CTA/요약 처리)
//
// 주의:
//  - HomeworkPage/NotificationsPage/SettingsPage는 role 파라미터 필요 → 전달
//  - 학생은 NotificationsPage 탭을 제거(알림은 홈에서 요약으로 처리)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/services/auth_state.dart';

// 페이지들
import '../features/home/dashboard_pages.dart'; // OwnerDashboardPage / TeacherDashboardPage / StudentHomePage
import '../features/attendance/attendance_page.dart';
import '../features/homework/homework_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/settings/settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  String? _lastRole; // 역할 변경 시 인덱스 리셋

  @override
  Widget build(BuildContext context) {
    final role = _readRole(context);

    if (_lastRole != role) {
      _lastRole = role;
      _selectedIndex = 0;
    }

    final tabs = _tabsForRole(role);

    final destinations = tabs
        .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
        .toList();
    final pages = tabs.map((t) => t.child).toList();

    final safeIndex = _selectedIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        destinations: destinations,
        onDestinationSelected: (i) {
          if (i != _selectedIndex) setState(() => _selectedIndex = i);
        },
      ),
    );
  }
}

// 런타임 안전 역할 읽기(필드명이 달라도 컴파일 에러 없이 동작)
String _readRole(BuildContext context) {
  final auth = context.read<AuthState?>();
  final dynamic d = auth;
  if (d == null) return 'owner';

  try {
    final v = d.role;
    if (v is String && v.isNotEmpty) return v;
  } catch (_) {}

  try {
    final v = d.currentRole;
    if (v is String && v.isNotEmpty) return v;
  } catch (_) {}

  try {
    final v = d.activeRole;
    if (v is String && v.isNotEmpty) return v;
  } catch (_) {}

  try {
    final m = d.currentMembership;
    final v = (m != null) ? m.role : null;
    if (v is String && v.isNotEmpty) return v;
  } catch (_) {}

  return 'owner';
}

class _TabDef {
  final String label;
  final IconData icon;
  final Widget child;
  const _TabDef(this.label, this.icon, this.child);
}

// 역할별 탭 세트
List<_TabDef> _tabsForRole(String role) {
  switch (role) {
    case 'owner':
      return <_TabDef>[
        _TabDef('대시보드', Icons.dashboard_customize_outlined, const OwnerDashboardPage()),
        _TabDef('출석',     Icons.how_to_reg_outlined,          const AttendancePage()),
        _TabDef('숙제',     Icons.assignment_outlined,          HomeworkPage(role: 'owner')),
        _TabDef('알림',     Icons.notifications_none,           NotificationsPage(role: 'owner')),
        _TabDef('설정',     Icons.settings_outlined,            SettingsPage(role: 'owner')),
      ];

    case 'teacher':
      return <_TabDef>[
        _TabDef('대시보드', Icons.dashboard_customize_outlined, const TeacherDashboardPage()),
        _TabDef('출석',     Icons.how_to_reg_outlined,          const AttendancePage()),
        _TabDef('숙제',     Icons.assignment_outlined,          HomeworkPage(role: 'teacher')),
        _TabDef('알림',     Icons.notifications_none,           NotificationsPage(role: 'teacher')),
        _TabDef('설정',     Icons.settings_outlined,            SettingsPage(role: 'teacher')),
      ];

    case 'student':
      // 학생은 3탭: 홈/학습/설정 (알림·출첵은 홈에서 요약/CTA로 처리)
      return <_TabDef>[
        _TabDef('홈',   Icons.home_outlined,      const StudentHomePage()),
        _TabDef('학습', Icons.menu_book_outlined, HomeworkPage(role: 'student')),
        _TabDef('설정', Icons.settings_outlined,  SettingsPage(role: 'student')),
      ];

    default:
      // 안전 기본값(오너 세트)
      return <_TabDef>[
        _TabDef('대시보드', Icons.dashboard_customize_outlined, const OwnerDashboardPage()),
        _TabDef('출석',     Icons.how_to_reg_outlined,          const AttendancePage()),
        _TabDef('숙제',     Icons.assignment_outlined,          HomeworkPage(role: role)),
        _TabDef('알림',     Icons.notifications_none,           NotificationsPage(role: role)),
        _TabDef('설정',     Icons.settings_outlined,            SettingsPage(role: role)),
      ];
  }
}
