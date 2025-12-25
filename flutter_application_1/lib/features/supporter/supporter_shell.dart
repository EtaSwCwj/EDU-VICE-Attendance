// lib/features/supporter/supporter_shell.dart
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../shared/services/student_supporter_service.dart';
import '../../shared/widgets/profile_avatar.dart';
import '../settings/settings_page.dart';

class SupporterShell extends StatefulWidget {
  const SupporterShell({super.key});

  @override
  State<SupporterShell> createState() => _SupporterShellState();
}

class _SupporterShellState extends State<SupporterShell> {
  int _currentIndex = 0;
  final _supporterService = StudentSupporterService();

  @override
  void initState() {
    super.initState();
    safePrint('[SupporterShell] 진입');
  }

  @override
  Widget build(BuildContext context) {
    safePrint('[SupporterShell] build - currentIndex: $_currentIndex');

    return Scaffold(
      appBar: AppBar(
        title: const Text('EDU-VICE'),
        actions: [
          GestureDetector(
            onTap: () {
              safePrint('[SupporterShell] 프로필 탭됨');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(role: 'supporter'),
                ),
              );
            },
            child: const ProfileAvatar(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomePage(),
          _buildStudentsPage(),
          const SettingsPage(role: 'supporter'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          safePrint('[SupporterShell] 탭 변경: $index');
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: '학생현황',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.family_restroom, size: 80, color: Colors.teal),
          const SizedBox(height: 16),
          Text(
            '서포터 홈',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '자녀의 학습 현황을 확인하세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsPage() {
    return FutureBuilder(
      future: _loadStudents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = snapshot.data ?? [];

        if (students.isEmpty) {
          return const Center(
            child: Text('연결된 학생이 없습니다'),
          );
        }

        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text('학생 ${index + 1}'),
                subtitle: const Text('학습 현황 보기'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  safePrint('[SupporterShell] 학생 탭됨: $index');
                  // TODO: 학생 상세 페이지로 이동
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<dynamic>> _loadStudents() async {
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      final students = await _supporterService.getStudentsBySupporter(authUser.userId);
      safePrint('[SupporterShell] 학생 로드: ${students.length}명');
      return students;
    } catch (e) {
      safePrint('[SupporterShell] 학생 로드 에러: $e');
      return [];
    }
  }
}
