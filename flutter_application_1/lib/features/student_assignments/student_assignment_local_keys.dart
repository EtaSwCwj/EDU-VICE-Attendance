class StudentAssignmentLocalKeys {
  StudentAssignmentLocalKeys._();

  static const String submittedPrefix = 'student_assignment_submitted::';
  static const String submittedAtPrefix = 'student_assignment_submitted_at::';
  static const String notePrefix = 'student_assignment_note::';
  static const String attachmentPrefix = 'student_assignment_attachment::';

  static String submitted({
    required String studentUsername,
    required String assignmentId,
  }) {
    return '$submittedPrefix$studentUsername::$assignmentId';
  }

  static String submittedAt({
    required String studentUsername,
    required String assignmentId,
  }) {
    return '$submittedAtPrefix$studentUsername::$assignmentId';
  }

  static String note({
    required String studentUsername,
    required String assignmentId,
  }) {
    return '$notePrefix$studentUsername::$assignmentId';
  }

  static String attachment({
    required String studentUsername,
    required String assignmentId,
  }) {
    return '$attachmentPrefix$studentUsername::$assignmentId';
  }

  static List<String> all({
    required String studentUsername,
    required String assignmentId,
  }) {
    return <String>[
      submitted(studentUsername: studentUsername, assignmentId: assignmentId),
      submittedAt(studentUsername: studentUsername, assignmentId: assignmentId),
      note(studentUsername: studentUsername, assignmentId: assignmentId),
      attachment(studentUsername: studentUsername, assignmentId: assignmentId),
    ];
  }
}
