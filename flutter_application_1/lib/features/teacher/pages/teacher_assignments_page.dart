import 'package:flutter/material.dart';
import '../../../auth/auth_service.dart';
import '../data/assignment_repository.dart';
import '../../../models/ModelProvider.dart';

class TeacherAssignmentsPage extends StatefulWidget {
  const TeacherAssignmentsPage({super.key});

  @override
  State<TeacherAssignmentsPage> createState() => _TeacherAssignmentsPageState();
}

class _TeacherAssignmentsPageState extends State<TeacherAssignmentsPage> {
  final _auth = const AuthService();
  final _repo = AssignmentRepository();

  bool _loading = true;
  String? _username;
  List<Assignment> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final u = await _auth.getUsername();
      List<Assignment> items = const [];
      if (u != null) {
        items = await _repo.listByTeacher(teacherUsername: u, limit: 100);
      }
      if (!mounted) return;
      setState(() {
        _username = u;
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint('[TeacherAssignments] error: $e');
    }
  }

  Future<void> _markDone(Assignment a) async {
    final updated = await _repo.updateStatus(assignment: a, status: AssignmentStatus.DONE);
    if (!mounted) return;
    setState(() {
      _items = _items.map((e) => e.id == updated.id ? updated : e).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as DONE')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('숙제 — ${_username ?? '-'}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final a = _items[i];
                  return Card(
                    child: ListTile(
                      title: Text(a.title),
                      subtitle: Text('student: ${a.studentUsername}  •  status: ${a.status.name}'),
                      trailing: (a.status != AssignmentStatus.DONE)
                          ? IconButton(
                              icon: const Icon(Icons.check_circle_outline),
                              onPressed: () => _markDone(a),
                            )
                          : const Icon(Icons.check_circle, color: Colors.green),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
