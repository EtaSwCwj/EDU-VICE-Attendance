import 'package:flutter/material.dart';
import '../../../auth/auth_service.dart';
import '../data/assignment_repository.dart';
import '../../../models/Assignment.dart';

/// 교사 홈: 오늘/임박 과제 요약(임시), 로그인/그룹 표기
class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  final _auth = const AuthService();
  final _repo = AssignmentRepository();

  String? _username;
  List<String> _groups = const [];
  List<Assignment> _latest = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final name = await _auth.getUsername();
      final groups = await _auth.getGroups();
      List<Assignment> items = const [];
      if (name != null) {
        items = await _repo.listByTeacher(teacherUsername: name, limit: 10);
      }
      if (!mounted) return;
      setState(() {
        _username = name;
        _groups = groups;
        _latest = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint('[TeacherHome] error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('교사 홈')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _bootstrap,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  Text('최근 과제(임시)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_latest.isEmpty)
                    const Text('No recent assignments.'),
                  ..._latest.map((a) => Card(
                        child: ListTile(
                          title: Text(a.title),
                          subtitle: Text('status: ${a.status.name}  •  student: ${a.studentUsername}'),
                        ),
                      )),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: ListTile(
        title: Text('Hello, ${_username ?? '-'}'),
        subtitle: Text('groups: ${_groups.isEmpty ? '-' : _groups.join(', ')}'),
        trailing: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await _auth.signOut();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
          },
        ),
      ),
    );
  }
}
