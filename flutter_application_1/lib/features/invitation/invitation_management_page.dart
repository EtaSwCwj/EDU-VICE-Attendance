// lib/features/invitation/invitation_management_page.dart
// 이름은 유지하지만 기능은 "멤버 직접 등록"으로 변경
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/ModelProvider.dart';
import '../../shared/services/academy_member_service.dart';
import '../../shared/services/auth_state.dart';
import '../../shared/utils/qr_token_util.dart';

class InvitationManagementPage extends StatefulWidget {
  final String academyId;

  const InvitationManagementPage({
    super.key,
    required this.academyId,
  });

  @override
  State<InvitationManagementPage> createState() => _InvitationManagementPageState();
}

class _InvitationManagementPageState extends State<InvitationManagementPage> {
  final _memberService = AcademyMemberService();
  final _emailController = TextEditingController();
  List<AcademyMember> _members = [];
  Map<String, AppUser?> _userCache = {};  // userId -> AppUser
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    safePrint('[InvitationManagementPage] Loading members');
    setState(() => _isLoading = true);

    try {
      final members = await _memberService.getMembersByAcademy(widget.academyId);
      
      // 각 멤버의 AppUser 정보 조회
      final userCache = <String, AppUser?>{};
      for (final member in members) {
        if (!userCache.containsKey(member.userId)) {
          const getUserQuery = '''
            query GetAppUser(\$id: ID!) {
              getAppUser(id: \$id) {
                id
                cognitoUsername
                name
                email
                profileImageUrl
              }
            }
          ''';

          final userResponse = await Amplify.API.query(
            request: GraphQLRequest<String>(
              document: getUserQuery,
              variables: {'id': member.userId},
            ),
          ).response;

          AppUser? foundUser;
          if (userResponse.data != null) {
            final userData = json.decode(userResponse.data!);
            final userJson = userData['getAppUser'];
            if (userJson != null) {
              foundUser = AppUser(
                id: userJson['id'],
                cognitoUsername: userJson['cognitoUsername'] ?? '',
                name: userJson['name'],
                email: userJson['email'],
                profileImageUrl: userJson['profileImageUrl'],
              );
            }
          }
          userCache[member.userId] = foundUser;
        }
      }

      setState(() {
        _members = members;
        _userCache = userCache;
        _isLoading = false;
      });
      
      safePrint('[InvitationManagementPage] Loaded ${members.length} members');
    } catch (e) {
      safePrint('[InvitationManagementPage] Error loading members: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addMember(String role, String targetEmail) async {
    safePrint('[InvitationManagementPage] Adding member: role=$role, email=$targetEmail');

    try {
      // 1. 이메일로 AppUser 조회 (API 사용 - 실시간 데이터)
      const listUsersQuery = '''
        query ListAppUsers(\$filter: ModelAppUserFilterInput) {
          listAppUsers(filter: \$filter) {
            items {
              id
              cognitoUsername
              name
              email
            }
          }
        }
      ''';

      final usersResponse = await Amplify.API.query(
        request: GraphQLRequest<String>(
          document: listUsersQuery,
          variables: {
            'filter': {
              'email': {'eq': targetEmail.toLowerCase()}
            }
          },
        ),
      ).response;

      if (usersResponse.data == null) {
        throw Exception('Failed to query users');
      }

      final usersJson = json.decode(usersResponse.data!);
      final usersList = usersJson['listAppUsers']['items'] as List;

      if (usersList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$targetEmail은(는) 가입되지 않은 사용자입니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final targetUserJson = usersList.first;
      final targetUserId = targetUserJson['id'] as String;
      final targetUserName = targetUserJson['name'] as String;
      safePrint('[InvitationManagementPage] Found user: $targetUserName (id: $targetUserId)');

      // 2. 이미 멤버인지 확인 (API 사용)
      const listMembersQuery = '''
        query ListAcademyMembers(\$filter: ModelAcademyMemberFilterInput) {
          listAcademyMembers(filter: \$filter) {
            items {
              id
            }
          }
        }
      ''';

      final membersResponse = await Amplify.API.query(
        request: GraphQLRequest<String>(
          document: listMembersQuery,
          variables: {
            'filter': {
              'academyId': {'eq': widget.academyId},
              'userId': {'eq': targetUserId}
            }
          },
        ),
      ).response;

      if (membersResponse.data != null) {
        final membersJson = json.decode(membersResponse.data!);
        final membersList = membersJson['listAcademyMembers']['items'] as List;

        if (membersList.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$targetEmail은(는) 이미 등록된 멤버입니다'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      // 3. AcademyMember 생성 (API 사용)
      const createMemberMutation = '''
        mutation CreateAcademyMember(\$input: CreateAcademyMemberInput!) {
          createAcademyMember(input: \$input) {
            id
            academyId
            userId
            role
          }
        }
      ''';

      final createResponse = await Amplify.API.mutate(
        request: GraphQLRequest<String>(
          document: createMemberMutation,
          variables: {
            'input': {
              'academyId': widget.academyId,
              'userId': targetUserId,
              'role': role,
            }
          },
        ),
      ).response;

      if (createResponse.data == null) {
        throw Exception('Failed to create member');
      }

      final createdMemberJson = json.decode(createResponse.data!);
      final memberId = createdMemberJson['createAcademyMember']['id'];
      safePrint('[InvitationManagementPage] Member created: $memberId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$targetUserName님을 ${_getRoleName(role)}(으)로 등록했습니다'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMembers();
      }
    } catch (e) {
      safePrint('[InvitationManagementPage] Error adding member: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('멤버 등록 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _searchUser() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일을 입력해주세요')),
      );
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 이메일 형식이 아닙니다')),
      );
      return;
    }

    safePrint('[InvitationManagementPage] Searching user: $email');

    // 로딩 시작
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // 1. 이메일로 AppUser 조회 (GraphQL API 사용 - 실시간 데이터)
      const listUsersQuery = '''
        query ListAppUsers(\$filter: ModelAppUserFilterInput) {
          listAppUsers(filter: \$filter) {
            items {
              id
              cognitoUsername
              name
              email
              profileImageUrl
            }
          }
        }
      ''';

      final usersResponse = await Amplify.API.query(
        request: GraphQLRequest<String>(
          document: listUsersQuery,
          variables: {
            'filter': {
              'email': {'eq': email.toLowerCase()}
            }
          },
        ),
      ).response;

      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.pop(context);

      if (usersResponse.data == null) {
        throw Exception('Failed to query users');
      }

      final usersJson = json.decode(usersResponse.data!);
      final usersList = usersJson['listAppUsers']['items'] as List;

      // 2. 사용자 존재 여부 확인
      if (usersList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$email은(는) 가입되지 않은 사용자입니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
        safePrint('[InvitationManagementPage] User not found: $email');
        return;
      }

      final targetUserJson = usersList.first;
      final targetUserId = targetUserJson['id'] as String;
      final targetUserName = targetUserJson['name'] as String;
      final targetUserEmail = targetUserJson['email'] as String;
      safePrint('[InvitationManagementPage] Found user: $targetUserName (id: $targetUserId)');

      // 3. 이미 멤버인지 확인
      final isAlreadyMember = _members.any((member) => member.userId == targetUserId);

      if (isAlreadyMember) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$targetUserName님은 이미 등록된 멤버입니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        safePrint('[InvitationManagementPage] User already member: $targetUserId');
        return;
      }

      // 4. 사용자 확인 다이얼로그 표시
      if (mounted) {
        // AppUser 객체 생성 (다이얼로그에 전달하기 위해)
        final user = AppUser(
          id: targetUserId,
          cognitoUsername: targetUserJson['cognitoUsername'] as String? ?? '',
          name: targetUserName,
          email: targetUserEmail,
          profileImageUrl: targetUserJson['profileImageUrl'] as String?,
        );

        _showUserConfirmationDialogFromSearch(user);
        _emailController.clear(); // 검색 성공 시 텍스트 필드 비우기
      }
    } catch (e) {
      safePrint('[InvitationManagementPage] Error searching user: $e');

      // 로딩 다이얼로그가 열려있다면 닫기
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사용자 검색 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'owner':
        return '원장';
      case 'teacher':
        return '선생님';
      case 'student':
        return '학생';
      case 'supporter':
        return '서포터';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.purple;
      case 'teacher':
        return Colors.blue;
      case 'student':
        return Colors.green;
      case 'supporter':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('멤버 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'QR 코드로 초대',
            onPressed: _showQRScanner,
          ),
        ],
      ),
      body: Column(
        children: [
          // 이메일 검색 영역
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: '이메일로 검색',
                      hintText: 'user@example.com',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchUser,
                  child: const Text('검색'),
                ),
              ],
            ),
          ),
          // 기존 멤버 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadMembers,
                    child: _members.isEmpty
                        ? const Center(child: Text('등록된 멤버가 없습니다'))
                        : ListView.builder(
                            itemCount: _members.length,
                            itemBuilder: (context, index) {
                              final member = _members[index];
                              final user = _userCache[member.userId];

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getRoleColor(member.role),
                                    child: Text(
                                      member.role[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    user?.name ?? '알 수 없음',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.email ?? member.userId,
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      Text(_getRoleName(member.role)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('멤버 추가'),
      ),
    );
  }

  void _showAddMemberDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('멤버 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이미 앱에 가입한 사용자만 추가할 수 있습니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                hintText: 'user@example.com',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('이메일을 입력해주세요')),
                );
                return;
              }
              if (!email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('올바른 이메일 형식이 아닙니다')),
                );
                return;
              }
              Navigator.pop(context);

              // 이메일로 AppUser 검색 후 확인 다이얼로그 표시
              await _searchAndShowConfirmDialog(email);
            },
            child: const Text('검색'),
          ),
        ],
      ),
    );
  }

  Future<void> _searchAndShowConfirmDialog(String email) async {
    safePrint('[InvitationManagementPage] 멤버 추가 다이얼로그에서 검색: $email');

    // 로딩 표시
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // 이메일로 AppUser 조회
      const listUsersQuery = '''
        query ListAppUsers(\$filter: ModelAppUserFilterInput) {
          listAppUsers(filter: \$filter) {
            items {
              id
              cognitoUsername
              name
              email
              profileImageUrl
            }
          }
        }
      ''';

      final usersResponse = await Amplify.API.query(
        request: GraphQLRequest<String>(
          document: listUsersQuery,
          variables: {
            'filter': {
              'email': {'eq': email.toLowerCase()}
            }
          },
        ),
      ).response;

      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.pop(context);

      if (usersResponse.data == null) {
        throw Exception('Failed to query users');
      }

      final usersJson = json.decode(usersResponse.data!);
      final usersList = usersJson['listAppUsers']['items'] as List;

      if (usersList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$email은(는) 가입되지 않은 사용자입니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final targetUserJson = usersList.first;

      // 이미 멤버인지 확인
      final targetUserId = targetUserJson['id'] as String;
      final isAlreadyMember = _members.any((member) => member.userId == targetUserId);

      if (isAlreadyMember) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${targetUserJson['name']}님은 이미 등록된 멤버입니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // AppUser 객체 생성
      final user = AppUser(
        id: targetUserId,
        cognitoUsername: targetUserJson['cognitoUsername'] as String? ?? '',
        name: targetUserJson['name'] as String,
        email: targetUserJson['email'] as String,
        profileImageUrl: targetUserJson['profileImageUrl'] as String?,
      );

      // 기존 확인 다이얼로그 재사용 (3버튼: 취소/초대 메일 발송/바로 추가)
      if (mounted) {
        _showUserConfirmationDialogFromSearch(user);
      }
    } catch (e) {
      safePrint('[InvitationManagementPage] 멤버 추가 검색 실패: $e');

      // 로딩 다이얼로그가 열려있다면 닫기
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사용자 검색 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showQRScanner() {
    safePrint('[InvitationManagementPage] 버튼 클릭: QR 스캔');

    final scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
    );

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('QR 코드 스캔'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                scannerController.dispose();
                Navigator.pop(context);
              },
            ),
          ),
          body: Stack(
            children: [
              MobileScanner(
                controller: scannerController,
                fit: BoxFit.contain,
                onDetect: (capture) async {
                  final List<Barcode> barcodes = capture.barcodes;

                  for (final barcode in barcodes) {
                    final String? code = barcode.rawValue;
                    if (code != null) {
                      safePrint('[InvitationManagementPage] QR 코드 스캔: $code');

                      // 토큰 복호화
                      final tokenData = QRTokenUtil.decryptToken(code);
                      if (tokenData != null && tokenData['userId'] != null) {
                        // 토큰 유효성 검증
                        if (!QRTokenUtil.isTokenValid(code)) {
                          if (mounted) {
                            scannerController.dispose();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('만료된 QR 코드입니다')),
                            );
                          }
                          return;
                        }

                        final userId = tokenData['userId'] as String;

                        // 사용자 정보 조회
                        try {
                          const getUserQuery = '''
                            query GetAppUser(\$id: ID!) {
                              getAppUser(id: \$id) {
                                id
                                cognitoUsername
                                name
                                email
                                profileImageUrl
                              }
                            }
                          ''';

                          final userResponse = await Amplify.API.query(
                            request: GraphQLRequest<String>(
                              document: getUserQuery,
                              variables: {'id': userId},
                            ),
                          ).response;

                          AppUser? foundUser;
                          if (userResponse.data != null) {
                            final userData = json.decode(userResponse.data!);
                            final userJson = userData['getAppUser'];
                            if (userJson != null) {
                              foundUser = AppUser(
                                id: userJson['id'],
                                cognitoUsername: userJson['cognitoUsername'] ?? '',
                                name: userJson['name'],
                                email: userJson['email'],
                                profileImageUrl: userJson['profileImageUrl'],
                              );
                            }
                          }

                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          scannerController.dispose();
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);

                          if (foundUser != null) {
                            _showUserConfirmationDialog(foundUser);
                          } else {
                            if (!mounted) return;
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('사용자를 찾을 수 없습니다')),
                            );
                          }
                        } catch (e) {
                          safePrint('[InvitationManagementPage] ERROR: QR 사용자 조회 실패 - $e');
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          scannerController.dispose();
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('사용자 정보 조회에 실패했습니다')),
                          );
                        }
                        return;
                      } else {
                        safePrint('[InvitationManagementPage] 잘못된 QR 코드');
                      }
                    }
                  }
                },
              ),
              // 가이드라인 오버레이
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // 가이드 텍스트
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Text(
                  'QR 코드를 프레임 안에 맞춰주세요',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Color.fromRGBO(0, 0, 0, 0.7),
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserConfirmationDialog(AppUser user) {
    String selectedRole = 'student';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('사용자 초대'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${user.name}님을 초대하시겠습니까?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text('역할 선택'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'teacher', label: Text('선생님')),
                  ButtonSegment(value: 'student', label: Text('학생')),
                ],
                selected: {selectedRole},
                onSelectionChanged: (Set<String> selection) {
                  setDialogState(() {
                    selectedRole = selection.first;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _sendInvitationEmail(user, selectedRole);
              },
              child: const Text('초대 메일 발송'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _addMember(selectedRole, user.email);
              },
              child: const Text('바로 추가'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInvitationEmail(AppUser user, String role) async {
    safePrint('[InvitationManagementPage] 초대 메일 발송: user=${user.name}, role=$role');

    try {
      // 1. 이미 멤버인지 확인 (GraphQL API)
      const listMembersQuery = '''
        query ListAcademyMembers(\$filter: ModelAcademyMemberFilterInput) {
          listAcademyMembers(filter: \$filter) {
            items {
              id
            }
          }
        }
      ''';

      final membersResponse = await Amplify.API.query(
        request: GraphQLRequest<String>(
          document: listMembersQuery,
          variables: {
            'filter': {
              'academyId': {'eq': widget.academyId},
              'userId': {'eq': user.id}
            }
          },
        ),
      ).response;

      if (membersResponse.data != null) {
        final membersJson = json.decode(membersResponse.data!);
        final membersList = membersJson['listAcademyMembers']['items'] as List;

        if (membersList.isNotEmpty) {
          safePrint('[InvitationManagementPage] 이미 등록된 멤버: ${user.email}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${user.name}님은 이미 등록된 멤버입니다'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      // 2. 현재 사용자 정보 가져오기
      if (!mounted) return;
      final authState = context.read<AuthState>();
      final currentUser = authState.user;

      if (currentUser == null) {
        throw Exception('현재 사용자 정보를 가져올 수 없습니다');
      }

      // Invitation 레코드 생성
      final inviteCode = const Uuid().v4();
      final expiresAt = TemporalDateTime(
        DateTime.now().add(const Duration(days: 7)),
      );


      // Invitation 생성 (GraphQL API 사용, DynamoDB 스트림이 Lambda 트리거를 자동 호출)
      const createInvitationMutation = '''
        mutation CreateInvitation(\$input: CreateInvitationInput!) {
          createInvitation(input: \$input) {
            id
            academyId
            inviterUserId
            inviteeEmail
            inviteeUserId
            role
            status
            inviteCode
            expiresAt
          }
        }
      ''';

      final createResponse = await Amplify.API.mutate(
        request: GraphQLRequest<String>(
          document: createInvitationMutation,
          variables: {
            'input': {
              'academyId': widget.academyId,
              'inviterUserId': currentUser.id,
              'inviteeEmail': user.email,
              'inviteeUserId': user.id,
              'role': role,
              'status': 'pending',
              'inviteCode': inviteCode,
              'expiresAt': expiresAt.format(),
            }
          },
        ),
      ).response;

      if (createResponse.data == null) {
        throw Exception('Failed to create invitation');
      }

      final createdInvitationJson = json.decode(createResponse.data!);
      final invitationId = createdInvitationJson['createInvitation']['id'];
      safePrint('[InvitationManagementPage] Invitation API 생성 성공: code=$inviteCode, id=$invitationId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('초대 메일이 발송되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      safePrint('[InvitationManagementPage] ERROR: 초대 메일 발송 실패 - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('초대 메일 발송 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserConfirmationDialogFromSearch(AppUser user) {
    String selectedRole = 'student';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('사용자 확인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '다음 사용자를 멤버로 추가하시겠습니까?',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                '이름: ${user.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                '이메일: ${user.email}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              const Text('역할 선택'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'teacher', label: Text('선생님')),
                  ButtonSegment(value: 'student', label: Text('학생')),
                ],
                selected: {selectedRole},
                onSelectionChanged: (Set<String> selection) {
                  setDialogState(() {
                    selectedRole = selection.first;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _sendInvitationEmail(user, selectedRole);
              },
              child: const Text('초대 메일 발송'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                // 바로 멤버 추가 (초대 단계 없이)
                _addMember(selectedRole, user.email);
              },
              child: const Text('바로 추가'),
            ),
          ],
        ),
      ),
    );
  }
}
