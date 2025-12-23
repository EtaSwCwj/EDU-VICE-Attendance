import 'dart:convert';
import 'package:encrypt/encrypt.dart';

/// QR 코드용 토큰 생성 및 복호화 유틸리티
class QRTokenUtil {
  // 암호화 키 (실제 서비스에서는 안전한 곳에 보관해야 함)
  static final _key = Key.fromUtf8('YourSecretKey321YourSecretKey321'); // 32 bytes
  static final _iv = IV.fromUtf8('1234567890123456'); // 16 bytes
  static final _encrypter = Encrypter(AES(_key));

  /// 사용자 ID와 타임스탬프를 이용해 암호화된 토큰 생성
  static String generateToken(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = {
      'userId': userId,
      'timestamp': timestamp,
    };

    final plainText = jsonEncode(data);
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);

    return encrypted.base64;
  }

  /// 암호화된 토큰을 복호화하여 사용자 정보 반환
  static Map<String, dynamic>? decryptToken(String token) {
    try {
      final encrypted = Encrypted.fromBase64(token);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);

      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      print('[QRTokenUtil] Error decrypting token: $e');
      return null;
    }
  }

  /// 토큰의 유효성 검증 (24시간 이내)
  static bool isTokenValid(String token) {
    final data = decryptToken(token);
    if (data == null) return false;

    final timestamp = data['timestamp'] as int?;
    if (timestamp == null) return false;

    final tokenTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(tokenTime);

    // 24시간 이내인지 확인
    return difference.inHours <= 24;
  }

  /// QR 코드용 초대 데이터 생성
  static String generateInviteQRData({
    required String inviteCode,
    required String academyId,
    required String role,
  }) {
    final data = {
      'type': 'invite',
      'code': inviteCode,
      'academyId': academyId,
      'role': role,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final plainText = jsonEncode(data);
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);

    return encrypted.base64;
  }

  /// QR 코드 데이터 복호화
  static Map<String, dynamic>? decryptQRData(String encryptedData) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedData);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);

      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      print('[QRTokenUtil] Error decrypting QR data: $e');
      return null;
    }
  }
}