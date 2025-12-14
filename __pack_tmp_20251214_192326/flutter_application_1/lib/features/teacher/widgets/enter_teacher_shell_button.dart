import 'dart:convert';
import 'dart:typed_data';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import '../teacher_shell.dart';

/// 교사용 쉘로 진입하는 임시 버튼(역할 가드)
/// - 현재 사용자 ID 토큰의 `cognito:groups`에 'teachers' 포함 여부로 판단
class EnterTeacherShellButton extends StatefulWidget {
  const EnterTeacherShellButton({super.key});

  @override
  State<EnterTeacherShellButton> createState() => _EnterTeacherShellButtonState();
}

class _EnterTeacherShellButtonState extends State<EnterTeacherShellButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _busy ? null : _enter,
      icon: const Icon(Icons.school),
      label: Text(_busy ? 'Checking…' : 'Enter Teacher Shell'),
    );
  }

  Future<void> _enter() async {
    setState(() => _busy = true);
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        _snack('Not signed in');
        return;
      }

      // ID 토큰(JWT) 문자열을 안전하게 얻기
      final tokens = (await Amplify.Auth.fetchAuthSession(
        options: const FetchAuthSessionOptions(forceRefresh: false),
      )).toJson(); // toJson()은 공개 API로 세션 정보를 직렬화

      // tokens 안에서 idToken 찾기(라이브러리 버전 차이를 고려해 방어적으로 파싱)
      final idToken = _extractIdToken(tokens);
      if (idToken == null) {
        _snack('No ID token');
        return;
      }

      final groups = _extractGroups(idToken);
      safePrint('[Auth] groups=$groups');

      if (groups.contains('teachers')) {
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeacherShell()));
      } else {
        _snack('You are not in teachers group.');
      }
    } on Exception catch (e, st) {
      safePrint('[Auth] enter teacher shell error: $e\n$st');
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 세션 직렬화 결과(JSON)에서 idToken 문자열만 안전 추출
  String? _extractIdToken(Map<String, Object?> json) {
    // 라이브러리 버전에 따라 키 구조가 조금씩 달라질 수 있어 방어적으로 처리
    // 흔한 구조 예:
    // {
    //   "isSignedIn": true,
    //   "userPoolTokens": {"idToken":"<JWT>", ...},
    //   ...
    // }
    try {
      final up = json['userPoolTokens'];
      if (up is Map) {
        final raw = up['idToken'];
        if (raw is String && raw.isNotEmpty) return raw;
      }
    } catch (_) {}
    return null;
  }

  /// JWT의 payload에서 cognito:groups 추출
  List<String> _extractGroups(String idToken) {
    final parts = idToken.split('.');
    if (parts.length < 2) return const [];
    final payload = parts[1];
    final normalized = _padBase64(payload);
    final Uint8List bytes = base64Url.decode(normalized);
    final map = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final raw = map['cognito:groups'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  String _padBase64(String input) {
    final mod = input.length % 4;
    if (mod == 0) return input;
    return input + '=' * (4 - mod);
    }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
