// lib/features/invitation/join_by_code_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../shared/services/invitation_service.dart';
import '../../shared/services/academy_member_service.dart';
import '../../shared/services/student_supporter_service.dart';

class JoinByCodePage extends StatefulWidget {
  const JoinByCodePage({super.key});

  @override
  State<JoinByCodePage> createState() => _JoinByCodePageState();
}

class _JoinByCodePageState extends State<JoinByCodePage> {
  final _codeController = TextEditingController();
  final _invitationService = InvitationService();
  final _memberService = AcademyMemberService();
  final _supporterService = StudentSupporterService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinWithCode() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.length != 6) {
      setState(() => _errorMessage = '6자리 코드를 입력해주세요');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    safePrint('[JoinByCodePage] Attempting to join with code: $code');

    try {
      // 1. 초대 조회
      final invitation = await _invitationService.getInvitationByCode(code);

      if (invitation == null) {
        setState(() {
          _errorMessage = '유효하지 않거나 만료된 초대코드입니다';
          _isLoading = false;
        });
        return;
      }

      // 2. 현재 유저 정보 가져오기
      final authUser = await Amplify.Auth.getCurrentUser();
      final userId = authUser.userId;

      safePrint('[JoinByCodePage] Current user: $userId, invitation role: ${invitation.role}');

      // 3. 역할에 따라 처리
      if (invitation.role == 'supporter') {
        // 서포터인 경우: StudentSupporter 생성
        if (invitation.targetStudentId == null) {
          setState(() {
            _errorMessage = '잘못된 서포터 초대입니다';
            _isLoading = false;
          });
          return;
        }

        final supporter = await _supporterService.createSupporter(
          studentMemberId: invitation.targetStudentId!,
          supporterUserId: userId,
          academyId: invitation.academyId,
        );

        if (supporter == null) {
          setState(() {
            _errorMessage = '서포터 등록에 실패했습니다 (최대 2명 제한)';
            _isLoading = false;
          });
          return;
        }
      } else {
        // 일반 역할인 경우: AcademyMember 생성
        final member = await _memberService.createMemberFromInvitation(
          invitation: invitation,
          userId: userId,
        );

        if (member == null) {
          setState(() {
            _errorMessage = '학원 등록에 실패했습니다';
            _isLoading = false;
          });
          return;
        }
      }

      // 4. 초대 사용 처리
      await _invitationService.useInvitation(
        invitation: invitation,
        userId: userId,
      );

      safePrint('[JoinByCodePage] Successfully joined!');

      // 5. 홈으로 이동
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getRoleName(invitation.role)}(으)로 등록되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      safePrint('[JoinByCodePage] Error: $e');
      setState(() {
        _errorMessage = '오류가 발생했습니다: $e';
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          safePrint('[JoinByCodePage] 안드로이드 백 버튼 클릭');
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('초대코드 입력'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              safePrint('[JoinByCodePage] 뒤로가기 버튼 클릭');
              context.go('/home');
            },
          ),
        ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.qr_code,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              '초대코드를 입력해주세요',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '원장님 또는 선생님에게 받은 6자리 코드를 입력하세요',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: 'ABC123',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _errorMessage,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                UpperCaseTextFormatter(),
              ],
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _joinWithCode,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('참여하기', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// 대문자 변환 포매터
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
