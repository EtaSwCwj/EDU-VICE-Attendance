import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/s3_storage_service.dart';

/// 프로필 이미지 선택 및 업로드 위젯
class ProfileImagePicker extends StatefulWidget {
  /// 현재 프로필 이미지 URL (S3 URL)
  final String? currentImageUrl;

  /// 사용자 ID (S3 경로에 사용)
  final String userId;

  /// 업로드 완료 시 콜백 (새 URL 전달)
  final ValueChanged<String>? onImageUploaded;

  /// 업로드 에러 시 콜백
  final ValueChanged<String>? onError;

  /// 이미지 크기 (기본 100)
  final double size;

  /// 편집 가능 여부
  final bool editable;

  const ProfileImagePicker({
    super.key,
    this.currentImageUrl,
    required this.userId,
    this.onImageUploaded,
    this.onError,
    this.size = 100,
    this.editable = true,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  final S3StorageService _storageService = S3StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploading = false;
  String? _displayImageUrl;

  @override
  void initState() {
    super.initState();
    _displayImageUrl = widget.currentImageUrl;
  }

  @override
  void didUpdateWidget(ProfileImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentImageUrl != widget.currentImageUrl) {
      _displayImageUrl = widget.currentImageUrl;
    }
  }

  Future<void> _showImageSourceDialog() async {
    if (!widget.editable || _isUploading) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('취소'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickAndUploadImage(source);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        return;
      }

      setState(() {
        _isUploading = true;
      });

      final file = File(pickedFile.path);
      final uploadedUrl = await _storageService.uploadProfileImage(
        widget.userId,
        file,
      );

      if (!mounted) return;

      if (uploadedUrl != null) {
        setState(() {
          _displayImageUrl = uploadedUrl;
          _isUploading = false;
        });
        widget.onImageUploaded?.call(uploadedUrl);
      } else {
        setState(() {
          _isUploading = false;
        });
        widget.onError?.call('이미지 업로드에 실패했습니다.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
      widget.onError?.call('이미지 선택 중 오류가 발생했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.editable ? _showImageSourceDialog : null,
      child: Stack(
        children: [
          // 프로필 이미지
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _buildImage(),
            ),
          ),

          // 업로드 중 로딩 표시
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),

          // 편집 아이콘
          if (widget.editable && !_isUploading)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: widget.size * 0.2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (_displayImageUrl != null && _displayImageUrl!.isNotEmpty) {
      return Image.network(
        _displayImageUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.size,
      height: widget.size,
      color: Colors.grey[200],
      child: Icon(
        Icons.person,
        size: widget.size * 0.5,
        color: Colors.grey[400],
      ),
    );
  }
}
