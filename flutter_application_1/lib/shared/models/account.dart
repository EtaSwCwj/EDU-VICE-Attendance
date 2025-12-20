class Membership {
  final String academyId;
  final String role; // owner | teacher | student

  const Membership({required this.academyId, required this.role});

  factory Membership.fromJson(Map<String, dynamic> j) =>
      Membership(academyId: j['academyId'] as String, role: j['role'] as String);

  Map<String, dynamic> toJson() => {'academyId': academyId, 'role': role};

  // ===== 값 비교 추가 =====
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Membership &&
          runtimeType == other.runtimeType &&
          academyId == other.academyId &&
          role == other.role;

  @override
  int get hashCode => Object.hash(academyId, role);

  @override
  String toString() => 'Membership($academyId, $role)';
}

class Account {
  final String id;
  final String name;
  final String username;
  final String password;   // 임시 환경: 평문 (실서비스에선 해시)
  final String? email;     // 이메일 추가
  final String? globalRole; // super_admin 등
  final List<Membership> memberships;

  const Account({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.memberships,
    this.email,
    this.globalRole,
  });

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        name: j['name'] as String,
        username: j['username'] as String,
        password: j['password'] as String,
        email: j['email'] as String?,
        globalRole: j['globalRole'] as String?,
        memberships: (j['memberships'] as List? ?? [])
            .map((e) => Membership.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'password': password,
        'email': email,
        'globalRole': globalRole,
        'memberships': memberships.map((e) => e.toJson()).toList(),
      };
}
