import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';
import '../models/academy.dart' as local_models;
import 'user_sync_service.dart';
import '../../models/ModelProvider.dart';

/// Amplify Auth 기반 AuthState
class AuthState extends ChangeNotifier {
  Account? _user;
  Account? get user => _user;
  bool get isSignedIn => _user != null;

  Membership? _current;
  Membership? get currentMembership => _current;

  List<local_models.Academy> _academies = const [];
  List<local_models.Academy> get academies => _academies;

  String? _lastError;
  String? get lastError => _lastError;

  /// 로그인
  Future<bool> signIn(String username, String password, {bool saveCredentials = false, bool autoLogin = false}) async {
    _lastError = null;

    try {
      // 기존 세션 확인 및 로그아웃
      try {
        await Amplify.Auth.getCurrentUser();
        await Amplify.Auth.signOut();
      } on AuthException catch (_) {}

      final result = await Amplify.Auth.signIn(username: username, password: password);

      if (!result.isSignedIn) {
        _lastError = '추가 인증 필요: ${result.nextStep.signInStep}';
        return false;
      }

      // DynamoDB 동기화
      try {
        final syncService = UserSyncService();
        await syncService.syncCurrentUser();
      } catch (_) {}

      await _loadUserInfo();

      if (saveCredentials || autoLogin) {
        await _saveCredentials(username, password, saveCredentials, autoLogin);
      }

      safePrint('[LOG] 로그인 성공: $username');
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _lastError = e.message;
      safePrint('[LOG] 로그인 실패: ${e.message}');
      return false;
    } catch (e) {
      _lastError = '예상치 못한 오류: $e';
      safePrint('[LOG] 로그인 에러: $e');
      return false;
    }
  }

  /// 자동 로그인
  Future<bool> tryAutoLogin() async {
    try {
      try {
        final session = await Amplify.Auth.fetchAuthSession();
        if (session.isSignedIn) {
          await _loadUserInfo();
          notifyListeners();
          return true;
        }
      } on AuthException catch (_) {}

      final prefs = await SharedPreferences.getInstance();
      final autoLogin = prefs.getBool('auto_login') ?? false;

      if (!autoLogin) return false;

      final username = prefs.getString('saved_username');
      final password = prefs.getString('saved_password');

      if (username == null || password == null) return false;

      return await signIn(username, password, saveCredentials: true, autoLogin: true);
    } catch (_) {
      return false;
    }
  }

  /// 저장된 credential 불러오기
  Future<Map<String, String?>> loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'username': prefs.getString('saved_username'),
        'password': prefs.getString('saved_password'),
        'autoLogin': prefs.getBool('auto_login')?.toString() ?? 'false',
      };
    } catch (_) {
      return {};
    }
  }

  /// 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    try {
      final cognitoUser = await Amplify.Auth.getCurrentUser();
      final cognitoUsername = cognitoUser.username;
      final cognitoUserId = cognitoUser.userId;

      final appUser = await _getAppUserByUsername(cognitoUsername);
      String userName = cognitoUsername;
      String? appUserId;

      if (appUser != null) {
        userName = appUser['name'] ?? cognitoUsername;
        appUserId = appUser['id'];
      }

      String? role;
      String academyId = 'default-academy';
      bool hasMembership = false;

      if (appUserId != null) {
        final membership = await _getAcademyMemberByUserId(appUserId);
        if (membership != null) {
          role = membership['role'] ?? 'student';
          academyId = membership['academyId'] ?? 'default-academy';
          hasMembership = true;
        } else {
          final groups = await _getGroups();
          if (groups.contains('owners')) {
            role = 'owner';
            hasMembership = true;
          } else if (groups.contains('teachers')) {
            role = 'teacher';
            hasMembership = true;
          }
        }
      } else {
        final groups = await _getGroups();
        if (groups.contains('owners')) {
          role = 'owner';
          hasMembership = true;
        } else if (groups.contains('teachers')) {
          role = 'teacher';
          hasMembership = true;
        }
      }

      if (!hasMembership || role == null) {
        _user = Account(
          id: appUserId ?? cognitoUserId,
          name: userName,
          username: cognitoUsername,
          password: '',
          email: appUser?['email'],
          memberships: [],
        );
        _academies = const [];
        _current = null;
        return;
      }

      local_models.Academy? academyInfo;

      if (academyId != 'default-academy') {
        final academy = await _getAcademyById(academyId);
        if (academy != null) {
          academyInfo = local_models.Academy(
            id: academy['id'] ?? academyId,
            name: academy['name'] ?? 'Unknown',
            code: academy['code'],
            address: academy['address'],
            phone: academy['phone'],
            description: academy['description'],
          );
        }
      }

      academyInfo ??= const local_models.Academy(
        id: 'default-academy',
        name: 'EDU-VICE',
        code: 'EDUVICE',
      );

      final membershipList = <Membership>[
        Membership(academyId: academyInfo.id, role: role),
      ];

      _user = Account(
        id: appUserId ?? cognitoUserId,
        name: userName,
        username: cognitoUsername,
        password: '',
        email: appUser?['email'],
        memberships: membershipList,
      );

      _academies = [academyInfo];
      _current = membershipList.first;
    } catch (e) {
      safePrint('[LOG] 사용자 정보 로드 실패: $e');
      try {
        final cognitoUser = await Amplify.Auth.getCurrentUser();
        _user = Account(
          id: cognitoUser.userId,
          name: cognitoUser.username,
          username: cognitoUser.username,
          password: '',
          memberships: [],
        );
      } catch (_) {
        _user = null;
      }
      _current = null;
      _academies = const [];
    }
  }

  Future<Map<String, dynamic>?> _getAppUserByUsername(String username) async {
    try {
      final request = ModelQueries.list(
        AppUser.classType,
        where: AppUser.COGNITOUSERNAME.eq(username),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors || response.data == null) return null;

      final users = response.data!.items.whereType<AppUser>().toList();
      if (users.isNotEmpty) {
        final u = users.first;
        return {
          'id': u.id,
          'name': u.name,
          'email': u.email,
          'cognitoUsername': u.cognitoUsername,
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getAcademyMemberByUserId(String userId) async {
    try {
      final request = ModelQueries.list(
        AcademyMember.classType,
        where: AcademyMember.USERID.eq(userId),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors || response.data == null) return null;

      final members = response.data!.items.whereType<AcademyMember>().toList();
      if (members.isNotEmpty) {
        final m = members.first;
        return {
          'id': m.id,
          'academyId': m.academyId,
          'userId': m.userId,
          'role': m.role,
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getAcademyById(String id) async {
    try {
      final request = ModelQueries.get(
        Academy.classType,
        AcademyModelIdentifier(id: id),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors || response.data == null) return null;

      final academy = response.data;
      if (academy != null) {
        return {
          'id': academy.id,
          'name': academy.name,
          'code': academy.code,
          'address': academy.address,
          'phone': academy.phone,
          'description': academy.description,
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

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
    } catch (_) {
      return const [];
    }
  }

  static String _padBase64(String input) {
    final pad = input.length % 4;
    if (pad == 2) return '$input==';
    if (pad == 3) return '$input=';
    if (pad == 1) return '$input===';
    return input;
  }

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
    } catch (_) {}
  }

  void selectMembership(Membership m) {
    _current = m;
    notifyListeners();
  }

  Future<void> reloadFromStorage() async {
    if (_user != null) {
      await _loadUserInfo();
    }
    notifyListeners();
  }

  /// 인증 상태 새로고침
  Future<void> refreshAuth() async {
    // Cognito 세션 강제 새로고침
    try {
      await Amplify.Auth.fetchAuthSession(
        options: const FetchAuthSessionOptions(forceRefresh: true),
      );
    } catch (_) {}

    await _loadUserInfo();
    
    // 핵심 로그: 데이터 변경 결과
    final role = _current?.role ?? 'none';
    final academy = currentAcademy?.name ?? 'none';
    safePrint('[LOG] refreshAuth 완료: role=$role, academy=$academy');
    
    notifyListeners();
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_login', false);

      _user = null;
      _current = null;
      _academies = const [];
      notifyListeners();

      safePrint('[LOG] 로그아웃');
    } catch (_) {}
  }

  String academyName(String id) {
    final found = _academies.where((e) => e.id == id);
    return found.isNotEmpty ? found.first.name : id;
  }

  local_models.Academy? get currentAcademy {
    final id = _current?.academyId;
    if (id == null) return null;
    final list = _academies.where((a) => a.id == id);
    return list.isNotEmpty ? list.first : null;
  }
}
