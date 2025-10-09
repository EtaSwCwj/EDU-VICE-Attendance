import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../models/academy.dart';
import 'mock_auth.dart';
import 'mock_db.dart';

class AuthState extends ChangeNotifier {
  Account? _user;
  Account? get user => _user;
  bool get isSignedIn => _user != null;

  Membership? _current;
  Membership? get currentMembership => _current;

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

  Future<void> reloadFromStorage() async {
    _academies = await MockDb.loadAcademies();

    if (_user != null) {
      final all = await MockDb.loadAccounts();
      final updated = all
          .where((a) => a.id == _user!.id)
          .cast<Account?>()
          .firstWhere((a) => a != null, orElse: () => null);
      if (updated != null) {
        _user = updated;
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

  void signOut() {
    _user = null;
    _current = null;
    _academies = const [];
    notifyListeners();
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
