import 'dart:async';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import '../../models/Assignment.dart';
import '../../models/AssignmentStatus.dart';
import 'student_assignment_detail_page.dart';
import 'student_assignment_repository.dart';

enum _StatusFilter { all, assigned, done }
enum _SortMode { newest, oldest }

class StudentAssignmentsPage extends StatefulWidget {
  const StudentAssignmentsPage({super.key});

  @override
  State<StudentAssignmentsPage> createState() => _StudentAssignmentsPageState();
}

class _StudentAssignmentsPageState extends State<StudentAssignmentsPage> {
  final _repo = StudentAssignmentRepository();

  bool _booting = true;
  bool _refreshing = false;
  bool _loadingMore = false;

  String? _studentUsername;
  String? _nextToken;
  bool _hasMore = true;

  final List<Assignment> _items = [];
  final ScrollController _scroll = ScrollController();

  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  _StatusFilter _statusFilter = _StatusFilter.all;
  _SortMode _sortMode = _SortMode.newest;

  @override
  void initState() {
    super.initState();

    _scroll.addListener(() {
      if (!_hasMore || _loadingMore || _refreshing) return;
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
        unawaited(_loadMore());
      }
    });

    unawaited(_boot());
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    final m = ScaffoldMessenger.of(context);
    m.clearSnackBars();
    m.showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _boot() async {
    setState(() => _booting = true);
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final username = user.username;

      if (!mounted) return;
      setState(() => _studentUsername = username);

      await _refresh();

      if (!mounted) return;
      setState(() => _booting = false);
    } catch (e, st) {
      safePrint('StudentAssignments boot failed: $e\n$st');
      if (!mounted) return;
      setState(() => _booting = false);
      _snack('로그인 세션 확인 필요: $e');
    }
  }

  void _hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _refresh() async {
    final s = _studentUsername;
    if (s == null || s.isEmpty) return;

    setState(() {
      _refreshing = true;
      _nextToken = null;
      _hasMore = true;
    });

    try {
      final page = await _repo.listAssignmentsByStudentPaged(
        studentUsername: s,
        limit: 25,
        nextToken: null,
      );

      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _nextToken = page.nextToken;
        _hasMore = page.nextToken != null && page.nextToken!.isNotEmpty;
        _refreshing = false;
      });
    } catch (e, st) {
      safePrint('StudentAssignments refresh failed: $e\n$st');
      if (!mounted) return;
      setState(() => _refreshing = false);
      _snack('조회 실패: $e');
    }
  }

  Future<void> _loadMore() async {
    final s = _studentUsername;
    if (s == null || s.isEmpty) return;
    if (!_hasMore) return;

    final token = _nextToken;
    if (token == null || token.isEmpty) {
      setState(() => _hasMore = false);
      return;
    }

    setState(() => _loadingMore = true);

    try {
      final page = await _repo.listAssignmentsByStudentPaged(
        studentUsername: s,
        limit: 25,
        nextToken: token,
      );

      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _nextToken = page.nextToken;
        _hasMore = page.nextToken != null && page.nextToken!.isNotEmpty;
        _loadingMore = false;
      });
    } catch (e, st) {
      safePrint('StudentAssignments loadMore failed: $e\n$st');
      if (!mounted) return;
      setState(() => _loadingMore = false);
      _snack('추가 로드 실패: $e');
    }
  }

  Future<void> _markDone(Assignment a) async {
    try {
      await _repo.updateAssignmentStatus(id: a.id, status: AssignmentStatus.DONE);
      if (!mounted) return;
      _snack('DONE 처리 완료');
      await _refresh();
    } catch (e, st) {
      safePrint('markDone failed: $e\n$st');
      if (!mounted) return;
      _snack('상태 변경 실패: $e');
    }
  }

  Future<void> _markAssigned(Assignment a) async {
    try {
      await _repo.updateAssignmentStatus(id: a.id, status: AssignmentStatus.ASSIGNED);
      if (!mounted) return;
      _snack('ASSIGNED로 되돌림');
      await _refresh();
    } catch (e, st) {
      safePrint('markAssigned failed: $e\n$st');
      if (!mounted) return;
      _snack('상태 변경 실패: $e');
    }
  }

  // TemporalDateTime/TemporalDate 대응: dueDate -> local ymd 문자열
  DateTime? _temporalToLocalDateTime(Object? v) {
    if (v == null) return null;

    if (v is TemporalDateTime) {
      return v.getDateTimeInUtc().toLocal();
    }
    if (v is TemporalDate) {
      final s = v.format();
      final parts = s.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) return DateTime(y, m, d);
      }
      return null;
    }

    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  DateTime? _dueLocal(Assignment a) => _temporalToLocalDateTime((a as dynamic).dueDate);

  String _ymd(DateTime? local) {
    if (local == null) return '-';
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool _isSameLocalDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Assignment> _applyView(List<Assignment> src) {
    Iterable<Assignment> it = src;

    switch (_statusFilter) {
      case _StatusFilter.all:
        break;
      case _StatusFilter.assigned:
        it = it.where((a) => a.status == AssignmentStatus.ASSIGNED);
        break;
      case _StatusFilter.done:
        it = it.where((a) => a.status == AssignmentStatus.DONE);
        break;
    }

    final q = _searchText.trim().toLowerCase();
    if (q.isNotEmpty) {
      it = it.where((a) {
        final t = a.title.toLowerCase();
        final teacher = a.teacherUsername.toLowerCase();
        return t.contains(q) || teacher.contains(q);
      });
    }

    final list = it.toList();

    int cmpDate(DateTime? a, DateTime? b) {
      final aa = a?.millisecondsSinceEpoch ?? 0;
      final bb = b?.millisecondsSinceEpoch ?? 0;
      return aa.compareTo(bb);
    }

    final now = DateTime.now();

    list.sort((a, b) {
      final aDone = a.status == AssignmentStatus.DONE;
      final bDone = b.status == AssignmentStatus.DONE;
      if (aDone != bDone) return aDone ? 1 : -1;

      final aDue = _dueLocal(a);
      final bDue = _dueLocal(b);

      final aToday = aDue != null && _isSameLocalDay(aDue, now);
      final bToday = bDue != null && _isSameLocalDay(bDue, now);
      if (aToday != bToday) return aToday ? -1 : 1;

      if (aDue != null && bDue != null) {
        final c = aDue.compareTo(bDue);
        if (c != 0) return c;
      } else if (aDue != null && bDue == null) {
        return -1;
      } else if (aDue == null && bDue != null) {
        return 1;
      }

      final aCreated = _temporalToLocalDateTime((a as dynamic).createdAt);
      final bCreated = _temporalToLocalDateTime((b as dynamic).createdAt);
      final c = cmpDate(aCreated, bCreated);
      return _sortMode == _SortMode.newest ? -c : c;
    });

    return list;
  }

  Future<void> _openDetail(Assignment a) async {
    _hideKeyboard();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StudentAssignmentDetailPage(assignment: a),
      ),
    );

    // ✅ 상세에서 상태 바꾸면 pop(true)로 돌아오게 설계
    if (changed == true) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _studentUsername == null ? '선생님 과제' : '선생님 과제 (내 계정: $_studentUsername)';
    final view = _applyView(_items);

    final total = _items.length;
    final assignedCnt = _items.where((a) => a.status == AssignmentStatus.ASSIGNED).length;
    final doneCnt = _items.where((a) => a.status == AssignmentStatus.DONE).length;

    final now = DateTime.now();
    final todayDueCnt = _items.where((a) {
      final d = _dueLocal(a);
      return d != null && a.status == AssignmentStatus.ASSIGNED && _isSameLocalDay(d, now);
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _refreshing ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            child: (_booting || _refreshing)
                ? const LinearProgressIndicator(minHeight: 3)
                : const SizedBox(height: 3),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('오늘 할 일 요약', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _pill(context, Icons.inbox, '전체 $total'),
                        _pill(context, Icons.pending_actions, '진행중 $assignedCnt'),
                        _pill(context, Icons.check_circle, '완료 $doneCnt'),
                        _pill(context, Icons.today, '오늘 마감 $todayDueCnt'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: '검색: title / teacherUsername',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _hideKeyboard(),
                  onChanged: (v) => setState(() => _searchText = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<_StatusFilter>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: _StatusFilter.all, child: Text('ALL')),
                          DropdownMenuItem(value: _StatusFilter.assigned, child: Text('ASSIGNED')),
                          DropdownMenuItem(value: _StatusFilter.done, child: Text('DONE')),
                        ],
                        onChanged: (v) {
                          _hideKeyboard();
                          if (v == null) return;
                          setState(() => _statusFilter = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<_SortMode>(
                        initialValue: _sortMode,
                        decoration: const InputDecoration(
                          labelText: 'Sort(보조)',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: _SortMode.newest, child: Text('Newest')),
                          DropdownMenuItem(value: _SortMode.oldest, child: Text('Oldest')),
                        ],
                        onChanged: (v) {
                          _hideKeyboard();
                          if (v == null) return;
                          setState(() => _sortMode = v);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _booting
                  ? const Center(child: CircularProgressIndicator())
                  : view.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('표시할 과제가 없습니다.')),
                            SizedBox(height: 8),
                            Center(child: Text('필터/검색 조건을 확인해보세요.')),
                          ],
                        )
                      : ListView.separated(
                          controller: _scroll,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          itemCount: view.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            if (i == view.length) {
                              if (_loadingMore) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              if (!_hasMore) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: Text('더 이상 없음')),
                                );
                              }
                              return const SizedBox(height: 16);
                            }

                            final a = view[i];
                            final dueLocal = _dueLocal(a);
                            final dueText = _ymd(dueLocal);
                            final isDone = a.status == AssignmentStatus.DONE;
                            final isToday = dueLocal != null && _isSameLocalDay(dueLocal, DateTime.now());

                            return InkWell(
                              onTap: () => _openDetail(a),
                              borderRadius: BorderRadius.circular(12),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              a.title,
                                              style: Theme.of(context).textTheme.titleMedium,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isToday && !isDone) ...[
                                            const SizedBox(width: 8),
                                            _tag(context, 'TODAY'),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          _chip(context, Icons.person, 'teacher: ${a.teacherUsername}'),
                                          _chip(context, Icons.event, 'due: $dueText'),
                                          _chip(context, Icons.flag, 'status: ${a.status.name}'),
                                        ],
                                      ),
                                      if ((a.description ?? '').trim().isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Text(a.description!, style: Theme.of(context).textTheme.bodyMedium),
                                      ],
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: FilledButton(
                                              onPressed: isDone ? null : () => _markDone(a),
                                              child: const Text('DONE'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: isDone ? () => _markAssigned(a) : null,
                                              child: const Text('UNDO'),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '탭하면 상세로 이동',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _tag(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
