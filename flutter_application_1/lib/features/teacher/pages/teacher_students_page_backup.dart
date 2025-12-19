import 'package:flutter/material.dart';

/// 교사용 - 학생(Students) 1차 스켈레톤
/// - 검색/필터, 학생 카드, 상세 이동 버튼만 더미로 구성
/// - 실제 쿼리/라우팅은 다음 단계에서 연결
class TeacherStudentsPage extends StatefulWidget {
  const TeacherStudentsPage({super.key});

  @override
  State<TeacherStudentsPage> createState() => _TeacherStudentsPageState();
}

class _TeacherStudentsPageState extends State<TeacherStudentsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final items = _dummyStudents
        .where((s) => _query.isEmpty || s.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students (Teacher)'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '학생 검색 (이름)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: items.length,
              itemBuilder: (context, i) => _StudentCard(student: items[i]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'teacher_students_backup_fab',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('학생 추가 UI는 다음 단계에서 연결됩니다.')),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('학생 추가'),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final _Student student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Text(student.name.characters.first)),
        title: Text(student.name),
        subtitle: Text('진도: ${student.progress}% · 최근 과제: ${student.lastAssignment ?? "-"}'),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('“${student.name}” 상세/숙제/평가 화면은 다음 단계에서 이동')),
            );
          },
        ),
      ),
    );
  }
}

class _Student {
  final String name;
  final int progress;
  final String? lastAssignment;

  const _Student(this.name, this.progress, this.lastAssignment);
}

const _dummyStudents = <_Student>[
  _Student('student_test1', 42, '연산 1-10'),
  _Student('student_test2', 75, '독해 3단원'),
  _Student('student_test3', 10, null),
  _Student('student_test4', 88, '도형 영역'),
];
