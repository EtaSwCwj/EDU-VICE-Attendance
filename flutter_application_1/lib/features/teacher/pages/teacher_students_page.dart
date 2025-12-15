import 'package:flutter/material.dart';
import '../../users/domain/entities/user.dart';
import '../../lessons/presentation/widgets/lesson_create_dialog.dart';
import '../../homework/presentation/widgets/homework_create_dialog.dart';

class TeacherStudentsPage extends StatefulWidget {
  const TeacherStudentsPage({super.key});

  @override
  State<TeacherStudentsPage> createState() => _TeacherStudentsPageState();
}

class _TeacherStudentsPageState extends State<TeacherStudentsPage> {
  String _query = '';
  String _filterType = 'all'; // 'all', 'today_lesson', 'has_homework'
  final List<Student> _students = [];
  
  // 현재 선택된 학생 (상세 보기용)
  Student? _selectedStudent;
  
  // 테스트용 데이터 (실제로는 Provider/Repository에서 가져옴)
  final Set<String> _studentsWithTodayLesson = {'student-001', 'student-003'};
  final Set<String> _studentsWithHomework = {'student-002', 'student-004'};

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() {
    setState(() {
      _students.addAll(_generateTestData());
    });
  }

  List<Student> _generateTestData() {
    final now = DateTime.now();
    return [
      Student(
        id: 'student-001',
        academyId: 'academy-dev',
        name: '김민준',
        phone: '010-1234-5678',
        age: 15,
        assignedTeacherIds: ['teacher-001'],
        enrolledAt: now.subtract(const Duration(days: 90)),
        isActive: true,
      ),
      Student(
        id: 'student-002',
        academyId: 'academy-dev',
        name: '이서연',
        phone: '010-2345-6789',
        age: 14,
        assignedTeacherIds: ['teacher-001'],
        enrolledAt: now.subtract(const Duration(days: 60)),
        isActive: true,
      ),
      Student(
        id: 'student-003',
        academyId: 'academy-dev',
        name: '박지후',
        phone: '010-3456-7890',
        age: 16,
        assignedTeacherIds: ['teacher-001'],
        enrolledAt: now.subtract(const Duration(days: 30)),
        isActive: true,
      ),
      Student(
        id: 'student-004',
        academyId: 'academy-dev',
        name: '최예은',
        phone: '010-4567-8901',
        age: 15,
        assignedTeacherIds: ['teacher-001'],
        enrolledAt: now.subtract(const Duration(days: 20)),
        isActive: true,
      ),
      Student(
        id: 'student-005',
        academyId: 'academy-dev',
        name: '정하준',
        phone: '010-5678-9012',
        age: 14,
        assignedTeacherIds: ['teacher-001'],
        enrolledAt: now.subtract(const Duration(days: 10)),
        isActive: true,
      ),
    ];
  }

  List<Student> get _filteredStudents {
    var result = _students.where((s) =>
        _query.isEmpty ||
        s.name.toLowerCase().contains(_query.toLowerCase())).toList();
    
    // 필터 적용 ('all' = 전체)
    if (_filterType == 'today_lesson') {
      result = result.where((s) => _studentsWithTodayLesson.contains(s.id)).toList();
    } else if (_filterType == 'has_homework') {
      result = result.where((s) => _studentsWithHomework.contains(s.id)).toList();
    }
    // _filterType == 'all' → 전체 (필터링 안 함)
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 관리'),
        actions: [
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
              child: filteredStudents.isEmpty
                  ? Center(
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
                                : (_query.isEmpty ? '학생이 없습니다' : '검색 결과가 없습니다'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = filteredStudents[index];
                        return _StudentCard(
                          student: student,
                          hasTodayLesson: _studentsWithTodayLesson.contains(student.id),
                          hasHomework: _studentsWithHomework.contains(student.id),
                          onTap: () => setState(() => _selectedStudent = student),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSearchStudentDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('학생 연결'),
      ),
    );
  }

  Future<void> _showSearchStudentDialog() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AWS 계정 검색 기능은 곧 추가됩니다')),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;
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
          '${student.age}세${student.phone != null ? ' · ${student.phone}' : ''}',
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
  final Student student;
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLessonsTab(),
            _buildHomeworkTab(),
            _buildStatsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLessonDialog(),
        icon: const Icon(Icons.add),
        label: const Text('수업 추가'),
      ),
    );
  }

  /// 수업 탭
  Widget _buildLessonsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBookProgressCard(),
        const SizedBox(height: 16),
        _buildRecentLessonsCard(),
      ],
    );
  }

  Widget _buildBookProgressCard() {
    final books = [
      _BookProgressData(
        title: '초등 수학의 정석',
        subject: '수학',
        currentChapter: '3단원 소수',
        progress: 0.5,
      ),
      _BookProgressData(
        title: '초등 영어 첫걸음',
        subject: '영어',
        currentChapter: 'Unit 4 Food',
        progress: 0.67,
      ),
    ];

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
            ...books.map((book) => _buildBookProgressItem(book)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookProgressItem(_BookProgressData book) {
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
                  color: _getSubjectColor(book.subject),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(book.subject,
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
              Text(book.currentChapter, style: TextStyle(color: Colors.indigo[700])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: book.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(_getSubjectColor(book.subject)),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(book.progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final lessonHistory = [
      _LessonHistoryItem(date: DateTime.now().subtract(const Duration(days: 1)), subject: '수학',
        bookTitle: '초등 수학의 정석', chapter: '3단원 소수', pages: 'p.45-52', score: 85, memo: '집중력 좋음'),
      _LessonHistoryItem(date: DateTime.now().subtract(const Duration(days: 3)), subject: '영어',
        bookTitle: '초등 영어 첫걸음', chapter: 'Unit 3 School', pages: 'p.25-30', score: 78, memo: '발음 연습 필요'),
      _LessonHistoryItem(date: DateTime.now().subtract(const Duration(days: 5)), subject: '수학',
        bookTitle: '초등 수학의 정석', chapter: '2단원 분수', pages: 'p.30-40', score: 92, memo: null),
    ];

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
            ...lessonHistory.map((item) => _buildLessonHistoryItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonHistoryItem(_LessonHistoryItem item) {
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
                decoration: BoxDecoration(color: _getSubjectColor(item.subject), borderRadius: BorderRadius.circular(4)),
                child: Text(item.subject, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text('${item.date.month}/${item.date.day}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const Spacer(),
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text('${item.score}점', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.menu_book, size: 14, color: Colors.indigo),
              const SizedBox(width: 4),
              Expanded(child: Text('${item.bookTitle} - ${item.chapter} ${item.pages}',
                style: TextStyle(color: Colors.indigo[700], fontSize: 13), overflow: TextOverflow.ellipsis)),
            ],
          ),
          if (item.memo != null) ...[
            const SizedBox(height: 4),
            Text('💬 ${item.memo}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ],
      ),
    );
  }

  /// 숙제 탭
  Widget _buildHomeworkTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCurrentHomeworkCard(),
        const SizedBox(height: 16),
        _buildCompletedHomeworkCard(),
      ],
    );
  }

  Widget _buildCurrentHomeworkCard() {
    final currentHomework = [
      _HomeworkItem(id: 'hw-001', subject: '수학', bookTitle: '초등 수학의 정석', chapter: '3단원 소수',
        pages: 'p.53-58 문제풀이', dueDate: DateTime.now().add(const Duration(days: 1)), status: 'pending'),
    ];

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
                Text('현재 숙제', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddHomeworkDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('발급'),
                ),
              ],
            ),
            const Divider(),
            if (currentHomework.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('현재 진행중인 숙제가 없습니다')))
            else
              ...currentHomework.map((hw) => _buildHomeworkItem(hw, showDueDate: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedHomeworkCard() {
    final completedHomework = [
      _HomeworkItem(id: 'hw-002', subject: '영어', bookTitle: '초등 영어 첫걸음', chapter: 'Unit 3 School',
        pages: 'p.31-35 단어암기', dueDate: DateTime.now().subtract(const Duration(days: 3)),
        status: 'completed', score: 90, completedOnTime: true),
      _HomeworkItem(id: 'hw-003', subject: '수학', bookTitle: '초등 수학의 정석', chapter: '2단원 분수',
        pages: 'p.41-45 문제풀이', dueDate: DateTime.now().subtract(const Duration(days: 5)),
        status: 'completed', score: 85, completedOnTime: false),
    ];

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
                Text('완료 숙제', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            if (completedHomework.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('완료된 숙제가 없습니다')))
            else
              ...completedHomework.map((hw) => _buildHomeworkItem(hw, showScore: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkItem(_HomeworkItem hw, {bool showDueDate = false, bool showScore = false}) {
    final isOverdue = hw.dueDate.isBefore(DateTime.now()) && hw.status == 'pending';
    
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
                decoration: BoxDecoration(color: _getSubjectColor(hw.subject), borderRadius: BorderRadius.circular(4)),
                child: Text(hw.subject, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const Spacer(),
              if (showDueDate) ...[
                Icon(isOverdue ? Icons.warning : Icons.schedule, size: 14, color: isOverdue ? Colors.red : Colors.grey),
                const SizedBox(width: 4),
                Text('마감: ${hw.dueDate.month}/${hw.dueDate.day}',
                  style: TextStyle(color: isOverdue ? Colors.red : Colors.grey[600], fontSize: 12)),
              ],
              if (showScore && hw.score != null) ...[
                Icon(hw.completedOnTime == true ? Icons.check_circle : Icons.schedule, size: 14,
                  color: hw.completedOnTime == true ? Colors.green : Colors.orange),
                const SizedBox(width: 4),
                Text('${hw.score}점', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.menu_book, size: 14, color: Colors.indigo),
              const SizedBox(width: 4),
              Expanded(child: Text('${hw.bookTitle} - ${hw.chapter}',
                style: TextStyle(color: Colors.indigo[700], fontSize: 13), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Text(hw.pages, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  /// 통계 탭
  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOverallStatsCard(),
        const SizedBox(height: 16),
        _buildSubjectStatsCard(),
      ],
    );
  }

  Widget _buildOverallStatsCard() {
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
                _buildStatItem('총 수업', '24회', Icons.school),
                _buildStatItem('평균 점수', '82점', Icons.star),
                _buildStatItem('출석률', '95%', Icons.check_circle),
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
            _buildSubjectStatRow('수학', 85, 12),
            _buildSubjectStatRow('영어', 78, 8),
            _buildSubjectStatRow('과학', 92, 4),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.student.name} 학생에게 수업이 추가되었습니다')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.student.name} 학생에게 숙제가 발급되었습니다')),
      );
    }
  }
}

class _BookProgressData {
  final String title;
  final String subject;
  final String currentChapter;
  final double progress;

  const _BookProgressData({
    required this.title,
    required this.subject,
    required this.currentChapter,
    required this.progress,
  });
}

class _LessonHistoryItem {
  final DateTime date;
  final String subject;
  final String bookTitle;
  final String chapter;
  final String pages;
  final int score;
  final String? memo;

  const _LessonHistoryItem({
    required this.date,
    required this.subject,
    required this.bookTitle,
    required this.chapter,
    required this.pages,
    required this.score,
    this.memo,
  });
}

class _HomeworkItem {
  final String id;
  final String subject;
  final String bookTitle;
  final String chapter;
  final String pages;
  final DateTime dueDate;
  final String status;
  final int? score;
  final bool? completedOnTime;

  const _HomeworkItem({
    required this.id,
    required this.subject,
    required this.bookTitle,
    required this.chapter,
    required this.pages,
    required this.dueDate,
    required this.status,
    this.score,
    this.completedOnTime,
  });
}
