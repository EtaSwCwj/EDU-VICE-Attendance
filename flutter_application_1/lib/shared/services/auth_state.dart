import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';
import '../models/academy.dart';
import 'user_sync_service.dart';

/// Amplify Auth 기반 AuthState
class AuthState extends ChangeNotifier {
  Account? _user;
  Account? get user => _user;
  bool get isSignedIn => _user != null;

  Membership? _current;
  Membership? get currentMembership => _current;

  List<Academy> _academies = const [];
  List<Academy> get academies => _academies;

  // 마지막 에러 메시지
  String? _lastError;
  String? get lastError => _lastError;

  /// 로그인 (Amplify Auth 사용)
  Future<bool> signIn(String username, String password, {bool saveCredentials = false, bool autoLogin = false}) async {
    _lastError = null; // 에러 초기화

    try {
      safePrint('[AuthState] Attempting sign in for user: $username');

      // 기존 세션 확인 및 로그아웃
      try {
        final currentUser = await Amplify.Auth.getCurrentUser();
        safePrint('[AuthState] Current user already signed in: ${currentUser.username}');
        safePrint('[AuthState] Signing out before new login...');

        await Amplify.Auth.signOut();
        safePrint('[AuthState] Previous session signed out successfully');
      } on AuthException catch (e) {
        // 로그인된 사용자가 없으면 AuthException 발생 (정상)
        safePrint('[AuthState] No current user session (expected): ${e.message}');
      }

      // Amplify 로그인
      final result = await Amplify.Auth.signIn(username: username, password: password);

      safePrint('[AuthState] Sign-in result: isSignedIn=${result.isSignedIn}, nextStep=${result.nextStep.signInStep}');

      if (!result.isSignedIn) {
        _lastError = 'Sign-in challenge or additional step required: ${result.nextStep.signInStep}';
        safePrint('[AuthState] $_lastError');
        return false;
      }

      // DynamoDB 동기화
      safePrint('[AuthState] Sign-in successful, syncing user to DynamoDB...');
      try {
        final syncService = UserSyncService();
        final syncResult = await syncService.syncCurrentUser();

        if (syncResult.success) {
          if (syncResult.isNew) {
            safePrint('[AuthState] ✅ User synced to DynamoDB (newly created)');
          } else {
            safePrint('[AuthState] ✅ User already exists in DynamoDB');
          }
        } else {
          safePrint('[AuthState] ⚠️ WARNING: User sync failed: ${syncResult.message}');
        }
      } catch (e, stackTrace) {
        safePrint('[AuthState] ❌ EXCEPTION during user sync: $e');
        safePrint('[AuthState] Stack trace: $stackTrace');
      }

      // 사용자 정보 및 역할 가져오기
      await _loadUserInfo();

      // 로그인 정보 저장 (옵션)
      if (saveCredentials || autoLogin) {
        await _saveCredentials(username, password, saveCredentials, autoLogin);
      }

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _lastError = e.message;
      safePrint('[AuthState] AuthException: ${e.message}');
      safePrint('[AuthState] Error details: ${e.underlyingException}');
      return false;
    } catch (e, stackTrace) {
      _lastError = 'Unexpected error: $e';
      safePrint('[AuthState] signIn error: $e');
      safePrint('[AuthState] Stack trace: $stackTrace');
      return false;
    }
  }

  /// 저장된 credential로 자동 로그인 시도
  Future<bool> tryAutoLogin() async {
    try {
      safePrint('[AuthState] Checking for existing session...');

      // 먼저 기존 세션이 유효한지 확인
      try {
        final session = await Amplify.Auth.fetchAuthSession();
        if (session.isSignedIn) {
          safePrint('[AuthState] Valid session found, loading user info...');

          // 기존 세션이 유효하면 사용자 정보만 로드
          await _loadUserInfo();
          notifyListeners();

          safePrint('[AuthState] Auto login successful with existing session');
          return true;
        }
      } on AuthException catch (e) {
        safePrint('[AuthState] No valid session: ${e.message}');
      }

      // 기존 세션이 없으면 저장된 credential로 로그인 시도
      final prefs = await SharedPreferences.getInstance();
      final autoLogin = prefs.getBool('auto_login') ?? false;

      if (!autoLogin) {
        safePrint('[AuthState] Auto login is disabled');
        return false;
      }

      final username = prefs.getString('saved_username');
      final password = prefs.getString('saved_password');

      if (username == null || password == null) {
        safePrint('[AuthState] No saved credentials found');
        return false;
      }

      safePrint('[AuthState] Attempting auto login with saved credentials for user: $username');

      // 자동 로그인 시도 (저장 옵션은 유지)
      return await signIn(username, password, saveCredentials: true, autoLogin: true);
    } catch (e) {
      safePrint('[AuthState] tryAutoLogin error: $e');
      return false;
    }
  }

  /// 저장된 credential 불러오기 (로그인 화면에 자동 입력용)
  Future<Map<String, String?>> loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'username': prefs.getString('saved_username'),
        'password': prefs.getString('saved_password'),
        'autoLogin': prefs.getBool('auto_login')?.toString() ?? 'false',
      };
    } catch (e) {
      safePrint('[AuthState] loadSavedCredentials error: $e');
      return {};
    }
  }

  /// 사용자 정보 및 역할 로드
  Future<void> _loadUserInfo() async {
    try {
      final cognitoUser = await Amplify.Auth.getCurrentUser();
      final groups = await _getGroups();

      // 역할 결정 (owners -> owner, teachers -> teacher, students -> student)
      String role = 'student'; // 기본값
      if (groups.contains('owners')) {
        role = 'owner';
      } else if (groups.contains('teachers')) {
        role = 'teacher';
      } else if (groups.contains('students')) {
        role = 'student';
      }

      // Account 및 Membership 생성
      _user = Account(
        id: cognitoUser.userId,
        name: cognitoUser.username,
        username: cognitoUser.username,
        password: '', // Cognito에서 관리하므로 빈 문자열
        memberships: [
          Membership(
            academyId: 'default',
            role: role,
          ),
        ],
      );

      _current = _user!.memberships.first;

      safePrint('[AuthState] User loaded: ${_user!.name}, role: $role, groups: $groups');
    } catch (e) {
      safePrint('[AuthState] _loadUserInfo error: $e');
    }
  }

  /// ID 토큰에서 그룹(claims: "cognito:groups") 읽기
  Future<List<String>> _getGroups() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
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
      safePrint('[AuthState] getGroups error: $e');
      return const [];
    }
  }

  /// base64 padding 보정
  static String _padBase64(String input) {
    final pad = input.length % 4;
    if (pad == 2) return '$input==';
    if (pad == 3) return '$input=';
    if (pad == 1) return '$input===';
    return input;
  }

  /// 로그인 정보 저장
  Future<void> _saveCredentials(String username, String password, bool saveCredentials, bool autoLogin) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (saveCredentials) {
        await prefs.setString('saved_username', username);
        await prefs.setString('saved_password', password);
      } else {
        await prefs.remove('saved_username');
        await prefs.remove('saved_password');
      }

      await prefs.setBool('auto_login', autoLogin);

      safePrint('[AuthState] Credentials saved: saveCredentials=$saveCredentials, autoLogin=$autoLogin');
    } catch (e) {
      safePrint('[AuthState] _saveCredentials error: $e');
    }
  }

  void selectMembership(Membership m) {
    _current = m;
    notifyListeners();
  }

  Future<void> reloadFromStorage() async {
    // Mock 데이터 제거 - 필요 시 실제 데이터 로드 로직 추가
    if (_user != null) {
      await _loadUserInfo();
    }
    notifyListeners();
  }

  /// 로그아웃 (autoLogin만 false로 변경, 아이디/비밀번호는 유지)
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();

      // autoLogin만 false로 설정 (아이디/비밀번호는 유지)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_login', false);

      _user = null;
      _current = null;
      _academies = const [];
      notifyListeners();

      safePrint('[AuthState] Signed out successfully');
    } catch (e) {
      safePrint('[AuthState] signOut error: $e');
    }
  }

  String academyName(String id) {
    final found = _academies.where((e) => e.id == id);
    return found.isNotEmpty ? found.first.name : id;
  }

  /// 현재 membership의 academy 객체를 반환(없으면 null)
  Academy? get currentAcademy {
    final id = _current?.academyId;
    if (id == null) return null;
    final list = _academies.where((a) => a.id == id);
    return list.isNotEmpty ? list.first : null;
  }
}
