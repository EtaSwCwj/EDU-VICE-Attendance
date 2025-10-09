import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../models/academy.dart';
import 'mock_auth.dart';
import 'mock_db.dart';

class AuthState extends ChangeNotifier {
  Account? _user;
  Account? get user => _user;
  bool get isSignedIn => _user != null;

  // 현재 선택된 소속(학원/역할)
  Membership? _current;
  Membership? get currentMembership => _current;

  // 학원 목록(간단 캐시)
  List<Academy> _academies = const [];
  List<Academy> get academies => _academies;

  Future<bool> signIn(String id, String pw) async {
    final u = await MockAuth.login(id, pw);
    if (u != null) {
      _user = u;
      _current = u.memberships.isNotEmpty ? u.memberships.first : null;
      _academies = await MockDb.loadAcademies();
      notifyListeners();
      return true;
    }
    return false;
  }

  void selectMembership(Membership m) {
    _current = m;
    notifyListeners();
  }

  void signOut() {
    _user = null;
    _current = null;
    _academies = const [];
    notifyListeners();
  }

  String academyName(String id) {
    final a = _academies.where((e) => e.id == id).cast<Academy?>().firstWhere(
          (e) => e != null,
          orElse: () => null,
        );
    return a?.name ?? id;
  }

  Future<void> reloadFromStorage() async {
    _academies = await MockDb.loadAcademies();

    if (_user != null) {
      // 최신 accounts에서 동일 ID 사용자 찾아서 memberships 등 갱신
      final all = await MockDb.loadAccounts();
      final updated =
          all.where((a) => a.id == _user!.id).cast<Account?>().firstWhere(
                (a) => a != null,
                orElse: () => null,
              );
      if (updated != null) {
        _user = updated;
        // 현재 선택이 사라졌다면 첫 membership으로 보정
        if (_user!.memberships.isNotEmpty &&
            (_current == null ||
                !_user!.memberships.any((m) =>
                    m.academyId == _current!.academyId &&
                    m.role == _current!.role))) {
          _current = _user!.memberships.first;
        }
      }
    }
    notifyListeners();
  }
}
