// 설명: 임시 계정 모델 (AWS 도입 전까지 사용)
// 주석: 한국어 / 로그: 영어

class Membership {
  final String academyId; // 학원 식별자
  final String role;      // owner | teacher | student

  const Membership({required this.academyId, required this.role});

  factory Membership.fromJson(Map<String, dynamic> j) =>
      Membership(academyId: j['academyId'] as String, role: j['role'] as String);

  Map<String, dynamic> toJson() => {'academyId': academyId, 'role': role};
}

class Account {
  final String id;
  final String name;
  final String username;
  final String password;   // 임시 환경이라 저장. (실서비스: 해시)
  final String? globalRole; // super_admin 등 (없을 수 있음)
  final List<Membership> memberships;

  const Account({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.memberships,
    this.globalRole,
  });

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        name: j['name'] as String,
        username: j['username'] as String,
        password: j['password'] as String,
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
        'globalRole': globalRole,
        'memberships': memberships.map((e) => e.toJson()).toList(),
      };
}
