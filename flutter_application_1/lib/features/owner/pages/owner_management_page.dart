// lib/features/owner/pages/owner_management_page.dart
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:provider/provider.dart';
import '../../../models/ModelProvider.dart';
import '../../users/data/repositories/teacher_aws_repository.dart';
import '../../users/data/repositories/student_aws_repository.dart';
import '../../invitation/invitation_management_page.dart';
import '../../../shared/services/auth_state.dart';

/// Owner 전용 관리 페이지
/// 4개 탭: 선생 관리 / 학생 관리 / 배정 관리 / 초대 관리
class OwnerManagementPage extends StatefulWidget {
  const OwnerManagementPage({super.key});

  @override
  State<OwnerManagementPage> createState() => _OwnerManagementPageState();
}

class _OwnerManagementPageState extends State<OwnerManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _teacherRepo = const TeacherAwsRepository();
  final _studentRepo = StudentAwsRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    safePrint('[OwnerManagementPage] 빌드');

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '선생 관리'),
            Tab(text: '학생 관리'),
            Tab(text: '배정 관리'),
            Tab(text: '초대 관리'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _TeacherManagementTab(repository: _teacherRepo),
              _StudentManagementTab(repository: _studentRepo),
              _AssignmentManagementTab(
                teacherRepo: _teacherRepo,
                studentRepo: _studentRepo,
              ),
              Builder(
                builder: (context) {
                  safePrint('[OwnerManagementPage] 초대 관리 탭 진입');
                  final authState = context.watch<AuthState>();
                  final currentMembership = authState.currentMembership;

                  if (currentMembership == null) {
                    safePrint('[OwnerManagementPage] ERROR: currentMembership is null');
                    return const Center(child: Text('학원 정보를 불러올 수 없습니다'));
                  }

                  safePrint('[OwnerManagementPage] academyId: ${currentMembership.academyId}');
                  return InvitationManagementPage(academyId: currentMembership.academyId);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 선생 관리 탭
class _TeacherManagementTab extends StatefulWidget {
  final TeacherAwsRepository repository;

  const _TeacherManagementTab({required this.repository});

  @override
  State<_TeacherManagementTab> createState() => _TeacherManagementTabState();
}

class _TeacherManagementTabState extends State<_TeacherManagementTab> {
  List<Teacher> _teachers = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => _loading = true);
    try {
      final allTeachers = await widget.repository.getAllTeachers();

      // Owner 계정 제외 (username이 "owner"로 시작하는 계정 필터링)
      final teachers = allTeachers
          .where((teacher) => !teacher.username.toLowerCase().startsWith('owner'))
          .toList();

      safePrint('[TeacherManagementTab] Total teachers: ${allTeachers.length}, Filtered (excluding owners): ${teachers.length}');

      if (mounted) {
        setState(() {
          _teachers = teachers;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('선생 목록 로드 실패: $e')),
        );
      }
    }
  }

  Future<void> _showCreateTeacherDialog() async {
    final usernameController = TextEditingController();
    final nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선생 등록'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: '아이디 (username)*',
                  hintText: 'teacher01',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '이름*',
                  hintText: '홍길동',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (usernameController.text.isEmpty ||
                  nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('아이디와 이름은 필수입니다')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('등록'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      safePrint('[TeacherManagementTab] Attempting to create teacher: ${usernameController.text.trim()}');

      final teacher = await widget.repository.createTeacher(
        username: usernameController.text.trim(),
        name: nameController.text.trim(),
      );

      safePrint('[TeacherManagementTab] Create teacher result: ${teacher != null ? "SUCCESS (id: ${teacher.id})" : "FAILED"}');

      if (mounted) {
        if (teacher != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('선생이 등록되었습니다 (ID: ${teacher.id})')),
          );
          await _loadTeachers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('선생 등록에 실패했습니다. 로그를 확인해주세요.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteTeacher(Teacher teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선생 삭제'),
        content: Text('${teacher.name} 선생을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      safePrint('[TeacherManagementTab] Attempting to delete teacher: ${teacher.id}');

      final success = await widget.repository.deleteTeacher(teacher.id);

      safePrint('[TeacherManagementTab] Delete teacher result: ${success ? "SUCCESS" : "FAILED"}');

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('선생이 삭제되었습니다')),
          );
          _loadTeachers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('선생 삭제에 실패했습니다. 로그를 확인해주세요.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                '전체 선생: ${_teachers.length}명',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _showCreateTeacherDialog,
                icon: const Icon(Icons.add),
                label: const Text('선생 등록'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _teachers.isEmpty
              ? const Center(
                  child: Text('등록된 선생이 없습니다'),
                )
              : RefreshIndicator(
                  onRefresh: _loadTeachers,
                  child: ListView.builder(
                    itemCount: _teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = _teachers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(teacher.name[0]),
                        ),
                        title: Text(teacher.name),
                        subtitle: Text('ID: ${teacher.username}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTeacher(teacher),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

/// 학생 관리 탭
class _StudentManagementTab extends StatefulWidget {
  final StudentAwsRepository repository;

  const _StudentManagementTab({required this.repository});

  @override
  State<_StudentManagementTab> createState() => _StudentManagementTabState();
}

class _StudentManagementTabState extends State<_StudentManagementTab> {
  List<Student> _students = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    try {
      final students = await widget.repository.getAll();
      if (mounted) {
        setState(() {
          _students = students;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('학생 목록 로드 실패: $e')),
        );
      }
    }
  }

  Future<void> _showCreateStudentDialog() async {
    final usernameController = TextEditingController();
    final nameController = TextEditingController();
    final gradeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('학생 등록'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: '아이디 (username)*',
                  hintText: 'student01',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '이름*',
                  hintText: '김철수',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gradeController,
                decoration: const InputDecoration(
                  labelText: '학년',
                  hintText: '초등 3학년',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (usernameController.text.isEmpty ||
                  nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('아이디와 이름은 필수입니다')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('등록'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      safePrint('[StudentManagementTab] Attempting to create student: ${usernameController.text.trim()}');

      final student = await widget.repository.createStudent(
        username: usernameController.text.trim(),
        name: nameController.text.trim(),
        grade: gradeController.text.trim().isEmpty
            ? null
            : gradeController.text.trim(),
      );

      safePrint('[StudentManagementTab] Create student result: ${student != null ? "SUCCESS (id: ${student.id})" : "FAILED"}');

      if (mounted) {
        if (student != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('학생이 등록되었습니다 (ID: ${student.id})')),
          );
          _loadStudents();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('학생 등록에 실패했습니다. 로그를 확인해주세요.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteStudent(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('학생 삭제'),
        content: Text('${student.name} 학생을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      safePrint('[StudentManagementTab] Attempting to delete student: ${student.id}');

      final success = await widget.repository.deleteStudent(student.id);

      safePrint('[StudentManagementTab] Delete student result: ${success ? "SUCCESS" : "FAILED"}');

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('학생이 삭제되었습니다')),
          );
          _loadStudents();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('학생 삭제에 실패했습니다. 로그를 확인해주세요.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                '전체 학생: ${_students.length}명',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _showCreateStudentDialog,
                icon: const Icon(Icons.add),
                label: const Text('학생 등록'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _students.isEmpty
              ? const Center(
                  child: Text('등록된 학생이 없습니다'),
                )
              : RefreshIndicator(
                  onRefresh: _loadStudents,
                  child: ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(student.name[0]),
                        ),
                        title: Text(student.name),
                        subtitle: Text(
                          'ID: ${student.username}${student.grade != null ? '\n${student.grade}' : ''}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteStudent(student),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

/// 배정 관리 탭
class _AssignmentManagementTab extends StatefulWidget {
  final TeacherAwsRepository teacherRepo;
  final StudentAwsRepository studentRepo;

  const _AssignmentManagementTab({
    required this.teacherRepo,
    required this.studentRepo,
  });

  @override
  State<_AssignmentManagementTab> createState() =>
      _AssignmentManagementTabState();
}

class _AssignmentManagementTabState extends State<_AssignmentManagementTab> {
  List<Teacher> _teachers = [];
  Map<String, List<Student>> _assignmentMap = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final allTeachers = await widget.teacherRepo.getAllTeachers();

      // Owner 계정 제외 (username이 "owner"로 시작하는 계정 필터링)
      final teachers = allTeachers
          .where((teacher) => !teacher.username.toLowerCase().startsWith('owner'))
          .toList();

      final assignmentMap = <String, List<Student>>{};

      for (final teacher in teachers) {
        final students =
            await widget.studentRepo.getStudentsByTeacher(teacher.username);
        assignmentMap[teacher.username] = students;
      }

      safePrint('[AssignmentManagementTab] Total teachers: ${allTeachers.length}, Filtered (excluding owners): ${teachers.length}');

      if (mounted) {
        setState(() {
          _teachers = teachers;
          _assignmentMap = assignmentMap;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')),
        );
      }
    }
  }

  Future<void> _showAssignStudentDialog(Teacher teacher) async {
    final allStudents = await widget.studentRepo.getAll();
    final assignedStudents = _assignmentMap[teacher.username] ?? [];
    final assignedUsernames =
        assignedStudents.map((s) => s.username).toSet();
    final availableStudents = allStudents
        .where((s) => !assignedUsernames.contains(s.username))
        .toList();

    if (!mounted) return;

    if (availableStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('배정 가능한 학생이 없습니다')),
      );
      return;
    }

    Student? selectedStudent;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${teacher.name} 선생님께 학생 배정'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Student>(
                  decoration: const InputDecoration(
                    labelText: '학생 선택',
                  ),
                  items: availableStudents.map((student) {
                    return DropdownMenuItem(
                      value: student,
                      child: Text('${student.name} (${student.username})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStudent = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (selectedStudent == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('학생을 선택해주세요')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('배정'),
          ),
        ],
      ),
    );

    if (result == true && selectedStudent != null && mounted) {
      safePrint('[AssignmentManagementTab] Attempting to link student to teacher: ${teacher.username} -> ${selectedStudent!.username}');

      final teacherStudent = await widget.studentRepo.linkStudentToTeacher(
        teacherUsername: teacher.username,
        studentUsername: selectedStudent!.username,
      );

      safePrint('[AssignmentManagementTab] Link result: ${teacherStudent != null ? "SUCCESS (id: ${teacherStudent.id})" : "FAILED"}');

      if (mounted) {
        if (teacherStudent != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('학생이 배정되었습니다')),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('학생 배정에 실패했습니다. 로그를 확인해주세요.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _unassignStudent(Teacher teacher, Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('배정 해제'),
        content: Text(
            '${teacher.name} 선생님으로부터 ${student.name} 학생을 배정 해제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('해제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      safePrint('[AssignmentManagementTab] Attempting to unlink student from teacher: ${teacher.username} -> ${student.username}');

      final success = await widget.studentRepo.unlinkStudentFromTeacher(
        teacherUsername: teacher.username,
        studentUsername: student.username,
      );

      safePrint('[AssignmentManagementTab] Unlink result: ${success ? "SUCCESS" : "FAILED"}');

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('배정이 해제되었습니다')),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('배정 해제에 실패했습니다. 로그를 확인해주세요.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                '선생님별 배정 현황',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: _teachers.isEmpty
              ? const Center(
                  child: Text('등록된 선생님이 없습니다'),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    itemCount: _teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = _teachers[index];
                      final students = _assignmentMap[teacher.username] ?? [];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            child: Text(teacher.name[0]),
                          ),
                          title: Text(teacher.name),
                          subtitle:
                              Text('배정된 학생: ${students.length}명'),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_add),
                            onPressed: () => _showAssignStudentDialog(teacher),
                          ),
                          children: students.isEmpty
                              ? [
                                  const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('배정된 학생이 없습니다'),
                                  ),
                                ]
                              : students.map((student) {
                                  return ListTile(
                                    leading: const Icon(Icons.person),
                                    title: Text(student.name),
                                    subtitle: Text(student.username),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.remove_circle,
                                          color: Colors.orange),
                                      onPressed: () =>
                                          _unassignStudent(teacher, student),
                                    ),
                                  );
                                }).toList(),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
