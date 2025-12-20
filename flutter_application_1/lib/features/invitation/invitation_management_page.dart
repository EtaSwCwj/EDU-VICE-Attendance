// lib/features/invitation/invitation_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../shared/services/invitation_service.dart';
import '../../models/ModelProvider.dart';

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
  final _invitationService = InvitationService();
  List<Invitation> _invitations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    safePrint('[InvitationManagementPage] Loading invitations');
    setState(() => _isLoading = true);

    final invitations = await _invitationService.getInvitationsByAcademy(widget.academyId);

    setState(() {
      _invitations = invitations;
      _isLoading = false;
    });
  }

  Future<void> _createInvitation(String role) async {
    safePrint('[InvitationManagementPage] Creating invitation for role: $role');

    try {
      final authUser = await Amplify.Auth.getCurrentUser();

      final invitation = await _invitationService.createInvitation(
        academyId: widget.academyId,
        role: role,
        createdBy: authUser.userId,
      );

      if (invitation != null && mounted) {
        _showInvitationCode(invitation);
        _loadInvitations();
      }
    } catch (e) {
      safePrint('[InvitationManagementPage] Error creating invitation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('초대 생성 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showInvitationCode(Invitation invitation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초대코드 생성 완료'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '역할: ${_getRoleName(invitation.role)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                invitation.inviteCode,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '유효기간: 7일',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: invitation.inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('코드가 복사되었습니다')),
              );
            },
            child: const Text('복사'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
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
        title: const Text('초대 관리'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInvitations,
              child: _invitations.isEmpty
                  ? const Center(child: Text('생성된 초대가 없습니다'))
                  : ListView.builder(
                      itemCount: _invitations.length,
                      itemBuilder: (context, index) {
                        final invitation = _invitations[index];
                        final isExpired = invitation.expiresAt
                            .getDateTimeInUtc()
                            .isBefore(DateTime.now().toUtc());
                        final isUsed = invitation.usedAt != null;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getRoleColor(invitation.role),
                              child: Text(
                                invitation.role[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              invitation.inviteCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            subtitle: Text(
                              '${_getRoleName(invitation.role)} • ${isUsed ? "사용됨" : isExpired ? "만료" : "유효"}',
                            ),
                            trailing: isUsed || isExpired
                                ? Icon(
                                    isUsed ? Icons.check_circle : Icons.cancel,
                                    color: isUsed ? Colors.green : Colors.red,
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: invitation.inviteCode),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('코드가 복사되었습니다'),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(),
        icon: const Icon(Icons.add),
        label: const Text('초대 생성'),
      ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초대 생성'),
        content: const Text('어떤 역할로 초대하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _createInvitation('teacher');
            },
            child: const Text('선생님'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _createInvitation('student');
            },
            child: const Text('학생'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
}
