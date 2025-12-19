import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:provider/provider.dart';
import '../../../models/ModelProvider.dart' as aws;
import '../../../core/di/injection_container.dart';
import '../../users/data/repositories/student_aws_repository.dart';
import '../../lessons/data/repositories/lesson_aws_repository.dart';
import '../../lessons/domain/entities/lesson.dart';
import '../../books/data/repositories/book_aws_repository.dart';
import '../../homework/data/repositories/assignment_aws_repository.dart';
import '../../lessons/presentation/widgets/lesson_create_dialog.dart';
import '../../homework/presentation/widgets/homework_create_dialog.dart';
import '../../../shared/services/auth_state.dart';
import '../../../shared/services/permission_service.dart';

class TeacherStudentsPage extends StatefulWidget {
  const TeacherStudentsPage({super.key});

  @override
  State<TeacherStudentsPage> createState() => _TeacherStudentsPageState();
}

class _TeacherStudentsPageState extends State<TeacherStudentsPage> {
  final StudentAwsRepository _studentRepo = getIt<StudentAwsRepository>();

  String _query = '';
  String _filterType = 'all'; // 'all', 'today_lesson', 'has_homework'
  List<aws.Student> _students = [];
  bool _isLoading = true;
  String? _error;
  String? _teacherUsername;

  // 현재 선택된 학생 (상세 보기용)
  aws.Student? _selectedStudent;

  // TODO: 실제로는 Lesson/Assignment 테이블에서 조회
  final Set<String> _studentsWithTodayLesson = {};
  final Set<String> _studentsWithHomework = {};

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final role = context.read<AuthState>().currentMembership?.role;
      List<aws.Student> students;

      if (PermissionService.canViewAllStudents(role)) {
        students = await _studentRepo.getAll();
        _teacherUsername = null;
      } else {
        _teacherUsername = await _studentRepo.getCurrentTeacherUsername();

        if (_teacherUsername == null) {
          setState(() {
            _error = '로그인 정보를 가져올 수 없습니다';
            _isLoading = false;
          });
          return;
        }

        students = await _studentRepo.getStudentsByTeacher(_teacherUsername!);
      }

      safePrint('[TeacherStudentsPage] 데이터 로드: ${students.length}명');

      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      safePrint('[TeacherStudentsPage] ERROR: $e');
      setState(() {
        _error = '학생 목록을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  List<aws.Student> get _filteredStudents {
    var result = _students.where((s) =>
        _query.isEmpty ||
        s.name.toLowerCase().contains(_query.toLowerCase())).toList();

    // 필터 적용 ('all' = 전체)
    if (_filterType == 'today_lesson') {
      result = result.where((s) => _studentsWithTodayLesson.contains(s.username)).toList();
    } else if (_filterType == 'has_homework') {
      result = result.where((s) => _studentsWithHomework.contains(s.username)).toList();
    }
    // _filterType == 'all' → 전체 (필터링 안 함)

    return result;
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('학생 관리')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 에러 발생
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('학생 관리')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadStudents,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    // 학생 상세가 선택되었으면 상세 페이지 표시
    if (_selectedStudent != null) {
      return _StudentDetailView(
        student: _selectedStudent!,
        onBack: () => setState(() => _selectedStudent = null),
        studentsWithTodayLesson: _studentsWithTodayLesson,
        studentsWithHomework: _studentsWithHomework,
      );
    }

    final filteredStudents = _filteredStudents;
    final role = context.watch<AuthState>().currentMembership?.role;
    final canAssignStudent = PermissionService.canAssignStudent(role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 관리'),
        actions: [
          // 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: '새로고침',
          ),
          // 필터 버튼
          PopupMenuButton<String>(
            icon: Icon(
              Icons.filter_list,
              color: _filterType != 'all' ? Colors.blue : null,
            ),
            onSelected: (value) {
              setState(() => _filterType = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all', // 'all' = 전체
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: _filterType == 'all' ? Colors.blue : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('전체'),
                    if (_filterType == 'all') ...[
                      const Spacer(),
                      const Icon(Icons.check, color: Colors.blue, size: 18),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'today_lesson',
                child: Row(
                  children: [
                    Icon(Icons.school, color: _filterType == 'today_lesson' ? Colors.blue : Colors.grey),
                    const SizedBox(width: 8),
                    Text('오늘 수업 (${_studentsWithTodayLesson.length}명)'),
                    if (_filterType == 'today_lesson') ...[
                      const Spacer(),
                      const Icon(Icons.check, color: Colors.blue, size: 18),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'has_homework',
                child: Row(
                  children: [
                    Icon(Icons.assignment, color: _filterType == 'has_homework' ? Colors.blue : Colors.grey),
                    const SizedBox(width: 8),
                    Text('숙제 있음 (${_studentsWithHomework.length}명)'),
                    if (_filterType == 'has_homework') ...[
                      const Spacer(),
                      const Icon(Icons.check, color: Colors.blue, size: 18),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 검색바
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: '학생 이름 검색',
                  border: const OutlineInputBorder(),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _query = ''),
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            // 필터 상태 표시
            if (_filterType != 'all')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    Icon(
                      _filterType == 'today_lesson' ? Icons.school : Icons.assignment,
                      size: 18,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _filterType == 'today_lesson'
                          ? '오늘 수업 있는 학생 (${filteredStudents.length}명)'
                          : '숙제 있는 학생 (${filteredStudents.length}명)',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _filterType = 'all'),
                      child: Icon(Icons.close, size: 18, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            // 학생 목록
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadStudents,
                child: filteredStudents.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _filterType != 'all' ? Icons.filter_alt_off : Icons.search_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _filterType != 'all'
                                      ? '조건에 맞는 학생이 없습니다'
                                      : (_query.isEmpty ? '등록된 학생이 없습니다' : '검색 결과가 없습니다'),
                                ),
                                if (_query.isEmpty && _filterType == 'all') ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '학생 연결 버튼으로 학생을 추가하세요',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return _StudentCard(
                            student: student,
                            hasTodayLesson: _studentsWithTodayLesson.contains(student.username),
                            hasHomework: _studentsWithHomework.contains(student.username),
                            onTap: () => setState(() => _selectedStudent = student),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canAssignStudent
          ? FloatingActionButton(
              heroTag: 'teacher_students_search_fab',
              onPressed: () => _showSearchStudentDialog(),
              tooltip: '학생 연결',
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }

  Future<void> _showSearchStudentDialog() async {
    if (_teacherUsername == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선생님 정보를 가져올 수 없습니다')),
      );
      return;
    }

    final selectedStudent = await showDialog<aws.Student>(
      context: context,
      builder: (context) => _SearchStudentDialog(
        teacherUsername: _teacherUsername!,
        connectedStudentUsernames: _students.map((s) => s.username).toList(),
      ),
    );

    if (selectedStudent != null && mounted) {
      // 학생 연결
      final result = await _studentRepo.linkStudentToTeacher(
        teacherUsername: _teacherUsername!,
        studentUsername: selectedStudent.username,
      );

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${selectedStudent.name} 학생이 연결되었습니다')),
          );
          _loadStudents(); // 새로고침
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('학생 연결에 실패했습니다')),
          );
        }
      }
    }
  }
}

/// 학생 검색 다이얼로그
class _SearchStudentDialog extends StatefulWidget {
  final String teacherUsername;
  final List<String> connectedStudentUsernames;

  const _SearchStudentDialog({
    required this.teacherUsername,
    required this.connectedStudentUsernames,
  });

  @override
  State<_SearchStudentDialog> createState() => _SearchStudentDialogState();
}

class _SearchStudentDialogState extends State<_SearchStudentDialog> {
  final TextEditingController _searchController = TextEditingController();
  final StudentAwsRepository _studentRepo = getIt<StudentAwsRepository>();

  List<aws.Student> _allStudents = [];
  List<aws.Student> _filteredStudents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final students = await _studentRepo.getAll();

      setState(() {
        _allStudents = students
            .where((s) => !widget.connectedStudentUsernames.contains(s.username))
            .toList();
        _filteredStudents = _allStudents;
        _isLoading = false;
      });

      safePrint('[SearchStudentDialog] 데이터 로드: ${_allStudents.length}명');
    } catch (e) {
      safePrint('[SearchStudentDialog] ERROR: $e');
      setState(() {
        _error = '학생 목록을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _allStudents;
      } else {
        _filteredStudents = _allStudents.where((student) {
          final name = student.name.toLowerCase();
          final username = student.username.toLowerCase();
          return name.contains(query) || username.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Expanded(
                  child: Text(
                    '학생 검색',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 검색 필드
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '학생 이름 또는 username으로 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // 결과 표시
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadAllStudents,
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_filteredStudents.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? (_allStudents.isEmpty && _searchController.text.isEmpty
                                ? 'AWS에 등록된 학생이 없습니다'
                                : '연결 가능한 학생이 없습니다')
                            : '검색 결과가 없습니다',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = _filteredStudents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(student.name[0]),
                        ),
                        title: Text(
                          student.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${student.username}'),
                            if (student.grade != null)
                              Text('학년: ${student.grade}'),
                          ],
                        ),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () {
                          Navigator.pop(context, student);
                        },
                      ),
                    );
                  },
                ),
              ),

            // 안내 문구
            if (!_isLoading && _error == null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_filteredStudents.length}명의 학생이 검색되었습니다',
                        style: TextStyle(color: Colors.blue[700], fontSize: 13),
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
}

class _StudentCard extends StatelessWidget {
  final aws.Student student;
  final bool hasTodayLesson;
  final bool hasHomework;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.hasTodayLesson,
    required this.hasHomework,
    required this.onTap,
  });

  String _getDisplayName(String fullName) {
    if (fullName.length >= 3) {
      return fullName.substring(1);
    } else if (fullName.length == 2) {
      return fullName;
    }
    return fullName[0];
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _getDisplayName(student.name);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue[100],
          child: Text(
            displayName.length >= 2 ? displayName.substring(0, 2) : displayName,
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(student.name),
            const SizedBox(width: 8),
            if (hasTodayLesson)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '수업',
                  style: TextStyle(fontSize: 10, color: Colors.green[700]),
                ),
              ),
            if (hasHomework) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '숙제',
                  style: TextStyle(fontSize: 10, color: Colors.orange[700]),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          student.grade != null ? '${student.grade}' : student.username,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// 학생 상세 뷰 - 하단 네비게이션 유지됨!
/// Navigator.push 대신 같은 Scaffold 내에서 표시
class _StudentDetailView extends StatefulWidget {
  final aws.Student student;
  final VoidCallback onBack;
  final Set<String> studentsWithTodayLesson;
  final Set<String> studentsWithHomework;

  const _StudentDetailView({
    required this.student,
    required this.onBack,
    required this.studentsWithTodayLesson,
    required this.studentsWithHomework,
  });

  @override
  State<_StudentDetailView> createState() => _StudentDetailViewState();
}

class _StudentDetailViewState extends State<_StudentDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // AWS Repositories
  final LessonAwsRepository _lessonRepo = getIt<LessonAwsRepository>();
  final BookAwsRepository _bookRepo = getIt<BookAwsRepository>();
  final AssignmentAwsRepository _assignmentRepo = getIt<AssignmentAwsRepository>();

  // 데이터 상태
  List<aws.Lesson> _recentLessons = [];
  List<aws.Book> _books = [];
  List<aws.Assignment> _pendingAssignments = [];
  List<aws.Assignment> _completedAssignments = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final studentUsername = widget.student.username;

      final results = await Future.wait([
        _loadLessons(studentUsername),
        _bookRepo.getAll(),
        _assignmentRepo.getByStudentAndStatus(studentUsername, aws.AssignmentStatus.ASSIGNED),
        _assignmentRepo.getByStudentAndStatus(studentUsername, aws.AssignmentStatus.DONE),
      ]);

      setState(() {
        _recentLessons = results[0] as List<aws.Lesson>;
        _books = results[1] as List<aws.Book>;
        _pendingAssignments = results[2] as List<aws.Assignment>;
        _completedAssignments = results[3] as List<aws.Assignment>;
        _isLoading = false;
      });

      safePrint('[StudentDetail] 데이터 로드: 수업 ${_recentLessons.length}, 숙제 ${_pendingAssignments.length}/${_completedAssignments.length}');
    } catch (e) {
      safePrint('[StudentDetail] ERROR: $e');
      setState(() {
        _error = '데이터를 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<aws.Lesson>> _loadLessons(String studentUsername) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      final result = await _lessonRepo.getLessonsByDateRange(
        teacherId: '',
        startDate: startDate,
        endDate: endDate,
      );

      return result.fold(
        (failure) => <aws.Lesson>[],
        (lessons) => <aws.Lesson>[],
      );
    } catch (e) {
      safePrint('[StudentDetail] ERROR: 수업 로드 실패 - $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(widget.student.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('학생 정보 수정 기능은 곧 추가됩니다')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: '수업'),
            Tab(icon: Icon(Icons.assignment), text: '숙제'),
            Tab(icon: Icon(Icons.bar_chart), text: '통계'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLessonsTab(),
                      _buildHomeworkTab(),
                      _buildStatsTab(),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'teacher_students_lesson_fab',
        onPressed: () => _showAddLessonDialog(),
        tooltip: '수업 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 수업 탭
  Widget _buildLessonsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBookProgressCard(),
          const SizedBox(height: 16),
          _buildRecentLessonsCard(),
        ],
      ),
    );
  }

  Widget _buildBookProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book, color: Colors.indigo),
                const SizedBox(width: 8),
                Text('교재별 진도', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            if (_books.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('등록된 교재가 없습니다')),
              )
            else
              ..._books.map((book) => _buildBookProgressItem(book)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookProgressItem(aws.Book book) {
    final subjectStr = subjectToKorean(book.subject);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSubjectColor(subjectStr),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(subjectStr,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.bookmark, size: 16, color: Colors.indigo),
              const SizedBox(width: 4),
              Text(gradeToKorean(book.grade), style: TextStyle(color: Colors.indigo[700])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${book.year}년', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case '수학': return Colors.blue;
      case '영어': return Colors.green;
      case '과학': return Colors.orange;
      case '국어': return Colors.purple;
      default: return Colors.grey;
    }
  }

  Widget _buildRecentLessonsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.orange),
                const SizedBox(width: 8),
                Text('최근 수업', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('전체 보기')),
              ],
            ),
            const Divider(),
            if (_recentLessons.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('최근 수업 기록이 없습니다')),
              )
            else
              ..._recentLessons.take(5).map((lesson) => _buildLessonHistoryItem(lesson)),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonHistoryItem(aws.Lesson lesson) {
    final subjectStr = subjectToKorean(lesson.subject);
    final date = lesson.scheduledDate.getDateTime();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _getSubjectColor(subjectStr), borderRadius: BorderRadius.circular(4)),
                child: Text(subjectStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text('${date.month}/${date.day}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const Spacer(),
              if (lesson.score != null) ...[
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${lesson.score}점', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.menu_book, size: 14, color: Colors.indigo),
              const SizedBox(width: 4),
              Expanded(child: Text(lesson.title,
                style: TextStyle(color: Colors.indigo[700], fontSize: 13), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }

  /// 숙제 탭
  Widget _buildHomeworkTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCurrentHomeworkCard(),
          const SizedBox(height: 16),
          _buildCompletedHomeworkCard(),
        ],
      ),
    );
  }

  Widget _buildCurrentHomeworkCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pending_actions, color: Colors.orange),
                const SizedBox(width: 8),
                Text('현재 숙제 (${_pendingAssignments.length})', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddHomeworkDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('발급'),
                ),
              ],
            ),
            const Divider(),
            if (_pendingAssignments.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('현재 진행중인 숙제가 없습니다')))
            else
              ..._pendingAssignments.map((hw) => _buildHomeworkItem(hw, showDueDate: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedHomeworkCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text('완료 숙제 (${_completedAssignments.length})', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            if (_completedAssignments.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('완료된 숙제가 없습니다')))
            else
              ..._completedAssignments.take(5).map((hw) => _buildHomeworkItem(hw, showScore: false)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkItem(aws.Assignment hw, {bool showDueDate = false, bool showScore = false}) {
    final dueDate = hw.dueDate?.getDateTimeInUtc();
    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now()) && hw.status == aws.AssignmentStatus.ASSIGNED;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isOverdue ? Colors.red[200]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                child: Text(assignmentStatusToKorean(hw.status), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const Spacer(),
              if (showDueDate && dueDate != null) ...[
                Icon(isOverdue ? Icons.warning : Icons.schedule, size: 14, color: isOverdue ? Colors.red : Colors.grey),
                const SizedBox(width: 4),
                Text('마감: ${dueDate.month}/${dueDate.day}',
                  style: TextStyle(color: isOverdue ? Colors.red : Colors.grey[600], fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(hw.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          if (hw.book != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.menu_book, size: 14, color: Colors.indigo),
                const SizedBox(width: 4),
                Expanded(child: Text('${hw.book}${hw.range != null ? ' - ${hw.range}' : ''}',
                  style: TextStyle(color: Colors.indigo[700], fontSize: 13), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
          if (hw.description != null) ...[
            const SizedBox(height: 4),
            Text(hw.description!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ],
      ),
    );
  }

  /// 통계 탭
  Widget _buildStatsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverallStatsCard(),
          const SizedBox(height: 16),
          _buildSubjectStatsCard(),
        ],
      ),
    );
  }

  Widget _buildOverallStatsCard() {
    // 실제 데이터 기반 통계 계산
    final totalLessons = _recentLessons.length;
    final lessonsWithScore = _recentLessons.where((l) => l.score != null).toList();
    final avgScore = lessonsWithScore.isNotEmpty
        ? (lessonsWithScore.map((l) => l.score!).reduce((a, b) => a + b) / lessonsWithScore.length).round()
        : 0;
    final totalAssignments = _pendingAssignments.length + _completedAssignments.length;
    final completionRate = totalAssignments > 0
        ? ((_completedAssignments.length / totalAssignments) * 100).round()
        : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                Text('전체 통계', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('총 수업', '$totalLessons회', Icons.school),
                _buildStatItem('평균 점수', '$avgScore점', Icons.star),
                _buildStatItem('숙제 완료율', '$completionRate%', Icons.check_circle),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 32),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildSubjectStatsCard() {
    // 과목별 통계 계산
    final subjectStats = <String, List<int>>{};
    for (final lesson in _recentLessons) {
      final subject = subjectToKorean(lesson.subject);
      if (!subjectStats.containsKey(subject)) {
        subjectStats[subject] = [];
      }
      if (lesson.score != null) {
        subjectStats[subject]!.add(lesson.score!);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: Colors.purple),
                const SizedBox(width: 8),
                Text('과목별 통계', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            if (subjectStats.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('수업 데이터가 없습니다')),
              )
            else
              ...subjectStats.entries.map((entry) {
                final avgScore = entry.value.isNotEmpty
                    ? (entry.value.reduce((a, b) => a + b) / entry.value.length).round()
                    : 0;
                return _buildSubjectStatRow(entry.key, avgScore, entry.value.length);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectStatRow(String subject, int avgScore, int lessonCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _getSubjectColor(subject), borderRadius: BorderRadius.circular(4)),
            child: Text(subject, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('평균 $avgScore점 · $lessonCount회'),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: avgScore / 100, backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(_getSubjectColor(subject))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddLessonDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => LessonCreateDialog(
        studentId: widget.student.id,
        studentName: widget.student.name,
      ),
    );

    if (result != null && mounted) {
      try {
        final user = await Amplify.Auth.getCurrentUser();
        final teacherUsername = user.username;

        final date = result['date'] as DateTime;
        final startTime = result['startTime'] as TimeOfDay;
        final scheduledAt = DateTime(
          date.year,
          date.month,
          date.day,
          startTime.hour,
          startTime.minute,
        );

        final lesson = Lesson(
          id: UUID.getUUID(),
          academyId: 'default',
          teacherId: teacherUsername,
          studentIds: [widget.student.username],
          bookId: result['bookId'] as String,
          subject: result['subject'] as String,
          scheduledAt: scheduledAt,
          durationMinutes: result['duration'] as int,
          status: LessonStatus.scheduled,
          progress: result['progress'] as LessonProgress?,
          isRecurring: result['isRecurring'] as bool,
          createdAt: DateTime.now(),
        );

        if (result['isRecurring'] == true) {
          final rule = result['recurrenceRule'] as RecurrenceRule;
          final createResult = await _lessonRepo.createRecurringLessons(lesson, rule);

          createResult.fold(
            (failure) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('반복 수업 생성에 실패했습니다: $failure')),
                );
              }
            },
            (lessons) {
              safePrint('[StudentDetail] 수업 생성: ${lessons.length}회');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${widget.student.name} 학생에게 ${lessons.length}회 수업이 추가되었습니다')),
                );
                _loadData();
              }
            },
          );
        } else {
          final createResult = await _lessonRepo.createLesson(lesson);

          createResult.fold(
            (failure) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('수업 생성에 실패했습니다: $failure')),
                );
              }
            },
            (createdLesson) {
              safePrint('[StudentDetail] 수업 생성 완료');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${widget.student.name} 학생에게 수업이 추가되었습니다')),
                );
                _loadData();
              }
            },
          );
        }
      } catch (e) {
        safePrint('[StudentDetail] ERROR: 수업 생성 실패 - $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('수업 생성 중 오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }

  Future<void> _showAddHomeworkDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => HomeworkCreateDialog(
        studentId: widget.student.id,
        studentName: widget.student.name,
      ),
    );

    if (result != null && mounted) {
      try {
        final user = await Amplify.Auth.getCurrentUser();
        final teacherUsername = user.username;

        String title = result['bookTitle'] as String;
        if (result['chapter'] != null) {
          title += ' - ${result['chapter']}';
        }

        String? range;
        final startPage = result['startPage'] as int?;
        final endPage = result['endPage'] as int?;
        if (startPage != null && endPage != null) {
          range = 'p.$startPage-$endPage';
        } else if (startPage != null) {
          range = 'p.$startPage~';
        }

        final assignment = aws.Assignment(
          title: title,
          description: result['description'] as String?,
          status: aws.AssignmentStatus.ASSIGNED,
          teacherUsername: teacherUsername,
          studentUsername: widget.student.username,
          book: result['bookId'] as String?,
          range: range,
          dueDate: result['dueDate'] != null
              ? TemporalDateTime((result['dueDate'] as DateTime).toUtc())
              : null,
        );

        final createdAssignment = await _assignmentRepo.create(assignment);

        if (createdAssignment != null) {
          safePrint('[StudentDetail] 숙제 발급 완료');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${widget.student.name} 학생에게 숙제가 발급되었습니다')),
            );
            _loadData();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('숙제 발급에 실패했습니다')),
            );
          }
        }
      } catch (e) {
        safePrint('[StudentDetail] ERROR: 숙제 발급 실패 - $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('숙제 발급 중 오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }
}

// AWS 모델을 직접 사용하므로 로컬 데이터 클래스 제거됨
