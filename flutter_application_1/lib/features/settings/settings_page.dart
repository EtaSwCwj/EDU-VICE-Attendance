import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../shared/services/auth_state.dart';
import '../../shared/services/mock_storage.dart';
import '../../shared/services/s3_storage_service.dart';
import '../../shared/widgets/profile_image_picker.dart';
import '../../shared/utils/qr_token_util.dart';

class SettingsPage extends StatefulWidget {
  final String role;
  const SettingsPage({required this.role, super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final S3StorageService _storageService = S3StorageService();
  String? _profileImageUrl;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    safePrint('[SettingsPage] 진입');
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final auth = context.read<AuthState>();
    final userId = auth.user?.id;

    if (userId != null) {
      final url = await _storageService.getProfileImageUrl(userId);
      if (mounted) {
        setState(() {
          _profileImageUrl = url;
          _isLoadingImage = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
        // 프로필 이미지 및 사용자 정보
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              if (_isLoadingImage)
                const SizedBox(
                  width: 100,
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ProfileImagePicker(
                  currentImageUrl: _profileImageUrl,
                  userId: auth.user?.id ?? '',
                  size: 100,
                  editable: true,
                  onImageUploaded: (url) {
                    safePrint('[SettingsPage] 프로필 이미지 업로드 성공');
                    setState(() {
                      _profileImageUrl = url;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('프로필 사진이 업데이트되었습니다')),
                    );
                  },
                  onError: (msg) {
                    safePrint('[SettingsPage] ERROR: 프로필 이미지 업로드 실패 - $msg');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  },
                ),
              const SizedBox(height: 16),
              Text(
                auth.user?.name ?? '',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                _getRoleText(widget.role),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const Divider(),

        // 일반 설정
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '설정',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.qr_code),
          title: const Text('내 QR 코드'),
          subtitle: const Text('다른 사용자에게 내 정보를 공유할 수 있습니다'),
          onTap: () {
            safePrint('[SettingsPage] 버튼 클릭: 내 QR 코드');
            _showQRCodeDialog();
          },
        ),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('데이터 새로고침'),
          onTap: () async {
            safePrint('[SettingsPage] 버튼 클릭: 데이터 새로고침');
            await context.read<AuthState>().reloadFromStorage();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('데이터를 다시 불러왔습니다')),
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.folder_open),
          title: const Text('accounts.json 경로 보기'),
          onTap: () async {
            final path = await MockStorage.filePath();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('경로: $path')));
            }
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          onTap: () {
            safePrint('[SettingsPage] 버튼 클릭: 로그아웃');
            context.read<AuthState>().signOut();
          },
        ),
        ],
      ),
    );
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return '관리자';
      case 'owner':
        return '원장';
      case 'teacher':
        return '선생';
      case 'student':
        return '학생';
      default:
        return role;
    }
  }

  void _showQRCodeDialog() {
    final auth = context.read<AuthState>();
    final userId = auth.user?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 찾을 수 없습니다')),
      );
      return;
    }

    // QR 토큰 생성
    final token = QRTokenUtil.generateToken(userId);
    safePrint('[SettingsPage] QR 토큰 생성: $token');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('내 QR 코드'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: token,
                  version: QrVersions.auto,
                  size: 300.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                auth.user?.name ?? '',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _getRoleText(widget.role),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '이 QR 코드를 스캔하여\n내 정보를 공유할 수 있습니다',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }
}
