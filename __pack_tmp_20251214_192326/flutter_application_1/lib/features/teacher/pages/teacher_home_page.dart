import 'package:flutter/material.dart';

/// 교사 홈 탭(스텁)
/// - 24-4에서 요약 카드(오늘 수업/임박 숙제 등) 연동 예정
class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('교사 홈')),
      body: const Center(
        child: Text(
          '홈(요약 위젯 예정)\n오늘 수업/임박 숙제/미평가 등을 표시합니다.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
