import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_state.dart';
import '../services/s3_storage_service.dart';

/// AppBar용 프로필 아바타 위젯
/// 탭하면 설정 페이지로 이동
class ProfileAvatar extends StatefulWidget {
  final double size;

  const ProfileAvatar({
    super.key,
    this.size = 32,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  final S3StorageService _storageService = S3StorageService();
  String? _profileImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final userName = auth.user?.name ?? '';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          final role = auth.currentMembership?.role ?? 'student';
          context.push('/settings/$role');
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primaryContainer,
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: _buildContent(initial),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(String initial) {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: widget.size * 0.5,
          height: widget.size * 0.5,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return Image.network(
        _profileImageUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildInitial(initial);
        },
      );
    }

    return _buildInitial(initial);
  }

  Widget _buildInitial(String initial) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: widget.size * 0.45,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
