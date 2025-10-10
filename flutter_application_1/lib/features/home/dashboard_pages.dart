import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/services/auth_state.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return _Section(
      title: '원장 대시보드',
      subtitle: '학원: ${auth.academyName(auth.currentMembership!.academyId)}',
      bullets: const [
        '오늘 일정/수업 현황',
        '출석 요약(지각·결석)',
        '공지/알림 보낸 내역',
      ],
    );
  }
}

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return _Section(
      title: '선생 대시보드',
      subtitle: '학원: ${auth.academyName(auth.currentMembership!.academyId)}',
      bullets: const [
        '내 반 오늘의 출석 체크',
        '숙제 채점/미제출 목록',
        '공지 발송 바로가기',
      ],
    );
  }
}

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return _Section(
      title: '학생 홈',
      subtitle: '학원: ${auth.academyName(auth.currentMembership!.academyId)}',
      bullets: const [
        '오늘 수업 시간표',
        '출석 현황',
        '숙제 제출 현황',
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> bullets;

  const _Section({
    required this.title,
    this.subtitle,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 16),
        ...bullets.map((b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(child: Text(b)),
                ],
              ),
            )),
      ],
    );
  }
}
