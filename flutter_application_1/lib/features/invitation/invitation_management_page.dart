// lib/features/invitation/invitation_management_page.dart
// 이름은 유지하지만 기능은 "멤버 직접 등록"으로 변경
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../models/ModelProvider.dart';
import '../../shared/services/academy_member_service.dart';

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
  List<AcademyMember> _members = [];
  Map<String, AppUser?> _userCache = {};  // userId -> AppUser
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
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
          final users = await Amplify.DataStore.query(
            AppUser.classType,
            where: AppUser.ID.eq(member.userId),
          );
          userCache[member.userId] = users.isNotEmpty ? users.first : null;
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
      ),
      body: _isLoading
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('멤버 추가'),
      ),
    );
  }

  void _showAddMemberDialog() {
    final emailController = TextEditingController();
    String selectedRole = 'student';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
              // 이메일 입력
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  hintText: 'user@example.com',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // 역할 선택
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
            FilledButton(
              onPressed: () {
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
                _addMember(selectedRole, email);
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }
}
