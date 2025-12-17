import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

/// S3 스토리지 서비스
/// 답안지 이미지 등 파일 업로드/다운로드 담당
class StorageService {
  const StorageService();

  /// 파일 업로드 (일반)
  /// [s3Path] S3 경로 (예: 'answers/chapter-001/image.jpg')
  /// [file] 업로드할 파일
  /// 반환: S3 키
  Future<String?> uploadFile({
    required String s3Path,
    required File file,
  }) async {
    try {
      final result = await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(file.path),
        path: StoragePath.fromString(s3Path),
        onProgress: (progress) {
          final percent = (progress.fractionCompleted * 100).toStringAsFixed(1);
          safePrint('[StorageService] 업로드 진행: $percent%');
        },
      ).result;

      safePrint('[StorageService] 업로드 완료: ${result.uploadedItem.path}');
      return result.uploadedItem.path;
    } on StorageException catch (e) {
      safePrint('[StorageService] ERROR: 업로드 실패 - ${e.message}');
      return null;
    } catch (e) {
      safePrint('[StorageService] ERROR: 업로드 실패 - $e');
      return null;
    }
  }

  /// 파일 다운로드 URL 가져오기
  /// [s3Key] S3 키
  /// 반환: 다운로드 URL (유효기간 1시간)
  Future<String?> getFileUrl(String s3Key) async {
    try {
      final result = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(s3Key),
        options: const StorageGetUrlOptions(
          pluginOptions: S3GetUrlPluginOptions(
            expiresIn: Duration(hours: 1),
          ),
        ),
      ).result;

      safePrint('[StorageService] URL 생성 완료: $s3Key');
      return result.url.toString();
    } on StorageException catch (e) {
      safePrint('[StorageService] ERROR: URL 생성 실패 - ${e.message}');
      return null;
    } catch (e) {
      safePrint('[StorageService] ERROR: URL 생성 실패 - $e');
      return null;
    }
  }

  /// 파일 삭제
  /// [s3Key] 삭제할 파일의 S3 키
  Future<bool> deleteFile(String s3Key) async {
    try {
      await Amplify.Storage.remove(
        path: StoragePath.fromString(s3Key),
      ).result;

      safePrint('[StorageService] 파일 삭제 완료: $s3Key');
      return true;
    } on StorageException catch (e) {
      safePrint('[StorageService] ERROR: 삭제 실패 - ${e.message}');
      return false;
    } catch (e) {
      safePrint('[StorageService] ERROR: 삭제 실패 - $e');
      return false;
    }
  }

  /// 답안지 이미지 업로드 (Chapter용)
  /// [chapterId] 단원 ID
  /// [imageFile] 이미지 파일
  /// 반환: S3 URL (저장용)
  Future<String?> uploadAnswerImage({
    required String chapterId,
    required File imageFile,
  }) async {
    final extension = path.extension(imageFile.path).toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final s3Path = 'public/answers/$chapterId/answer_$timestamp$extension';

    final uploadedKey = await uploadFile(s3Path: s3Path, file: imageFile);
    if (uploadedKey != null) {
      safePrint('[StorageService] 답안지 업로드 완료: chapterId=$chapterId');
      return uploadedKey;
    }
    return null;
  }

  /// 답안지 이미지 URL 가져오기
  /// [answerImageUrl] Chapter 모델에 저장된 S3 키
  Future<String?> getAnswerImageUrl(String? answerImageUrl) async {
    if (answerImageUrl == null || answerImageUrl.isEmpty) {
      return null;
    }
    return getFileUrl(answerImageUrl);
  }

  /// 파일 선택 (이미지)
  /// 반환: 선택한 파일, 취소 시 null
  Future<File?> pickImageFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          safePrint('[StorageService] 파일 선택 완료: $filePath');
          return File(filePath);
        }
      }
      safePrint('[StorageService] 파일 선택 취소됨');
      return null;
    } catch (e) {
      safePrint('[StorageService] ERROR: 파일 선택 실패 - $e');
      return null;
    }
  }

  /// 파일 선택 (모든 타입)
  Future<File?> pickAnyFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          safePrint('[StorageService] 파일 선택 완료: $filePath');
          return File(filePath);
        }
      }
      safePrint('[StorageService] 파일 선택 취소됨');
      return null;
    } catch (e) {
      safePrint('[StorageService] ERROR: 파일 선택 실패 - $e');
      return null;
    }
  }

  /// 폴더 내 파일 목록 조회
  /// [folderPath] S3 폴더 경로 (예: 'public/answers/')
  Future<List<String>> listFiles(String folderPath) async {
    try {
      final result = await Amplify.Storage.list(
        path: StoragePath.fromString(folderPath),
      ).result;

      final keys = result.items.map((item) => item.path).toList();
      safePrint('[StorageService] 파일 목록 조회: ${keys.length}개');
      return keys;
    } on StorageException catch (e) {
      safePrint('[StorageService] ERROR: 목록 조회 실패 - ${e.message}');
      return [];
    } catch (e) {
      safePrint('[StorageService] ERROR: 목록 조회 실패 - $e');
      return [];
    }
  }
}
