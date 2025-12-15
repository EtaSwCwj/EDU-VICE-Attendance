import 'package:flutter/material.dart';
import '../../users/domain/entities/user.dart';

class TeacherStudentsPage extends StatefulWidget {
  const TeacherStudentsPage({super.key});

  @override
  State<TeacherStudentsPage> createState() => _TeacherStudentsPageState();
}

class _TeacherStudentsPageState extends State<TeacherStudentsPage> {
  String _query = '';
  final List<Student> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() {
    // TODO: Repository에서 로드
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _students
        .where((s) =>
            _query.isEmpty ||
            s.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 관리'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '학생 이름 검색',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _query.isEmpty
                              ? '학생이 없습니다'
                              : '검색 결과가 없습니다',
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      return _StudentCard(
                        student: student,
                        onTap: () => _showStudentDetail(student),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStudentDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('학생 추가'),
      ),
    );
  }

  void _showStudentDetail(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _StudentDetailPage(student: student),
      ),
    );
  }

  Future<void> _showAddStudentDialog() async {
    final result = await showDialog<Student>(
      context: context,
      builder: (context) => _AddStudentDialog(),
    );

    if (result != null) {
      setState(() => _students.add(result));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.name} 학생이 추가되었습니다')),
        );
      }
    }
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(student.name.characters.first),
        ),
        title: Text(student.name),
        subtitle: Text(
          '${student.age}세${student.phone != null ? ' · ${student.phone}' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _StudentDetailPage extends StatelessWidget {
  final Student student;

  const _StudentDetailPage({required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(student.name),
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(context),
          const SizedBox(height: 16),
          _buildLessonsCard(context),
          const SizedBox(height: 16),
          _buildProgressCard(context),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기본 정보',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            _buildInfoRow(Icons.person, '이름', student.name),
            _buildInfoRow(Icons.cake, '나이', '${student.age}세'),
            if (student.phone != null)
              _buildInfoRow(Icons.phone, '연락처', student.phone!),
            if (student.email != null)
              _buildInfoRow(Icons.email, '이메일', student.email!),
            _buildInfoRow(
              Icons.calendar_today,
              '등록일',
              '${student.enrolledAt.year}.${student.enrolledAt.month}.${student.enrolledAt.day}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          SizedBox(width: 60, child: Text('$label:')),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildLessonsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '수업 이력',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('수업 이력 기능은 곧 추가됩니다'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '학습 진도',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('진도 통계 기능은 곧 추가됩니다'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStudentDialog extends StatefulWidget {
  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('학생 추가'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => v?.isEmpty ?? true ? '이름을 입력하세요' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '연락처',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: '나이',
                prefixIcon: Icon(Icons.cake),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return '나이를 입력하세요';
                final age = int.tryParse(v);
                if (age == null || age < 1 || age > 100) {
                  return '올바른 나이를 입력하세요';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final student = Student(
                id: 'student-${DateTime.now().millisecondsSinceEpoch}',
                academyId: 'academy-dev',
                name: _nameController.text,
                phone: _phoneController.text.isEmpty ? null : _phoneController.text,
                age: int.parse(_ageController.text),
                assignedTeacherIds: ['teacher-001'],
                enrolledAt: DateTime.now(),
                isActive: true,
              );
              Navigator.pop(context, student);
            }
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}
