import 'package:flutter/material.dart';

/// 교사용 - 수업(Classes) 1차 스켈레톤
/// - 지금은 더미 UI만 제공 (목록/상세 구조 확인용)
/// - 다음 단계에서 실제 데이터 연동 및 라우팅 연결 예정
class TeacherClassesPage extends StatelessWidget {
  const TeacherClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes (Teacher)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(
            icon: Icons.event_note,
            title: '오늘 수업',
            subtitle: '당일 일정만 간략 확인',
          ),
          const SizedBox(height: 8),
          ...List.generate(
            3,
            (i) => _ClassTile(
              title: '수업 ${i + 1}',
              subtitle: '시간: 18:${(i * 10).toString().padLeft(2, '0')} ~ 19:${(i * 10 + 50).toString().padLeft(2, '0')}',
              students: ['student_test1', 'student_test2'],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.view_week,
            title: '주간 보기(더미)',
            subtitle: '주간 요약 영역 – 다음 단계에서 캘린더/표로 교체',
          ),
          const SizedBox(height: 8),
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: const Center(
              child: Text('주간 타임라인(placeholder)'),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('수업 추가 UI는 다음 단계에서 연결됩니다.')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('수업 추가'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Spacer(),
        if (subtitle != null)
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _ClassTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> students;

  const _ClassTile({
    required this.title,
    required this.subtitle,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.class_),
        title: Text(title),
        subtitle: Text('$subtitle\n학생: ${students.join(', ')}'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('“$title” 상세/편집은 다음 단계에서 구현')),
            );
          },
        ),
      ),
    );
  }
}
