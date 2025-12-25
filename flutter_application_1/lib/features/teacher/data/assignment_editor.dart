import '../../../models/Assignment.dart';
import '../../../models/AssignmentStatus.dart';
import 'assignment_repository.dart';

class AssignmentEditor {
  final AssignmentRepository _repo;
  AssignmentEditor(this._repo);

  Future<void> updateStatus({
    required Assignment assignment,
    required AssignmentStatus nextStatus,
  }) async {
    await _repo.updateAssignmentStatus(id: assignment.id, status: nextStatus);
  }

  Future<void> deleteById(String id) async {
    await _repo.deleteAssignment(id);
  }
}
