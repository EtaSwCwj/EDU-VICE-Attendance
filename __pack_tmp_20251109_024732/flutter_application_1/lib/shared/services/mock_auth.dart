// 설명: assets/mock/accounts.json을 읽어 더미 로그인 수행
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/account.dart';

class MockAuth {
  // 1) JSON 로드 → Account 리스트
  static Future<List<Account>> _loadAll() async {
    final text = await rootBundle.loadString('assets/mock/accounts.json');
    final Map<String, dynamic> data = jsonDecode(text) as Map<String, dynamic>;
    final List list = data['accounts'] as List? ?? [];
    return list.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
  }

  // 2) 로그인: username/password 매칭
  static Future<Account?> login(String username, String password) async {
    final all = await _loadAll();
    try {
      final user = all.firstWhere(
        (a) => a.username == username && a.password == password,
      );
      // ignore: avoid_print
      print('[MockAuth] login ok: ${user.id} (${user.globalRole ?? user.memberships.map((m)=>m.role).toList()})');
      return user;
    } catch (_) {
      // ignore: avoid_print
      print('[MockAuth] invalid credentials for $username');
      return null;
    }
  }
}
