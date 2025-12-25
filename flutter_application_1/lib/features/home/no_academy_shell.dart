// lib/features/home/no_academy_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../../shared/services/auth_state.dart';
import '../../models/ModelProvider.dart';
import '../../shared/services/invitation_service.dart';

/// 소속 학원이 없는 유저용 화면
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
    setState(() {
      _isLoading = true;
    });

    try {
      final auth = context.read<AuthState>();
      final user = auth.user;

      if (user?.email != null) {
        safePrint('[NoAcademyShell] 초대 목록 조회 시작: ${user!.email}');

        // 1. 초대 목록 조회
        final invitations = await InvitationService().getInvitationsByTargetEmail(user.email!);
        safePrint('[NoAcademyShell] 초대 목록 조회 완료: ${invitations.length}개');

        // 2. 각 초대의 Academy 정보 조회
        final academyNames = <String, String>{};
        for (final invitation in invitations) {
          if (invitation.academyId.isNotEmpty) {
            try {
              final request = ModelQueries.get(Academy.classType, AcademyModelIdentifier(id: invitation.academyId));
              final response = await Amplify.API.query(request: request).response;

              if (response.data != null) {
                academyNames[invitation.academyId] = response.data!.name;
                safePrint('[NoAcademyShell] Academy 조회 성공: ${response.data!.name}');
              }
            } catch (e) {
              safePrint('[NoAcademyShell] Academy 조회 실패: ${invitation.academyId}, $e');
            }
          }
        }

        setState(() {
          _invitations = invitations;
          _academyNames = academyNames;
        });

        safePrint('[NoAcademyShell] 초대 목록 로드 완료: ${_invitations.length}개, Academy 정보: ${_academyNames.length}개');
      }
    } catch (e) {
      safePrint('[NoAcademyShell] ERROR: 초대 목록 조회 실패 - $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptInvitation(Invitation invitation) async {
    safePrint('[NoAcademyShell] 초대 수락 클릭: ${invitation.id}');

    final auth = context.read<AuthState>();
    final user = auth.user;

    if (user == null) {
      safePrint('[NoAcademyShell] ERROR: 사용자 정보 없음');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자 정보를 찾을 수 없습니다.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      safePrint('[NoAcademyShell] 초대 수락 시작: user=${user.id}, academyId=${invitation.academyId}, role=${invitation.role}');

      // 1. AcademyMember 생성
      final academyMember = AcademyMember(
        userId: user.id,
        academyId: invitation.academyId,
        role: invitation.role,
      );

      final createMemberRequest = ModelMutations.create(academyMember);
      final createMemberResponse = await Amplify.API.mutate(request: createMemberRequest).response;

      if (createMemberResponse.data == null) {
        throw Exception('AcademyMember 생성 실패: ${createMemberResponse.errors}');
      }

      safePrint('[NoAcademyShell] AcademyMember 생성 성공: ${createMemberResponse.data!.id}');

      // 2. Invitation 업데이트 (상태를 accepted로 변경)
      final now = TemporalDateTime.now();
      final updatedInvitation = invitation.copyWith(
        status: 'accepted',
        usedAt: now,
        usedBy: user.id,
      );

      final updateInvitationRequest = ModelMutations.update(updatedInvitation);
      final updateInvitationResponse = await Amplify.API.mutate(request: updateInvitationRequest).response;

      if (updateInvitationResponse.data == null) {
        throw Exception('Invitation 업데이트 실패: ${updateInvitationResponse.errors}');
      }

      safePrint('[NoAcademyShell] Invitation 업데이트 성공: ${updateInvitationResponse.data!.id}, status=${updateInvitationResponse.data!.status}');

      // 3. 성공 처리
      safePrint('[NoAcademyShell] 초대 수락 완료: academyMember=${createMemberResponse.data!.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('초대를 수락했습니다. 학원 화면으로 이동합니다.'),
            backgroundColor: Colors.green,
          ),
        );

        // AuthState 새로고침하여 홈 화면으로 이동
        auth.refreshAuth();
      }

    } catch (e) {
      safePrint('[NoAcademyShell] ERROR: 초대 수락 실패 - $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('초대 수락 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectInvitation(Invitation invitation) async {
    safePrint('[NoAcademyShell] 초대 거절 클릭: ${invitation.id}');

    setState(() {
      _isLoading = true;
    });

    try {
      safePrint('[NoAcademyShell] 초대 거절 시작: invitation=${invitation.id}');

      // GraphQL Mutation으로 Invitation 업데이트 (상태를 rejected로 변경)
      final updatedInvitation = invitation.copyWith(
        status: 'rejected',
      );

      final updateInvitationRequest = ModelMutations.update(updatedInvitation);
      final updateInvitationResponse = await Amplify.API.mutate(request: updateInvitationRequest).response;

      if (updateInvitationResponse.data == null) {
        throw Exception('Invitation 업데이트 실패: ${updateInvitationResponse.errors}');
      }

      safePrint('[NoAcademyShell] Invitation 업데이트 성공: ${updateInvitationResponse.data!.id}, status=${updateInvitationResponse.data!.status}');

      // 성공 시: setState로 _invitations 리스트에서 해당 초대 제거
      setState(() {
        _invitations.removeWhere((inv) => inv.id == invitation.id);
        _isLoading = false;
      });

      safePrint('[NoAcademyShell] 초대 거절 완료: 리스트에서 제거됨');

      // SnackBar로 거절 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('초대를 거절했습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

    } catch (e) {
      safePrint('[NoAcademyShell] ERROR: 초대 거절 실패 - $e');

      // 실패 시: setState로 로딩 상태 false
      setState(() {
        _isLoading = false;
      });

      // SnackBar로 에러 메시지 표시
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
          // 새로고침 버튼 (멤버 등록 후 확인용)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              safePrint('[NoAcademyShell] 새로고침 버튼 클릭');
              auth.refreshAuth();
            },
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
                // 아이콘
                const Icon(
                  Icons.school_outlined,
                  size: 100,
                  color: Colors.grey,
                ),
                const SizedBox(height: 32),

                // 안내 문구
                Text(
                  '학원에 등록되지 않았습니다',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '학원 관리자에게 아래 정보를 알려주세요.\n등록 후 새로고침 버튼을 눌러주세요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // 이메일 표시 (핵심!)
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

                // QR 코드 (나중에 QR 스캔 기능용)
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 48),

                // 받은 초대 목록
                _buildInvitationsSection(),

                const SizedBox(height: 48),

                // 새로고침 버튼 (크게)
                FilledButton.icon(
                  onPressed: () {
                    safePrint('[NoAcademyShell] 새로고침 버튼 클릭');
                    auth.refreshAuth();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('등록 확인'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 도움말
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
        // 섹션 제목
        Text(
          '받은 초대',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // 로딩 중
        if (_isLoading)
          const CircularProgressIndicator()
        // 초대가 없는 경우
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
                Icon(
                  Icons.mail_outline,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  '받은 초대가 없습니다',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          )
        // 초대 목록
        else
          Column(
            children: _invitations.map((invitation) => _buildInvitationCard(invitation)).toList(),
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
            // 학원명
            Text(
              academyName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // 역할
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

            // 버튼들
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
