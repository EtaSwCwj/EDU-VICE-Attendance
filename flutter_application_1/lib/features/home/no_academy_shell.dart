import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:go_router/go_router.dart';
import '../../shared/services/auth_state.dart';
import '../../models/ModelProvider.dart';
import '../../shared/services/invitation_service.dart';

class NoAcademyShell extends StatefulWidget {
  const NoAcademyShell({super.key});

  @override
  State<NoAcademyShell> createState() => _NoAcademyShellState();
}

class _NoAcademyShellState extends State<NoAcademyShell> {
  List<Invitation> _invitations = [];
  bool _isLoading = false;
  Map<String, String> _academyNames = {};

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthState>();
      final user = auth.user;

      if (user?.email != null) {
        final invitations = await InvitationService().getInvitationsByTargetEmail(user!.email!);

        final academyNames = <String, String>{};
        for (final invitation in invitations) {
          if (invitation.academyId.isNotEmpty) {
            try {
              final request = ModelQueries.get(Academy.classType, AcademyModelIdentifier(id: invitation.academyId));
              final response = await Amplify.API.query(request: request).response;
              if (response.data != null) {
                academyNames[invitation.academyId] = response.data!.name;
              }
            } catch (_) {}
          }
        }

        setState(() {
          _invitations = invitations;
          _academyNames = academyNames;
        });
      }
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  Future<void> _acceptInvitation(Invitation invitation) async {
    safePrint('[LOG] 수락 버튼 클릭');

    final auth = context.read<AuthState>();
    final user = auth.user;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자 정보를 찾을 수 없습니다.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Invitation 업데이트
      final now = TemporalDateTime.now();

      const updateMutation = '''
        mutation UpdateInvitation(\$id: ID!, \$status: String!, \$usedAt: AWSDateTime!, \$usedBy: ID!) {
          updateInvitation(input: {
            id: \$id
            status: \$status
            usedAt: \$usedAt
            usedBy: \$usedBy
          }) {
            id
            status
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: updateMutation,
        variables: {
          'id': invitation.id,
          'status': 'accepted',
          'usedAt': now.format(),
          'usedBy': user.id,
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        throw Exception('Invitation 업데이트 실패');
      }

      safePrint('[LOG] Invitation 업데이트 완료');

      // 2. Lambda 완료 대기 (2초)
      safePrint('[LOG] Lambda 완료 대기 중...');
      await Future.delayed(const Duration(seconds: 2));

      // 3. 재로그인 안내 후 로그인 화면으로 이동
      safePrint('[LOG] 초대 수락 완료 → 로그인 화면으로 이동');

      if (mounted) {
        // 로그아웃
        await auth.signOut();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('초대를 수락했습니다! 다시 로그인해주세요.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        context.go('/login');
      }

    } catch (e) {
      safePrint('[LOG] 수락 실패: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('초대 수락 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectInvitation(Invitation invitation) async {
    safePrint('[LOG] 거절 버튼 클릭');

    setState(() => _isLoading = true);

    try {
      final updatedInvitation = invitation.copyWith(status: 'rejected');
      final request = ModelMutations.update(updatedInvitation);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.data == null) {
        throw Exception('Invitation 업데이트 실패');
      }

      setState(() {
        _invitations.removeWhere((inv) => inv.id == invitation.id);
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('초대를 거절했습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

    } catch (e) {
      safePrint('[LOG] 거절 실패: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('초대 거절 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EDU-VICE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => auth.refreshAuth(),
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school_outlined, size: 100, color: Colors.grey),
                const SizedBox(height: 32),
                Text(
                  '학원에 등록되지 않았습니다',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '학원 관리자에게 아래 정보를 알려주세요.\n등록 후 새로고침 버튼을 눌러주세요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                if (user != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '내 이메일',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email ?? '이메일 없음',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                if (user != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: user.email ?? user.id,
                          version: QrVersions.auto,
                          size: 150.0,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 48),

                _buildInvitationsSection(),

                const SizedBox(height: 48),

                FilledButton.icon(
                  onPressed: () => auth.refreshAuth(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('등록 확인'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('도움말'),
                        content: const Text(
                          '학원에 등록하려면:\n\n'
                          '1. 학원 관리자에게 위의 이메일을 알려주세요.\n'
                          '2. 관리자가 등록하면 완료됩니다.\n'
                          '3. "등록 확인" 버튼을 눌러 확인하세요.\n\n'
                          '등록이 완료되면 자동으로 학원 화면으로 이동합니다.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('도움말'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationsSection() {
    return Column(
      children: [
        Text(
          '받은 초대',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          const CircularProgressIndicator()
        else if (_invitations.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.mail_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  '받은 초대가 없습니다',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else
          Column(
            children: _invitations.map((inv) => _buildInvitationCard(inv)).toList(),
          ),
      ],
    );
  }

  Widget _buildInvitationCard(Invitation invitation) {
    final academyName = _academyNames[invitation.academyId] ?? '학원명 조회 중...';
    final roleText = _getRoleDisplayText(invitation.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              academyName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                roleText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectInvitation(invitation),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('거절'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _acceptInvitation(invitation),
                    child: const Text('수락'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayText(String? role) {
    switch (role) {
      case 'OWNER':
        return '원장';
      case 'TEACHER':
        return '강사';
      case 'STUDENT':
        return '학생';
      default:
        return '역할 미지정';
    }
  }
}
