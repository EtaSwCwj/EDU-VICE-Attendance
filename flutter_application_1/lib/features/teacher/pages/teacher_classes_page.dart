import 'package:flutter/material.dart';

/// 수업 탭(스텁)
/// - 24-2/3에서 실제 리스트/필터/페이지네이션 연동
class TeacherClassesPage extends StatelessWidget {
  const TeacherClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('수업')),
      body: const Center(
        child: Text(
          '수업 목록(임시)\n다음 단계에서 실데이터 연결',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
