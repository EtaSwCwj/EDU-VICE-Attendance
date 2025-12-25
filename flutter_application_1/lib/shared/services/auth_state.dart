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

  // 마지막 에러 메시지
  String? _lastError;
  String? get lastError => _lastError;

  /// 로그인 (Amplify Auth 사용)
  Future<bool> signIn(String username, String password, {bool saveCredentials = false, bool autoLogin = false}) async {
    _lastError = null;

    try {
      safePrint('[AuthState] 로그인 시도: $username');

      // 기존 세션 확인 및 로그아웃
      try {
        await Amplify.Auth.getCurrentUser();
        await Amplify.Auth.signOut();
      } on AuthException catch (_) {
        // 세션 없음 (정상)
      }

      // Amplify 로그인
      final result = await Amplify.Auth.signIn(username: username, password: password);

      if (!result.isSignedIn) {
        _lastError = '추가 인증 필요: ${result.nextStep.signInStep}';
        safePrint('[AuthState] ERROR: $_lastError');
        return false;
      }

      // DynamoDB 동기화
      try {
        final syncService = UserSyncService();
        await syncService.syncCurrentUser();
      } catch (e) {
        safePrint('[AuthState] WARNING: 사용자 동기화 실패 - $e');
      }

      // 사용자 정보 로드
      await _loadUserInfo();

      // 로그인 정보 저장
      if (saveCredentials || autoLogin) {
        await _saveCredentials(username, password, saveCredentials, autoLogin);
      }

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _lastError = e.message;
      safePrint('[AuthState] ERROR: ${e.message}');
      return false;
    } catch (e) {
      _lastError = '예상치 못한 오류: $e';
      safePrint('[AuthState] ERROR: $e');
      return false;
    }
  }

  /// 저장된 credential로 자동 로그인 시도
  Future<bool> tryAutoLogin() async {
    try {
      safePrint('[AuthState] 세션 확인 중...');

      // 기존 세션 확인
      try {
        final session = await Amplify.Auth.fetchAuthSession();
        if (session.isSignedIn) {
          await _loadUserInfo();
          notifyListeners();
          safePrint('[AuthState] 자동 로그인 성공 (기존 세션)');
          return true;
        }
      } on AuthException catch (_) {
        // 세션 없음
      }

      // 저장된 credential 확인
      final prefs = await SharedPreferences.getInstance();
      final autoLogin = prefs.getBool('auto_login') ?? false;

      if (!autoLogin) {
        safePrint('[AuthState] 자동 로그인 비활성화');
        return false;
      }

      final username = prefs.getString('saved_username');
      final password = prefs.getString('saved_password');

      if (username == null || password == null) {
        return false;
      }

      safePrint('[AuthState] 저장된 계정으로 로그인: $username');
      return await signIn(username, password, saveCredentials: true, autoLogin: true);
    } catch (e) {
      safePrint('[AuthState] ERROR: 자동 로그인 실패 - $e');
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
      safePrint('[AuthState] ERROR: 저장된 계정 로드 실패 - $e');
      return {};
    }
  }

  /// 사용자 정보 및 역할 로드
  /// AppUser, AcademyMember, Academy 테이블에서 조회
  /// Cognito 그룹은 fallback으로 사용
  Future<void> _loadUserInfo() async {
    try {
      safePrint('[AuthState] Step 1: Cognito 사용자 조회');
      final cognitoUser = await Amplify.Auth.getCurrentUser();
      final cognitoUsername = cognitoUser.username;
      final cognitoUserId = cognitoUser.userId;

      safePrint('[DEBUG] ========== 역할 판단 시작 ==========');
      safePrint('[DEBUG] Cognito userId: $cognitoUserId');
      safePrint('[DEBUG] Cognito username: $cognitoUsername');

      safePrint('[AuthState] Step 2: AppUser 조회');
      final appUser = await _getAppUserByUsername(cognitoUsername);
      String userName = cognitoUsername;
      String? appUserId;

      if (appUser != null) {
        userName = appUser['name'] ?? cognitoUsername;
        appUserId = appUser['id'];
        safePrint('[AuthState]   AppUser: $userName');
        safePrint('[DEBUG] AppUser 조회 결과: 있음 (id=$appUserId, name=$userName)');
      } else {
        safePrint('[DEBUG] AppUser 조회 결과: 없음');
      }

      safePrint('[AuthState] Step 3: AcademyMember 조회');
      String? role;
      String academyId = 'default-academy';
      bool hasMembership = false;

      if (appUserId != null) {
        final membership = await _getAcademyMemberByUserId(appUserId);
        if (membership != null) {
          role = membership['role'] ?? 'student';
          academyId = membership['academyId'] ?? 'default-academy';
          hasMembership = true;
          safePrint('[AuthState]   role=$role, academyId=$academyId');
          safePrint('[DEBUG] AcademyMember 조회 결과: 있음 (role=$role)');
        } else {
          safePrint('[DEBUG] AcademyMember 조회 결과: 없음');
          final groups = await _getGroups();
          safePrint('[DEBUG] Cognito 그룹: $groups');
          if (groups.contains('owners')) {
            role = 'owner';
            hasMembership = true;
          } else if (groups.contains('teachers')) {
            role = 'teacher';
            hasMembership = true;
          }
        }
      } else {
        safePrint('[DEBUG] appUserId가 null이므로 AcademyMember 조회 스킵');
        final groups = await _getGroups();
        safePrint('[DEBUG] Cognito 그룹: $groups');
        if (groups.contains('owners')) {
          role = 'owner';
          hasMembership = true;
        } else if (groups.contains('teachers')) {
          role = 'teacher';
          hasMembership = true;
        }
      }

      safePrint('[DEBUG] hasMembership: $hasMembership');
      safePrint('[DEBUG] 최종 role: $role');

      // 소속이 없으면 memberships를 빈 리스트로
      if (!hasMembership || role == null) {
        safePrint('[DEBUG] 소속 없음 → memberships: []');
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
        safePrint('[DEBUG] ========== 역할 판단 끝 (NoAcademyShell) ==========');
        return;
      }

      safePrint('[AuthState] Step 4: Academy 조회');
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
          safePrint('[AuthState]   Academy: ${academyInfo.name}');
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

      safePrint('[AuthState] Summary: user=$userName, role=$role, academy=${academyInfo.name}');
      safePrint('[DEBUG] ========== 역할 판단 끝 (role=$role, memberships.length=${membershipList.length}) ==========');
    } catch (e) {
      safePrint('[AuthState] ERROR: 사용자 정보 로드 실패 - $e');

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

  /// AppUser 테이블에서 cognitoUsername으로 조회
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
    } catch (e) {
      safePrint('[AuthState] ERROR: AppUser 조회 실패 - $e');
      return null;
    }
  }

  /// AcademyMember 테이블에서 userId로 조회
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
    } catch (e) {
      safePrint('[AuthState] ERROR: AcademyMember 조회 실패 - $e');
      return null;
    }
  }

  /// Academy 테이블에서 id로 조회
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
    } catch (e) {
      safePrint('[AuthState] ERROR: Academy 조회 실패 - $e');
      return null;
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
      safePrint('[AuthState] ERROR: Cognito 그룹 조회 실패 - $e');
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
    } catch (e) {
      safePrint('[AuthState] ERROR: 계정 저장 실패 - $e');
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

  /// 인증 상태 새로고침 (멤버 등록 후 확인용)
  Future<void> refreshAuth() async {
    safePrint('[AuthState] 인증 상태 새로고침');
    await _loadUserInfo();
    notifyListeners();
  }

  /// 로그아웃 (autoLogin만 false로 변경, 아이디/비밀번호는 유지)
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_login', false);

      _user = null;
      _current = null;
      _academies = const [];
      notifyListeners();

      safePrint('[AuthState] 로그아웃 완료');
    } catch (e) {
      safePrint('[AuthState] ERROR: 로그아웃 실패 - $e');
    }
  }

  String academyName(String id) {
    final found = _academies.where((e) => e.id == id);
    return found.isNotEmpty ? found.first.name : id;
  }

  /// 현재 membership의 academy 객체를 반환(없으면 null)
  local_models.Academy? get currentAcademy {
    final id = _current?.academyId;
    if (id == null) return null;
    final list = _academies.where((a) => a.id == id);
    return list.isNotEmpty ? list.first : null;
  }
}
