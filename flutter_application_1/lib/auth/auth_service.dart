import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class AuthService {
  const AuthService();

  Future<bool> isSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } catch (e) {
      safePrint('[Auth] isSignedIn error: $e');
      return false;
    }
  }

  Future<void> signIn(String username, String password) async {
    final res = await Amplify.Auth.signIn(username: username, password: password);
    if (!res.isSignedIn) {
      throw StateError('Sign-in challenge or failure');
    }
  }

  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      safePrint('[Auth] signOut error: $e');
    }
  }

  /// ID 토큰에서 그룹(claims: "cognito:groups") 읽기
  Future<List<String>> getGroups() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      // ✅ JsonWebToken → 원문 문자열은 raw 에 있음
      final idTokenRaw = session.userPoolTokensResult.value.idToken.raw;

      final parts = idTokenRaw.split('.');
      if (parts.length != 3) return const [];
      final payloadJson = utf8.decode(base64Url.decode(_padBase64(parts[1])));
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

      final groups = payload['cognito:groups'];
      if (groups is List) {
        return groups.map((e) => e.toString()).toList();
      }
      return const [];
    } catch (e) {
      safePrint('[Auth] getGroups error: $e');
      return const [];
    }
  }

  Future<String?> getUsername() async {
    try {
      final attrs = await Amplify.Auth.fetchUserAttributes();
      final preferred = attrs.firstWhere(
        (a) => a.userAttributeKey == CognitoUserAttributeKey.preferredUsername,
        orElse: () => const AuthUserAttribute(
          userAttributeKey: AuthUserAttributeKey.email,
          value: '',
        ),
      );
      if (preferred.value.isNotEmpty) return preferred.value;

      // custom:username (있으면 사용)
      final custom = attrs.firstWhere(
        (a) => a.userAttributeKey == CognitoUserAttributeKey.custom('username'),
        orElse: () => const AuthUserAttribute(
          userAttributeKey: AuthUserAttributeKey.email,
          value: '',
        ),
      );
      if (custom.value.isNotEmpty) return custom.value;

      final user = await Amplify.Auth.getCurrentUser();
      return user.username;
    } catch (e) {
      safePrint('[Auth] getUsername error: $e');
      return null;
    }
  }

  /// base64 padding 보정
  static String _padBase64(String input) {
    final pad = input.length % 4;
    if (pad == 2) return '$input==';
    if (pad == 3) return '$input=';
    if (pad == 1) return '$input===';
    return input;
    // ▲ 불필요한 { } 제거
  }
}
