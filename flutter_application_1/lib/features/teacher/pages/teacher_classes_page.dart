import 'package:flutter/material.dart';

class TeacherClassesPage extends StatelessWidget {
  const TeacherClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('수업(시간표 조회/평가/숙제 발급)')),
      body: const Center(child: Text('Lesson timetable will be here (V23-2).')),
    );
  }
}
