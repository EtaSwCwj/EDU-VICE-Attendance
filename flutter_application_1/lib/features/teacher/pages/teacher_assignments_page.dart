import 'dart:async';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/ModelProvider.dart';
import '../data/assignment_repository.dart';
import '../widgets/assignment_action_sheet.dart';

enum _StatusFilter { all, assigned, done }
enum _SortMode { newest, dueDate, title }

class TeacherAssignmentsPage extends StatefulWidget {
  const TeacherAssignmentsPage({super.key});

  @override
  State<TeacherAssignmentsPage> createState() => _TeacherAssignmentsPageState();
}

class _TeacherAssignmentsPageState extends State<TeacherAssignmentsPage> {
  final _repo = AssignmentRepository();

  bool _booting = true;
  bool _creating = false;

  String? _teacherUsername;

  // ✅ Create 패널 접기/펼치기
  bool _createExpanded = false;

  // Search/Filter/Sort
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchText = '';
  _StatusFilter _statusFilter = _StatusFilter.all;
  _SortMode _sortMode = _SortMode.newest;

  // Create inputs
  final TextEditingController _studentUsernameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Pagination (My)
  final ScrollController _myScroll = ScrollController();
  bool _myLoading = false;
  bool _myRefreshing = false;
  bool _myHasMore = true;
  String? _myNextToken;
  final List<Assignment> _myItems = [];

  // Pagination (OwnerOnly)
  final ScrollController _ownerScroll = ScrollController();
  bool _ownerLoading = false;
  bool _ownerRefreshing = false;
  bool _ownerHasMore = true;
  String? _ownerNextToken;
  final List<Assignment> _ownerItems = [];

  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();

    _myScroll.addListener(() {
      if (_tabIndex != 0) return;
      if (!_myHasMore || _myLoading || _myRefreshing) return;
      if (_myScroll.position.pixels >= _myScroll.position.maxScrollExtent - 240) {
        unawaited(_loadMoreMy());
      }
    });

    _ownerScroll.addListener(() {
      if (_tabIndex != 1) return;
      if (!_ownerHasMore || _ownerLoading || _ownerRefreshing) return;
      if (_ownerScroll.position.pixels >= _ownerScroll.position.maxScrollExtent - 240) {
        unawaited(_loadMoreOwner());
      }
    });

    _searchController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 220), () {
        final v = _searchController.text.trim();
        if (v == _searchText) return;
        setState(() => _searchText = v);
      });
    });

    unawaited(_boot());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();

    _studentUsernameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();

    _myScroll.dispose();
    _ownerScroll.dispose();

    super.dispose();
  }

  Future<void> _boot() async {
    setState(() => _booting = true);

    try {
      final user = await Amplify.Auth.getCurrentUser();
      final username = user.username;

      if (!mounted) return;
      setState(() {
        _teacherUsername = username;
      });

      await Future.wait([
        _refreshMy(),
        _refreshOwner(),
      ]);

      if (!mounted) return;
      setState(() => _booting = false);
    } catch (e, st) {
      safePrint('TeacherAssignmentsPage boot failed: $e\n$st');
      if (!mounted) return;
      setState(() => _booting = false);
      _showError('로그인 세션 확인 필요: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // --------- View transforms (search/filter/sort) ---------
  bool _matchesSearch(Assignment a) {
    if (_searchText.isEmpty) return true;
    final q = _searchText.toLowerCase();

    final title = a.title.toLowerCase();
    final student = a.studentUsername.toLowerCase();
    final desc = (a.description ?? '').toLowerCase();

    return title.contains(q) || student.contains(q) || desc.contains(q);
  }

  bool _matchesStatus(Assignment a) {
    switch (_statusFilter) {
      case _StatusFilter.all:
        return true;
      case _StatusFilter.assigned:
        return a.status == AssignmentStatus.ASSIGNED;
      case _StatusFilter.done:
        return a.status == AssignmentStatus.DONE;
    }
  }

  int _compareSort(Assignment a, Assignment b) {
    switch (_sortMode) {
      case _SortMode.newest:
        final at = a.createdAt?.getDateTimeInUtc();
        final bt = b.createdAt?.getDateTimeInUtc();
        if (at != null && bt != null) return bt.compareTo(at);
        if (at != null) return -1;
        if (bt != null) return 1;
        return 0;

      case _SortMode.dueDate:
        final ad = a.dueDate?.getDateTimeInUtc();
        final bd = b.dueDate?.getDateTimeInUtc();
        if (ad != null && bd != null) return ad.compareTo(bd);
        if (ad != null) return -1;
        if (bd != null) return 1;
        return 0;

      case _SortMode.title:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    }
  }

  List<Assignment> _applyViewTransform(List<Assignment> src) {
    final out = src.where(_matchesSearch).where(_matchesStatus).toList();
    out.sort(_compareSort);
    return out;
  }

  // --------- Pagination loaders ---------
  Future<void> _refreshMy() async {
    final username = _teacherUsername;
    if (username == null || username.isEmpty) return;

    setState(() {
      _myRefreshing = true;
      _myHasMore = true;
      _myNextToken = null;
      _myItems.clear();
    });

    try {
      final page = await _repo.listAssignmentsByTeacherPaged(
        teacherUsername: username,
        limit: 25,
        nextToken: null,
      );

      if (!mounted) return;
      setState(() {
        _myItems.addAll(page.items);
        _myNextToken = page.nextToken;
        _myHasMore = page.nextToken != null && page.nextToken!.isNotEmpty;
        _myRefreshing = false;
      });
    } catch (e, st) {
      safePrint('refreshMy failed: $e\n$st');
      if (!mounted) return;
      setState(() => _myRefreshing = false);
      _showError('내 과제 새로고침 실패: $e');
    }
  }

  Future<void> _loadMoreMy() async {
    final username = _teacherUsername;
    if (username == null || username.isEmpty) return;
    if (!_myHasMore) return;

    final token = _myNextToken;
    if (token == null || token.isEmpty) {
      setState(() => _myHasMore = false);
      return;
    }

    setState(() => _myLoading = true);

    try {
      final page = await _repo.listAssignmentsByTeacherPaged(
        teacherUsername: username,
        limit: 25,
        nextToken: token,
      );

      if (!mounted) return;
      setState(() {
        _myItems.addAll(page.items);
        _myNextToken = page.nextToken;
        _myHasMore = page.nextToken != null && page.nextToken!.isNotEmpty;
        _myLoading = false;
      });
    } catch (e, st) {
      safePrint('loadMoreMy failed: $e\n$st');
      if (!mounted) return;
      setState(() => _myLoading = false);
      _showError('추가 로드 실패: $e');
    }
  }

  Future<void> _refreshOwner() async {
    setState(() {
      _ownerRefreshing = true;
      _ownerHasMore = true;
      _ownerNextToken = null;
      _ownerItems.clear();
    });

    try {
      final page = await _repo.listAssignmentsOwnerOnlyPaged(
        limit: 25,
        nextToken: null,
      );

      if (!mounted) return;
      setState(() {
        _ownerItems.addAll(page.items);
        _ownerNextToken = page.nextToken;
        _ownerHasMore = page.nextToken != null && page.nextToken!.isNotEmpty;
        _ownerRefreshing = false;
      });
    } catch (e, st) {
      safePrint('refreshOwner failed: $e\n$st');
      if (!mounted) return;
      setState(() => _ownerRefreshing = false);
      _showError('Owner 목록 새로고침 실패: $e');
    }
  }

  Future<void> _loadMoreOwner() async {
    if (!_ownerHasMore) return;

    final token = _ownerNextToken;
    if (token == null || token.isEmpty) {
      setState(() => _ownerHasMore = false);
      return;
    }

    setState(() => _ownerLoading = true);

    try {
      final page = await _repo.listAssignmentsOwnerOnlyPaged(
        limit: 25,
        nextToken: token,
      );

      if (!mounted) return;
      setState(() {
        _ownerItems.addAll(page.items);
        _ownerNextToken = page.nextToken;
        _ownerHasMore = page.nextToken != null && page.nextToken!.isNotEmpty;
        _ownerLoading = false;
      });
    } catch (e, st) {
      safePrint('loadMoreOwner failed: $e\n$st');
      if (!mounted) return;
      setState(() => _ownerLoading = false);
      _showError('추가 로드 실패: $e');
    }
  }

  // --------- Actions ---------
  Future<void> _createAssignment() async {
    final teacherUsername = _teacherUsername;
    if (teacherUsername == null || teacherUsername.isEmpty) {
      _showError('교사 계정 상태 확인 필요');
      return;
    }

    final student = _studentUsernameController.text.trim();
    final title = _titleController.text.trim();
    final desc = _descriptionController.text.trim();

    if (student.isEmpty || title.isEmpty) {
      _showError('studentUsername / title 필수');
      return;
    }

    setState(() => _creating = true);

    try {
      await _repo.createAssignment(
        teacherUsername: teacherUsername,
        studentUsername: student,
        title: title,
        description: desc.isEmpty ? null : desc,
      );

      if (!mounted) return;

      _studentUsernameController.clear();
      _titleController.clear();
      _descriptionController.clear();

      // 생성 성공 후: 패널 닫기 + 리스트 갱신
      setState(() => _createExpanded = false);

      if (_tabIndex == 0) {
        await _refreshMy();
      } else {
        await _refreshOwner();
      }
    } catch (e, st) {
      safePrint('createAssignment failed: $e\n$st');
      if (!mounted) return;
      _showError('생성 실패: $e');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _openActionSheet(Assignment a) async {
    await showAssignmentActionSheet(
      context: context,
      assignment: a,
      onChanged: () {
        if (!mounted) return;
        if (_tabIndex == 0) {
          unawaited(_refreshMy());
        } else {
          unawaited(_refreshOwner());
        }
      },
      onDeleted: () {
        if (!mounted) return;
        if (_tabIndex == 0) {
          unawaited(_refreshMy());
        } else {
          unawaited(_refreshOwner());
        }
      },
    );
  }

  Future<void> _deleteDirect(Assignment a) async {
    final id = a.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제'),
        content: Text('정말 삭제할까?\n\n$id'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );

    if (!mounted) return;
    if (ok != true) return;

    try {
      await _repo.deleteAssignment(id);
      if (!mounted) return;
      if (_tabIndex == 0) {
        await _refreshMy();
      } else {
        await _refreshOwner();
      }
    } catch (e, st) {
      safePrint('delete failed: $e\n$st');
      if (!mounted) return;
      _showError('삭제 실패: $e');
    }
  }

  // --------- UI ---------
  @override
  Widget build(BuildContext context) {
    final myView = _applyViewTransform(_myItems);
    final ownerView = _applyViewTransform(_ownerItems);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher · Assignments'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('내 과제')),
                      ButtonSegment(value: 1, label: Text('OwnerOnly')),
                    ],
                    selected: {_tabIndex},
                    onSelectionChanged: (s) => setState(() => _tabIndex = s.first),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _booting
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCreateCollapsible(),
                _buildToolbarCompact(),
                const Divider(height: 1),
                Expanded(
                  child: IndexedStack(
                    index: _tabIndex,
                    children: [
                      _buildListCompact(
                        controller: _myScroll,
                        refreshing: _myRefreshing,
                        loadingMore: _myLoading,
                        hasMore: _myHasMore,
                        items: myView,
                        onRefresh: _refreshMy,
                        emptyText: '내 과제가 없습니다.',
                      ),
                      _buildListCompact(
                        controller: _ownerScroll,
                        refreshing: _ownerRefreshing,
                        loadingMore: _ownerLoading,
                        hasMore: _ownerHasMore,
                        items: ownerView,
                        onRefresh: _refreshOwner,
                        emptyText: 'OwnerOnly 항목이 없습니다.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ✅ Create 패널: 기본 접힘 + 헤더만 작게
  Widget _buildCreateCollapsible() {
    final teacher = _teacherUsername ?? '-';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _createExpanded = !_createExpanded),
                child: Row(
                  children: [
                    Icon(_createExpanded ? Icons.expand_less : Icons.expand_more),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Create (teacher=$teacher)',
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    FilledButton(
                      onPressed: _creating ? null : _createAssignment,
                      child: _creating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create'),
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 180),
                crossFadeState:
                    _createExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    children: [
                      TextField(
                        controller: _studentUsernameController,
                        decoration: const InputDecoration(
                          labelText: 'studentUsername',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'description (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 툴바: 공간 줄이기(한 번에 보기 좋게)
  Widget _buildToolbarCompact() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: '검색: title / studentUsername / description',
              border: const OutlineInputBorder(),
              suffixIcon: _searchText.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchText = '');
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownMenu<_StatusFilter>(
                  label: const Text('Status'),
                  initialSelection: _statusFilter,
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: _StatusFilter.all, label: 'ALL'),
                    DropdownMenuEntry(value: _StatusFilter.assigned, label: 'ASSIGNED'),
                    DropdownMenuEntry(value: _StatusFilter.done, label: 'DONE'),
                  ],
                  onSelected: (v) => setState(() => _statusFilter = v ?? _StatusFilter.all),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownMenu<_SortMode>(
                  label: const Text('Sort'),
                  initialSelection: _sortMode,
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: _SortMode.newest, label: 'Newest'),
                    DropdownMenuEntry(value: _SortMode.dueDate, label: 'Due date'),
                    DropdownMenuEntry(value: _SortMode.title, label: 'Title'),
                  ],
                  onSelected: (v) => setState(() => _sortMode = v ?? _SortMode.newest),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ 리스트: 제목/상태 중심으로 축약 + empty 표시
  Widget _buildListCompact({
    required ScrollController controller,
    required bool refreshing,
    required bool loadingMore,
    required bool hasMore,
    required List<Assignment> items,
    required Future<void> Function() onRefresh,
    required String emptyText,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty && !refreshing
          ? ListView(
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Text(
                    emptyText,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            )
          : ListView.separated(
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i == items.length) {
                  if (refreshing || loadingMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!hasMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: Text('끝')),
                    );
                  }
                  return const SizedBox(height: 16);
                }

                final a = items[i];
                return _AssignmentTile(
                  a: a,
                  onActions: () => _openActionSheet(a),
                  onCopyId: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(ClipboardData(text: a.id));
                    if (!mounted) return;
                    messenger.showSnackBar(const SnackBar(content: Text('ID copied')));
                  },
                  onDelete: () => _deleteDirect(a),
                );
              },
            ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  final Assignment a;
  final VoidCallback onActions;
  final Future<void> Function() onCopyId;
  final VoidCallback onDelete;

  const _AssignmentTile({
    required this.a,
    required this.onActions,
    required this.onCopyId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = a.status.name;
    final due = a.dueDate?.getDateTimeInUtc();
    final dueText = due == null ? '-' : due.toLocal().toString().split('.').first;

    return Card(
      child: ListTile(
        title: Text(
          a.title,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaChip(icon: Icons.person, text: a.studentUsername),
              _MetaChip(icon: Icons.flag, text: statusText),
              _MetaChip(icon: Icons.event, text: dueText),
              if ((a.description ?? '').trim().isNotEmpty)
                const _MetaChip(icon: Icons.notes, text: 'desc'),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (k) async {
            if (k == 'sheet') {
              onActions();
              return;
            }
            if (k == 'copy') {
              await onCopyId();
              return;
            }
            if (k == 'delete') {
              onDelete();
              return;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'sheet', child: Text('Actions')),
            PopupMenuItem(value: 'copy', child: Text('Copy ID')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
