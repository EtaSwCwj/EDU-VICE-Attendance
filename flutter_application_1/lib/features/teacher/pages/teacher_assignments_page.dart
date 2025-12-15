import 'dart:async';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../models/Assignment.dart';
import '../../../models/AssignmentStatus.dart';
import '../../../shared/services/auth_state.dart';
import '../data/assignment_repository.dart';
import '../widgets/assignment_action_sheet.dart';
import 'teacher_assignment_local_view_page.dart';
import '../../settings/settings_page.dart';

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

  bool _createExpanded = false;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchText = '';
  _StatusFilter _statusFilter = _StatusFilter.all;
  _SortMode _sortMode = _SortMode.newest;

  final TextEditingController _studentUsernameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final FocusNode _studentFocus = FocusNode();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();

  // ✅ due date (local date only UI)
  DateTime? _dueDateLocal; // 날짜만 의미있게 사용 (시간은 23:59로 고정 저장)

  final ScrollController _myScroll = ScrollController();
  bool _myLoading = false;
  bool _myRefreshing = false;
  bool _myHasMore = true;
  String? _myNextToken;
  final List<Assignment> _myItems = [];
  String? _myLastError;

  final ScrollController _ownerScroll = ScrollController();
  bool _ownerLoading = false;
  bool _ownerRefreshing = false;
  bool _ownerHasMore = true;
  String? _ownerNextToken;
  final List<Assignment> _ownerItems = [];
  String? _ownerLastError;

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

    _studentFocus.dispose();
    _titleFocus.dispose();
    _descFocus.dispose();

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
      setState(() => _teacherUsername = username);

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

  void _hideKeyboard() {
    final scope = FocusScope.of(context);
    if (scope.hasFocus) scope.unfocus();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) => _showSnack(message);

  bool get _isHeaderBusy {
    if (_creating) return true;
    if (_tabIndex == 0) return _myRefreshing;
    return _ownerRefreshing;
  }

  ScrollController get _activeScroll => _tabIndex == 0 ? _myScroll : _ownerScroll;

  Future<void> _scrollToTop() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    if (!_activeScroll.hasClients) return;

    await _activeScroll.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  // ---------------- View transforms ----------------
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
        if (ad != null && bd != null) return ad.compareTo(bd); // 가까운 due 먼저
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

  // ---------------- Error normalization ----------------
  String _prettyError(Object e) {
    final msg = e.toString();

    if (msg.contains('Not Authorized') || msg.contains('Unauthorized') || msg.contains('401')) {
      return '권한이 없습니다. (Cognito 세션/그룹/권한 정책 확인 필요)';
    }
    if (msg.contains('Validation') || msg.contains('FieldUndefined')) {
      return '스키마/쿼리 불일치가 감지되었습니다. (백엔드 스키마와 앱 codegen 동기화 확인)';
    }
    if (msg.contains('Network') || msg.contains('Socket') || msg.contains('timed out')) {
      return '네트워크 문제로 요청이 실패했습니다. (연결 상태 확인)';
    }
    return '요청 실패: $msg';
  }

  // ---------------- Pagination loaders ----------------
  Future<void> _refreshMy() async {
    final username = _teacherUsername;
    if (username == null || username.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _myRefreshing = true;
      _myHasMore = true;
      _myNextToken = null;
      _myLastError = null;
    });

    try {
      final page = await _repo.listAssignmentsByTeacherPaged(
        teacherUsername: username,
        limit: 25,
        nextToken: null,
      );

      if (!mounted) return;
      setState(() {
        _myItems
          ..clear()
          ..addAll(page.items);
        _myNextToken = page.nextToken;
        _myHasMore = page.nextToken != null && page.nextToken!.isNotEmpty;
        _myRefreshing = false;
      });
    } catch (e, st) {
      safePrint('refreshMy failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _myRefreshing = false;
        _myLastError = _prettyError(e);
      });
      _showError('내 과제 새로고침 실패');
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
      setState(() {
        _myLoading = false;
        _myLastError = _prettyError(e);
      });
      _showError('추가 로드 실패');
    }
  }

  Future<void> _refreshOwner() async {
    if (!mounted) return;
    setState(() {
      _ownerRefreshing = true;
      _ownerHasMore = true;
      _ownerNextToken = null;
      _ownerLastError = null;
    });

    try {
      final page = await _repo.listAssignmentsOwnerOnlyPaged(
        limit: 25,
        nextToken: null,
      );

      if (!mounted) return;
      setState(() {
        _ownerItems
          ..clear()
          ..addAll(page.items);
        _ownerNextToken = page.nextToken;
        _ownerHasMore = page.nextToken != null && page.nextToken!.isNotEmpty;
        _ownerRefreshing = false;
      });
    } catch (e, st) {
      safePrint('refreshOwner failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _ownerRefreshing = false;
        _ownerLastError = _prettyError(e);
      });
      _showError('Owner 목록 새로고침 실패');
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
      setState(() {
        _ownerLoading = false;
        _ownerLastError = _prettyError(e);
      });
      _showError('추가 로드 실패');
    }
  }

  // ---------------- dueDate helper ----------------
  String? _buildDueDateUtcIsoFromLocalDate(DateTime? localDate) {
    if (localDate == null) return null;

    final localEndOfDay = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      23,
      59,
      0,
    );

    return localEndOfDay.toUtc().toIso8601String();
  }

  String _formatDateYmd(DateTime? dtLocal) {
    if (dtLocal == null) return '-';
    final y = dtLocal.year.toString().padLeft(4, '0');
    final m = dtLocal.month.toString().padLeft(2, '0');
    final d = dtLocal.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDueDate() async {
    _hideKeyboard();

    final now = DateTime.now();
    final initial = _dueDateLocal ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 3, 12, 31),
    );

    if (!mounted) return;
    if (picked == null) return;

    setState(() => _dueDateLocal = DateTime(picked.year, picked.month, picked.day));
  }

  // ---------------- Actions ----------------
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

    final dueUtcIso = _buildDueDateUtcIsoFromLocalDate(_dueDateLocal);

    _hideKeyboard();
    setState(() => _creating = true);

    try {
      await _repo.createAssignment(
        teacherUsername: teacherUsername,
        studentUsername: student,
        title: title,
        description: desc.isEmpty ? null : desc,
        dueDateUtcIso: dueUtcIso,
      );

      if (!mounted) return;

      _studentUsernameController.clear();
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _dueDateLocal = null;
        _createExpanded = false;
      });

      if (_tabIndex == 0) {
        await _refreshMy();
      } else {
        await _refreshOwner();
      }

      if (!mounted) return;
      _showSnack('과제 생성 완료');
      await _scrollToTop();
    } catch (e, st) {
      safePrint('createAssignment failed: $e\n$st');
      if (!mounted) return;
      _showError(_prettyError(e));
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

    _hideKeyboard();

    try {
      await _repo.deleteAssignment(id);
      if (!mounted) return;

      if (_tabIndex == 0) {
        await _refreshMy();
      } else {
        await _refreshOwner();
      }

      if (!mounted) return;
      _showSnack('삭제 완료');
      await _scrollToTop();
    } catch (e, st) {
      safePrint('delete failed: $e\n$st');
      if (!mounted) return;
      _showError(_prettyError(e));
    }
  }

  Future<void> _openLocalView(Assignment a) async {
    _hideKeyboard();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeacherAssignmentLocalViewPage(assignment: a),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final myView = _applyViewTransform(_myItems);
    final ownerView = _applyViewTransform(_ownerItems);

    return GestureDetector(
      onTap: _hideKeyboard,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Teacher · Assignments'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: '설정',
              onPressed: () {
                try {
                  final authState = context.read<AuthState>();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: authState,
                        child: Scaffold(
                          appBar: AppBar(title: const Text('설정')),
                          body: const SettingsPage(role: 'teacher'),
                        ),
                      ),
                    ),
                  );
                } catch (e) {
                  // AuthState가 없으면 Provider 없이 열기
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('설정')),
                        body: const _SettingsPageFallback(),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
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
                      onSelectionChanged: (s) {
                        _hideKeyboard();
                        setState(() => _tabIndex = s.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              child: _isHeaderBusy
                  ? const LinearProgressIndicator(minHeight: 3)
                  : const SizedBox(height: 3),
            ),
            _buildCreateCollapsible(),
            _buildToolbarCompact(),
            const Divider(height: 1),
            Expanded(
              child: _booting
                  ? _buildSkeletonList(count: 6)
                  : IndexedStack(
                      index: _tabIndex,
                      children: [
                        _buildListCompact(
                          controller: _myScroll,
                          refreshing: _myRefreshing,
                          loadingMore: _myLoading,
                          hasMore: _myHasMore,
                          items: myView,
                          onRefresh: _refreshMy,
                          emptyTitle: '내 과제가 없습니다.',
                          emptyHint: '위에서 Create를 펼쳐서 새 과제를 만들어보세요.',
                          header: _myLastError == null ? null : _ErrorBanner(message: _myLastError!),
                        ),
                        _buildListCompact(
                          controller: _ownerScroll,
                          refreshing: _ownerRefreshing,
                          loadingMore: _ownerLoading,
                          hasMore: _ownerHasMore,
                          items: ownerView,
                          onRefresh: _refreshOwner,
                          emptyTitle: 'OwnerOnly 항목이 없습니다.',
                          emptyHint: '이 탭은 서버 @auth 정책에 따라 owners 그룹만 더 많은 데이터를 볼 수 있습니다.',
                          header: Column(
                            children: [
                              const _OwnerPolicyBanner(),
                              if (_ownerLastError != null) ...[
                                const SizedBox(height: 8),
                                _ErrorBanner(message: _ownerLastError!),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

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
                onTap: () {
                  _hideKeyboard();
                  setState(() => _createExpanded = !_createExpanded);
                },
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
                        focusNode: _studentFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _titleFocus.requestFocus(),
                        decoration: const InputDecoration(
                          labelText: 'studentUsername',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _descFocus.requestFocus(),
                        decoration: const InputDecoration(
                          labelText: 'title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        focusNode: _descFocus,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _createAssignment(),
                        decoration: const InputDecoration(
                          labelText: 'description (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDueDate,
                              icon: const Icon(Icons.event),
                              label: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Due date: ${_formatDateYmd(_dueDateLocal)}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Clear due date',
                            onPressed: _dueDateLocal == null
                                ? null
                                : () => setState(() => _dueDateLocal = null),
                            icon: const Icon(Icons.clear),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '※ dueDate는 “해당 날짜 23:59(로컬)” 기준으로 저장됩니다.',
                          style: TextStyle(fontSize: 12),
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

  Widget _buildToolbarCompact() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _hideKeyboard(),
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
                        _hideKeyboard();
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
                  onSelected: (v) {
                    _hideKeyboard();
                    setState(() => _statusFilter = v ?? _StatusFilter.all);
                  },
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
                  onSelected: (v) {
                    _hideKeyboard();
                    setState(() => _sortMode = v ?? _SortMode.newest);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListCompact({
    required ScrollController controller,
    required bool refreshing,
    required bool loadingMore,
    required bool hasMore,
    required List<Assignment> items,
    required Future<void> Function() onRefresh,
    required String emptyTitle,
    required String emptyHint,
    Widget? header,
  }) {
    final bool showSkeleton = refreshing && items.isEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        _hideKeyboard();
        await onRefresh();
      },
      child: showSkeleton
          ? _buildSkeletonList(count: 6, controller: controller)
          : ListView.separated(
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
              itemCount: 1 + (header != null ? 1 : 0) + (items.isEmpty ? 1 : (items.length + 1)),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                int cursor = 0;

                if (header != null) {
                  if (i == cursor) return header;
                  cursor += 1;
                }

                if (items.isEmpty) {
                  if (i == cursor) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Column(
                        children: [
                          Text(emptyTitle, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            emptyHint,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }

                final listIndex = i - cursor;
                if (listIndex < items.length) {
                  final a = items[listIndex];
                  return _AssignmentTile(
                    a: a,
                    onTap: () => _openLocalView(a), // ✅ “디바이스 공유 로컬 조회” 상세
                    onActions: () => _openActionSheet(a),
                    onCopyId: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(ClipboardData(text: a.id));
                      if (!mounted) return;
                      messenger.showSnackBar(const SnackBar(content: Text('ID copied')));
                    },
                    onDelete: () => _deleteDirect(a),
                    formatYmd: _formatDateYmd,
                  );
                }

                if (loadingMore) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!hasMore) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text('더 이상 없음')),
                  );
                }
                return const SizedBox(height: 16);
              },
            ),
    );
  }

  Widget _buildSkeletonList({required int count, ScrollController? controller}) {
    final c = Theme.of(context).colorScheme;
    final base = c.surfaceContainerHighest.withValues(alpha: 0.7);

    return ListView.separated(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 18,
                  width: 180,
                  decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      height: 28,
                      width: 120,
                      decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(999)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 28,
                      width: 110,
                      decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(999)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 28,
                      width: 80,
                      decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(999)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  final Assignment a;
  final VoidCallback onTap;
  final VoidCallback onActions;
  final Future<void> Function() onCopyId;
  final VoidCallback onDelete;
  final String Function(DateTime?) formatYmd;

  const _AssignmentTile({
    required this.a,
    required this.onTap,
    required this.onActions,
    required this.onCopyId,
    required this.onDelete,
    required this.formatYmd,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = a.status.name;
    final dueUtc = a.dueDate?.getDateTimeInUtc();
    final dueLocal = dueUtc?.toLocal();
    final dueText = formatYmd(dueLocal);

    return Card(
      child: ListTile(
        onTap: onTap, // ✅ 카드 탭 → 로컬 조회 상세
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
              const _MetaChip(icon: Icons.cloud_off, text: '로컬 조회'),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (k) async {
            if (k == 'detail') {
              onTap();
              return;
            }
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
            PopupMenuItem(value: 'detail', child: Text('Local Detail')),
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

class _OwnerPolicyBanner extends StatelessWidget {
  const _OwnerPolicyBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OwnerOnly 탭 안내', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  const Text(
                    '• 이 탭은 서버(AppSync) @auth 정책이 최종 판정합니다.\n'
                    '• 현재 계정이 owners 그룹이 아니면 “비어있어도 정상”입니다.\n'
                    '• 권한이 없으면 401/Not Authorized가 나올 수 있습니다.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.errorContainer.withValues(alpha: 0.65),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: cs.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: cs.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AuthState 없이 작동하는 설정 페이지 (폴백)
class _SettingsPageFallback extends StatelessWidget {
  const _SettingsPageFallback();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // 사용자 정보
        const ListTile(
          leading: CircleAvatar(child: Icon(Icons.person)),
          title: Text('선생님'),
          subtitle: Text('교사'),
        ),
        const Divider(),

        // 교재 관리
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '📚 교재 관리',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.indigo,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.menu_book, color: Colors.indigo),
          title: const Text('교재 목록'),
          subtitle: const Text('등록된 교재 확인'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('교재 목록 기능은 곧 추가됩니다')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.add_circle, color: Colors.green),
          title: const Text('교재 추가'),
          subtitle: const Text('새 교재 등록'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('교재 추가 기능은 곧 추가됩니다')),
            );
          },
        ),
        const Divider(),

        // 일반 설정
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '⚙️ 설정',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('앱 정보'),
          subtitle: const Text('버전 1.0.0'),
        ),
      ],
    );
  }
}
