import 'package:flutter/material.dart';

class TeacherStudentsPage extends StatelessWidget {
  const TeacherStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('학생')),
      body: const Center(child: Text('Student list & filters (V23-3).')),
    );
  }
}
