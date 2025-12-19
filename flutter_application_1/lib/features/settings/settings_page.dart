import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../shared/services/auth_state.dart';
import '../../shared/services/mock_storage.dart';
import '../../shared/services/s3_storage_service.dart';
import '../../shared/widgets/profile_image_picker.dart';

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
}
