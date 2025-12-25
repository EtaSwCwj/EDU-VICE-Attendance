/// 역할별 권한 체크 서비스
class PermissionService {
  const PermissionService();

  /// 학생 생성 권한 (Owner만)
  static bool canCreateStudent(String? role) {
    return role == 'owner';
  }

  /// 학생 삭제 권한 (Owner만)
  static bool canDeleteStudent(String? role) {
    return role == 'owner';
  }

  /// 선생 생성 권한 (Owner만)
  static bool canCreateTeacher(String? role) {
    return role == 'owner';
  }

  /// 선생 삭제 권한 (Owner만)
  static bool canDeleteTeacher(String? role) {
    return role == 'owner';
  }

  /// 선생-학생 배정 권한 (Owner만)
  static bool canAssignStudent(String? role) {
    return role == 'owner';
  }

  /// 전체 학생 조회 권한 (Owner만)
  static bool canViewAllStudents(String? role) {
    return role == 'owner';
  }

  /// 전체 선생 조회 권한 (Owner만)
  static bool canViewAllTeachers(String? role) {
    return role == 'owner';
  }

  /// Owner 권한인지 확인
  static bool isOwner(String? role) {
    return role == 'owner';
  }

  /// Teacher 권한인지 확인
  static bool isTeacher(String? role) {
    return role == 'teacher';
  }

  /// Student 권한인지 확인
  static bool isStudent(String? role) {
    return role == 'student';
  }
}
