import 'dart:io';
import 'dart:typed_data';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:image/image.dart' as img;

/// S3 스토리지 서비스
/// 프로필 이미지 업로드 및 관리
class S3StorageService {
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int targetImageSize = 512; // 512x512
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png'];

  /// 프로필 이미지 업로드
  /// [userId] 사용자 ID
  /// [imageFile] 업로드할 이미지 파일
  /// 반환: S3 URL 또는 에러 시 null
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      // 1. 파일 크기 확인
      final fileSize = await imageFile.length();
      if (fileSize > maxFileSizeBytes) {
        safePrint('[S3StorageService] ERROR: 파일 크기 초과 (${fileSize ~/ 1024}KB > 5MB)');
        return null;
      }

      // 2. 파일 확장자 확인
      final extension = imageFile.path.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        safePrint('[S3StorageService] ERROR: 허용되지 않는 확장자 ($extension)');
        return null;
      }

      // 3. 이미지 리사이즈
      final resizedBytes = await _resizeImage(imageFile);
      if (resizedBytes == null) {
        safePrint('[S3StorageService] ERROR: 이미지 리사이즈 실패');
        return null;
      }

      // 4. S3 업로드 경로
      final s3Key = 'profiles/$userId/profile.jpg';

      // 5. S3 업로드
      final result = await Amplify.Storage.uploadData(
        data: StorageDataPayload.bytes(resizedBytes),
        path: StoragePath.fromString('public/$s3Key'),
        options: const StorageUploadDataOptions(
          metadata: {'content-type': 'image/jpeg'},
        ),
      ).result;

      safePrint('[S3StorageService] 업로드 성공: ${result.uploadedItem.path}');

      // 6. URL 생성
      final urlResult = await Amplify.Storage.getUrl(
        path: StoragePath.fromString('public/$s3Key'),
        options: const StorageGetUrlOptions(
          pluginOptions: S3GetUrlPluginOptions(
            expiresIn: Duration(days: 7),
          ),
        ),
      ).result;

      return urlResult.url.toString();
    } on StorageException catch (e) {
      safePrint('[S3StorageService] ERROR: StorageException - ${e.message}');
      return null;
    } catch (e) {
      safePrint('[S3StorageService] ERROR: $e');
      return null;
    }
  }

  /// 이미지 리사이즈 (512x512, JPEG)
  Future<Uint8List?> _resizeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return null;
      }

      // 정사각형으로 크롭 (중앙 기준)
      final shortestSide = image.width < image.height ? image.width : image.height;
      final xOffset = (image.width - shortestSide) ~/ 2;
      final yOffset = (image.height - shortestSide) ~/ 2;

      final cropped = img.copyCrop(
        image,
        x: xOffset,
        y: yOffset,
        width: shortestSide,
        height: shortestSide,
      );

      // 512x512로 리사이즈
      final resized = img.copyResize(
        cropped,
        width: targetImageSize,
        height: targetImageSize,
        interpolation: img.Interpolation.linear,
      );

      // JPEG으로 인코딩 (품질 85%)
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (e) {
      safePrint('[S3StorageService] ERROR: 이미지 처리 실패 - $e');
      return null;
    }
  }

  /// 프로필 이미지 URL 가져오기
  Future<String?> getProfileImageUrl(String userId) async {
    try {
      final s3Key = 'profiles/$userId/profile.jpg';
      final result = await Amplify.Storage.getUrl(
        path: StoragePath.fromString('public/$s3Key'),
        options: const StorageGetUrlOptions(
          pluginOptions: S3GetUrlPluginOptions(
            expiresIn: Duration(days: 7),
          ),
        ),
      ).result;

      return result.url.toString();
    } on StorageException catch (e) {
      safePrint('[S3StorageService] getProfileImageUrl ERROR: ${e.message}');
      return null;
    } catch (e) {
      safePrint('[S3StorageService] getProfileImageUrl ERROR: $e');
      return null;
    }
  }

  /// 프로필 이미지 삭제
  Future<bool> deleteProfileImage(String userId) async {
    try {
      final s3Key = 'profiles/$userId/profile.jpg';
      await Amplify.Storage.remove(
        path: StoragePath.fromString('public/$s3Key'),
      ).result;

      safePrint('[S3StorageService] 삭제 성공: $s3Key');
      return true;
    } on StorageException catch (e) {
      safePrint('[S3StorageService] deleteProfileImage ERROR: ${e.message}');
      return false;
    } catch (e) {
      safePrint('[S3StorageService] deleteProfileImage ERROR: $e');
      return false;
    }
  }
}
