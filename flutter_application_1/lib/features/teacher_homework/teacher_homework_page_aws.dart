// lib/features/teacher_homework/teacher_homework_page_aws.dart
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:get_it/get_it.dart';
import '../../models/ModelProvider.dart' as aws;
import '../../core/di/injection_container.dart';
import '../homework/data/repositories/assignment_aws_repository.dart';
import '../users/data/repositories/student_aws_repository.dart';
import '../books/data/repositories/book_aws_repository.dart';

/// AWS 기반 선생님 숙제 관리 페이지
/// 로컬 데이터 대신 AssignmentAwsRepository 사용
class TeacherHomeworkPageAws extends StatefulWidget {
  const TeacherHomeworkPageAws({super.key});

  @override
  State<TeacherHomeworkPageAws> createState() => _TeacherHomeworkPageAwsState();
}

class _TeacherHomeworkPageAwsState extends State<TeacherHomeworkPageAws> {
  final AssignmentAwsRepository _assignmentRepo = getIt<AssignmentAwsRepository>();
  final StudentAwsRepository _studentRepo = getIt<StudentAwsRepository>();
  final BookAwsRepository _bookRepo = getIt<BookAwsRepository>();

  List<aws.Student> _students = [];
  List<aws.Assignment> _assignments = [];
  List<aws.Book> _books = [];
  aws.Student? _selectedStudent;
  aws.Subject? _selectedSubject;

  bool _loading = true;
  String? _error;
  String? _teacherUsername;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 현재 선생님 username 가져오기
      final user = await Amplify.Auth.getCurrentUser();
      _teacherUsername = user.username;

      safePrint('[TeacherHomeworkPageAws] Loading data for teacher: $_teacherUsername');

      // 학생 목록 조회 (Student 테이블 전체)
      safePrint('[TeacherHomeworkPageAws] Calling StudentAwsRepository.getAll...');
      final students = await _studentRepo.getAll();

      safePrint('[TeacherHomeworkPageAws] StudentAwsRepository returned ${students.length} students');
      for (final student in students.take(3)) {
        safePrint('[TeacherHomeworkPageAws]   - Student: ${student.username}, name: ${student.name}');
      }

      // 교재 목록 조회
      final books = await _bookRepo.getAll();

      if (mounted) {
        setState(() {
          _students = students;
          _books = books;
          _loading = false;
        });

        safePrint('[TeacherHomeworkPageAws] Loaded ${students.length} students, ${books.length} books');
      }
    } catch (e, stackTrace) {
      safePrint('[TeacherHomeworkPageAws] Error loading data: $e');
      safePrint('[TeacherHomeworkPageAws] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = '데이터를 불러오는데 실패했습니다: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadAssignments() async {
    if (_selectedStudent == null) return;

    setState(() => _loading = true);

    try {
      safePrint('[TeacherHomeworkPageAws] Loading assignments for student: ${_selectedStudent!.username}');

      final assignments = await _assignmentRepo.getByStudent(_selectedStudent!.username);

      if (mounted) {
        setState(() {
          _assignments = assignments;
          _loading = false;
        });

        safePrint('[TeacherHomeworkPageAws] Loaded ${assignments.length} assignments');
      }
    } catch (e) {
      safePrint('[TeacherHomeworkPageAws] Error loading assignments: $e');
      if (mounted) {
        setState(() {
          _error = '숙제 목록을 불러오는데 실패했습니다: $e';
          _loading = false;
        });
      }
    }
  }

  List<aws.Assignment> get _filteredAssignments {
    if (_selectedSubject == null) return _assignments;
    return _assignments.where((a) {
      // Assignment는 book과 연결되어 있으므로 book의 subject로 필터링
      final book = _books.firstWhere(
        (b) => b.id == a.book,
        orElse: () => aws.Book(title: '', subject: aws.Subject.MATH, grade: aws.Grade.ELEMENTARY),
      );
      return book.subject == _selectedSubject;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surface = cs.surfaceContainerHighest.withValues(alpha: 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('숙제 (교사)'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: _selectedStudent == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'teacher_homework_aws_fab',
              onPressed: _showCreateAssignmentDialog,
              icon: const Icon(Icons.add),
              label: const Text('새 과제'),
            ),
      body: Column(
        children: [
          Material(
            color: surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  _buildStudentPicker(),
                  const SizedBox(height: 8),
                  _buildSubjectFilter(),
                  if (_selectedStudent != null) ...[
                    const SizedBox(height: 8),
                    _buildStatusCounters(),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentPicker() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<aws.Student>(
            decoration: const InputDecoration(
              labelText: '학생 선택',
              border: OutlineInputBorder(),
            ),
            initialValue: _selectedStudent,
            items: _students.map((student) {
              return DropdownMenuItem(
                value: student,
                child: Text(student.name),
              );
            }).toList(),
            onChanged: (student) {
              setState(() {
                _selectedStudent = student;
                _assignments = [];
              });
              if (student != null) {
                _loadAssignments();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectFilter() {
    final subjects = [
      aws.Subject.MATH,
      aws.Subject.ENGLISH,
      aws.Subject.SCIENCE,
      aws.Subject.KOREAN,
    ];

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<aws.Subject?>(
            decoration: const InputDecoration(
              labelText: '과목 필터',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('전체')),
              ...subjects.map((subject) {
                String name;
                switch (subject) {
                  case aws.Subject.MATH:
                    name = '수학';
                    break;
                  case aws.Subject.ENGLISH:
                    name = '영어';
                    break;
                  case aws.Subject.SCIENCE:
                    name = '과학';
                    break;
                  case aws.Subject.KOREAN:
                    name = '국어';
                    break;
                }
                return DropdownMenuItem(value: subject, child: Text(name));
              }),
            ],
            onChanged: (subject) {
              setState(() => _selectedSubject = subject);
            },
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => setState(() => _selectedSubject = null),
          icon: const Icon(Icons.filter_alt_off),
          label: const Text('필터 해제'),
        ),
      ],
    );
  }

  Widget _buildStatusCounters() {
    final cs = Theme.of(context).colorScheme;
    final items = _filteredAssignments;

    int pending = items.where((a) => a.status == aws.AssignmentStatus.ASSIGNED).length;
    int inProgress = items.where((a) => a.status == aws.AssignmentStatus.IN_PROGRESS).length;
    int done = items.where((a) => a.status == aws.AssignmentStatus.DONE).length;

    Widget pill(Color bg, Color fg, String label, int count) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$count', style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          pill(cs.primary.withValues(alpha: 0.10), cs.primary, '발급', pending),
          const SizedBox(width: 8),
          pill(cs.tertiary.withValues(alpha: 0.10), cs.tertiary, '진행중', inProgress),
          const SizedBox(width: 8),
          pill(cs.secondary.withValues(alpha: 0.10), cs.secondary, '완료', done),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
      );
    }

    if (_selectedStudent == null) {
      return const Center(
        child: Text('학생을 먼저 선택하세요.', style: TextStyle(fontSize: 16)),
      );
    }

    if (_filteredAssignments.isEmpty) {
      return const Center(
        child: Text('해당 학생의 숙제가 없습니다.', style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: _filteredAssignments.length,
      itemBuilder: (context, i) => _buildAssignmentCard(_filteredAssignments[i]),
    );
  }

  Widget _buildAssignmentCard(aws.Assignment assignment) {
    final cs = Theme.of(context).colorScheme;
    final surface = cs.surfaceContainerHighest.withValues(alpha: 1);

    Color statusColor;
    String statusLabel;
    switch (assignment.status) {
      case aws.AssignmentStatus.ASSIGNED:
        statusColor = cs.primary;
        statusLabel = '발급';
        break;
      case aws.AssignmentStatus.IN_PROGRESS:
        statusColor = cs.tertiary;
        statusLabel = '진행중';
        break;
      case aws.AssignmentStatus.DONE:
        statusColor = cs.secondary;
        statusLabel = '완료';
        break;
    }

    final dueDate = assignment.dueDate?.getDateTimeInUtc().toLocal();

    return Card(
      color: surface,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    assignment.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withValues(alpha: 0.55)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (assignment.description != null) ...[
              Text(
                assignment.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
            ],
            if (dueDate != null)
              Text(
                '마감: ${_formatDate(dueDate)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: assignment.status == aws.AssignmentStatus.DONE
                      ? null
                      : () => _updateStatus(assignment, aws.AssignmentStatus.DONE),
                  icon: const Icon(Icons.check),
                  label: const Text('완료 처리'),
                ),
                OutlinedButton.icon(
                  onPressed: assignment.status == aws.AssignmentStatus.IN_PROGRESS
                      ? null
                      : () => _updateStatus(assignment, aws.AssignmentStatus.IN_PROGRESS),
                  icon: const Icon(Icons.edit),
                  label: const Text('진행중'),
                ),
                OutlinedButton.icon(
                  onPressed: assignment.status == aws.AssignmentStatus.ASSIGNED
                      ? null
                      : () => _updateStatus(assignment, aws.AssignmentStatus.ASSIGNED),
                  icon: const Icon(Icons.undo),
                  label: const Text('초기화'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(aws.Assignment assignment, aws.AssignmentStatus newStatus) async {
    try {
      final success = await _assignmentRepo.updateStatus(assignment.id, newStatus);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상태가 업데이트되었습니다')),
        );
        _loadAssignments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상태 업데이트에 실패했습니다')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    }
  }

  Future<void> _showCreateAssignmentDialog() async {
    if (_selectedStudent == null) return;

    final result = await showDialog<aws.Assignment>(
      context: context,
      builder: (context) => _CreateAssignmentDialog(
        student: _selectedStudent!,
        teacherUsername: _teacherUsername!,
        books: _books,
      ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('숙제가 생성되었습니다')),
      );
      _loadAssignments();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 숙제 생성 다이얼로그
class _CreateAssignmentDialog extends StatefulWidget {
  final aws.Student student;
  final String teacherUsername;
  final List<aws.Book> books;

  const _CreateAssignmentDialog({
    required this.student,
    required this.teacherUsername,
    required this.books,
  });

  @override
  State<_CreateAssignmentDialog> createState() => _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<_CreateAssignmentDialog> {
  final _assignmentRepo = GetIt.instance<AssignmentAwsRepository>();
  final _bookRepo = GetIt.instance<BookAwsRepository>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  aws.Book? _selectedBook;
  aws.Chapter? _selectedChapter;
  List<aws.Chapter> _chapters = [];
  bool _loadingChapters = false;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    if (_selectedBook == null) return;

    setState(() {
      _loadingChapters = true;
      _selectedChapter = null;
      _chapters = [];
    });

    safePrint('[_CreateAssignmentDialog] Loading chapters for book: ${_selectedBook!.id}');

    try {
      final chapters = await _bookRepo.getChaptersByBookId(_selectedBook!.id);

      if (mounted) {
        setState(() {
          _chapters = chapters;
          _loadingChapters = false;
        });

        safePrint('[_CreateAssignmentDialog] Loaded ${chapters.length} chapters');
      }
    } catch (e) {
      safePrint('[_CreateAssignmentDialog] Error loading chapters: $e');
      if (mounted) {
        setState(() {
          _loadingChapters = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력하세요')),
      );
      return;
    }

    if (_selectedBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('교재를 선택하세요')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      safePrint('[_CreateAssignmentDialog] Creating assignment...');
      safePrint('[_CreateAssignmentDialog]   - Student: ${widget.student.username}');
      safePrint('[_CreateAssignmentDialog]   - Teacher: ${widget.teacherUsername}');
      safePrint('[_CreateAssignmentDialog]   - Book: ${_selectedBook!.id}');
      safePrint('[_CreateAssignmentDialog]   - Chapter: ${_selectedChapter?.id}');

      final assignment = aws.Assignment(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        book: _selectedBook!.id,
        range: _selectedChapter?.title, // 챕터 제목을 range로 저장
        dueDate: TemporalDateTime(_dueDate),
        status: aws.AssignmentStatus.ASSIGNED,
        studentUsername: widget.student.username,
        teacherUsername: widget.teacherUsername,
      );

      final result = await _assignmentRepo.create(assignment);

      if (!mounted) return;

      if (result != null) {
        safePrint('[_CreateAssignmentDialog] Assignment created: ${result.id}');
        Navigator.pop(context, result);
      } else {
        safePrint('[_CreateAssignmentDialog] Assignment creation failed');
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('숙제 생성에 실패했습니다')),
        );
      }
    } catch (e, stackTrace) {
      safePrint('[_CreateAssignmentDialog] Error creating assignment: $e');
      safePrint('[_CreateAssignmentDialog] Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('새 숙제 - ${widget.student.name}'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '제목 *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 교재 선택
              DropdownButtonFormField<aws.Book>(
                decoration: const InputDecoration(
                  labelText: '교재 *',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedBook,
                items: widget.books.map((book) {
                  return DropdownMenuItem(
                    value: book,
                    child: Text(book.title),
                  );
                }).toList(),
                onChanged: (book) {
                  setState(() => _selectedBook = book);
                  _loadChapters();
                },
              ),
              const SizedBox(height: 16),

              // 챕터 선택
              if (_selectedBook != null) ...[
                _loadingChapters
                    ? const Center(child: CircularProgressIndicator())
                    : _chapters.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey[100],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '이 교재에 등록된 목차가 없습니다',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<aws.Chapter>(
                            decoration: const InputDecoration(
                              labelText: '챕터 (선택사항)',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _selectedChapter,
                            items: _chapters.map((chapter) {
                              return DropdownMenuItem(
                                value: chapter,
                                child: Text('${chapter.orderIndex}. ${chapter.title}'),
                              );
                            }).toList(),
                            onChanged: (chapter) {
                              setState(() => _selectedChapter = chapter);
                            },
                          ),
                const SizedBox(height: 16),
              ],

              // 마감일
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '마감일',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 설명
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '설명 (선택사항)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('생성'),
        ),
      ],
    );
  }
}
