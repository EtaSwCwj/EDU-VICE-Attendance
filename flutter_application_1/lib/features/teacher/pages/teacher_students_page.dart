import 'package:flutter/material.dart';

/// 학생 탭(스텁)
/// - 24-3에서 학생 목록/간단 필터 연결
class TeacherStudentsPage extends StatelessWidget {
  const TeacherStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('학생')),
      body: const Center(
        child: Text(
          '학생 목록(임시)\n필터/정렬/탭 간 이동은 이후 단계 반영',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
