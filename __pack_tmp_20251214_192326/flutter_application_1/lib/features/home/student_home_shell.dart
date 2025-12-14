import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import '../../models/Assignment.dart';
import '../student_assignments/student_assignments_page.dart';
import '../student_assignments/student_assignment_repository.dart';

class StudentHomeShell extends StatefulWidget {
  const StudentHomeShell({super.key});

  @override
  State<StudentHomeShell> createState() => _StudentHomeShellState();
}

class _StudentHomeShellState extends State<StudentHomeShell> {
  int _index = 0;

  String? _studentUsername;
  bool _booting = true;

  final _repo = StudentAssignmentRepository();
  Future<_DashboardVM>? _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    setState(() => _booting = true);

    String? username;
    Future<_DashboardVM>? future;

    try {
      final user = await Amplify.Auth.getCurrentUser();
      username = user.username;
      future = _loadDashboard(username);
    } catch (_) {
      username = null;
      future = Future.value(_DashboardVM.empty());
    }

    if (!mounted) return;

    setState(() {
      _studentUsername = username;
      _dashboardFuture = future;
      _booting = false;
    });
  }

  Future<_DashboardVM> _loadDashboard(String? username) async {
    final u = username;
    if (u == null || u.isEmpty) return _DashboardVM.empty();

    final page = await _repo.listAssignmentsByStudentPaged(
      studentUsername: u,
      limit: 50,
      nextToken: null,
    );

    final items = page.items;

    final total = items.length;
    final done = items.where((a) => _statusOf(a) == 'DONE').length;
    final assigned = items.where((a) => _statusOf(a) == 'ASSIGNED').length;

    final todayDue = items.where((a) {
      final d = _dueAsLocalDate(a);
      if (d == null) return false;
      final now = DateTime.now();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;

    // 최근 과제: createdAt 우선, 없으면 dueDate
    final recent = List<Assignment>.from(items);
    recent.sort((a, b) {
      final ad = _createdAtAsLocalDate(a) ?? _dueAsLocalDate(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = _createdAtAsLocalDate(b) ?? _dueAsLocalDate(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    return _DashboardVM(
      total: total,
      assigned: assigned,
      done: done,
      todayDue: todayDue,
      recent: recent.take(3).toList(),
    );
  }

  void _goToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildDashboard(context),
      const _StudentStudyStub(),
      const StudentAssignmentsPage(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: '과제',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final username = _studentUsername;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '학생 대시보드',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: '새로고침',
                onPressed: () {
                  final u = _studentUsername;
                  setState(() => _dashboardFuture = _loadDashboard(u));
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      username == null ? '학생 계정: (알 수 없음)' : '학생 계정: $username',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_booting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            FutureBuilder<_DashboardVM>(
              future: _dashboardFuture ?? Future.value(_DashboardVM.empty()),
              builder: (context, snap) {
                final vm = snap.data ?? _DashboardVM.empty();
                return Expanded(
                  child: ListView(
                    children: [
                      _SummaryCard(
                        total: vm.total,
                        assigned: vm.assigned,
                        done: vm.done,
                        todayDue: vm.todayDue,
                        onGoAssignments: () => _goToTab(2),
                        onGoStudy: () => _goToTab(1),
                      ),
                      const SizedBox(height: 12),
                      _RecentPreviewCard(
                        recent: vm.recent,
                        onGoAssignments: () => _goToTab(2),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DashboardVM {
  final int total;
  final int assigned;
  final int done;
  final int todayDue;
  final List<Assignment> recent;

  const _DashboardVM({
    required this.total,
    required this.assigned,
    required this.done,
    required this.todayDue,
    required this.recent,
  });

  factory _DashboardVM.empty() => const _DashboardVM(
        total: 0,
        assigned: 0,
        done: 0,
        todayDue: 0,
        recent: <Assignment>[],
      );
}

/// --- Temporal helpers ---
/// Amplify codegen 모델에서 dueDate/createdAt이 TemporalDateTime? / TemporalDate? 일 수 있음.
/// - TemporalDateTime: getDateTimeInUtc() 사용 가능
/// - TemporalDate: getDateTimeInUtc() 없음 → format() (yyyy-MM-dd)로 안전 변환
String _statusOf(Assignment a) {
  final s = (a as dynamic).status; // enum/string 모두 대응
  return s.toString().split('.').last.toUpperCase();
}

DateTime? _dueAsLocalDate(Assignment a) {
  final v = (a as dynamic).dueDate;
  return _temporalToLocalDateTime(v);
}

DateTime? _createdAtAsLocalDate(Assignment a) {
  final v = (a as dynamic).createdAt;
  return _temporalToLocalDateTime(v);
}

DateTime? _temporalToLocalDateTime(Object? v) {
  if (v == null) return null;

  if (v is TemporalDateTime) {
    return v.getDateTimeInUtc().toLocal();
  }

  if (v is TemporalDate) {
    // TemporalDate는 "날짜"만 있으니 로컬 자정으로 만든다.
    final s = v.format(); // yyyy-MM-dd
    final parts = s.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    return null;
  }

  // fallback: parse string
  final s = v.toString();
  try {
    return DateTime.parse(s).toLocal();
  } catch (_) {
    return null;
  }
}

String _formatYmd(DateTime? d) {
  if (d == null) return '-';
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// --- Widgets ---

class _SummaryCard extends StatelessWidget {
  final int total;
  final int assigned;
  final int done;
  final int todayDue;
  final VoidCallback onGoAssignments;
  final VoidCallback onGoStudy;

  const _SummaryCard({
    required this.total,
    required this.assigned,
    required this.done,
    required this.todayDue,
    required this.onGoAssignments,
    required this.onGoStudy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '선생님 과제 요약',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ChipStat(icon: Icons.view_list_outlined, label: '전체 $total'),
                _ChipStat(icon: Icons.pending_actions_outlined, label: '진행중 $assigned'),
                _ChipStat(icon: Icons.check_circle_outline, label: '완료 $done'),
                _ChipStat(icon: Icons.event_outlined, label: '오늘 마감 $todayDue'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onGoAssignments,
                    icon: const Icon(Icons.assignment),
                    label: const Text('과제 탭으로'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onGoStudy,
                    icon: const Icon(Icons.menu_book),
                    label: const Text('학습 탭으로'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentPreviewCard extends StatelessWidget {
  final List<Assignment> recent;
  final VoidCallback onGoAssignments;

  const _RecentPreviewCard({
    required this.recent,
    required this.onGoAssignments,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '최근 과제(미리보기)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: onGoAssignments,
                  child: const Text('전체 보기'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('최근 과제가 없습니다.'),
              )
            else
              Column(
                children: recent.map((a) {
                  // 모델이 non-nullable일 수도 있어서 null 체크는 최소화
                  final rawTitle = (a as dynamic).title?.toString() ?? '';
                  final title = rawTitle.trim().isEmpty ? '(제목 없음)' : rawTitle.trim();

                  final teacher = ((a as dynamic).teacherUsername?.toString() ?? '-');
                  final due = _formatYmd(_dueAsLocalDate(a));
                  final status = _statusOf(a);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.assignment_outlined),
                        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          'teacher: $teacher  ·  due: $due  ·  $status',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChipStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ChipStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }
}

class _StudentStudyStub extends StatelessWidget {
  const _StudentStudyStub();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '학습 탭(예정)\n\n여기에 학습/진도/교재/복습 등을 붙입니다.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
